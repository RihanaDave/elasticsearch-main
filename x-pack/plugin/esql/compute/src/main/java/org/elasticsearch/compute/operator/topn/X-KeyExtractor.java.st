/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0; you may not use this file except in compliance with the Elastic License
 * 2.0.
 */

package org.elasticsearch.compute.operator.topn;

$if(BytesRef)$
import org.apache.lucene.util.BytesRef;
$endif$
import org.elasticsearch.compute.data.$Type$Block;
import org.elasticsearch.compute.data.$Type$Vector;
import org.elasticsearch.compute.operator.BreakingBytesRefBuilder;

import java.util.Locale;

/**
 * Extracts sort keys for top-n from their {@link $Type$Block}s.
 * This class is generated. Edit {@code X-KeyExtractor.java.st} instead.
 */
abstract class KeyExtractorFor$Type$ implements KeyExtractor {
    static KeyExtractorFor$Type$ extractorFor(TopNEncoder encoder, boolean ascending, byte nul, byte nonNul, $Type$Block block) {
        $Type$Vector v = block.asVector();
        if (v != null) {
            return new KeyExtractorFor$Type$.FromVector(encoder, nul, nonNul, v);
        }
        if (ascending) {
            return block.mvSortedAscending()
                ? new KeyExtractorFor$Type$.MinFromAscendingBlock(encoder, nul, nonNul, block)
                : new KeyExtractorFor$Type$.MinFromUnorderedBlock(encoder, nul, nonNul, block);
        }
        return block.mvSortedAscending()
            ? new KeyExtractorFor$Type$.MaxFromAscendingBlock(encoder, nul, nonNul, block)
            : new KeyExtractorFor$Type$.MaxFromUnorderedBlock(encoder, nul, nonNul, block);
    }

$if(BytesRef)$
    private final TopNEncoder encoder;
    protected final BytesRef scratch = new BytesRef();
$endif$
    private final byte nul;
    private final byte nonNul;

    KeyExtractorFor$Type$(TopNEncoder encoder, byte nul, byte nonNul) {
$if(BytesRef)$
        this.encoder = encoder;
$else$
        assert encoder == TopNEncoder.DEFAULT_SORTABLE;
$endif$
        this.nul = nul;
        this.nonNul = nonNul;
    }

    protected final int nonNul(BreakingBytesRefBuilder key, $type$ value) {
        key.append(nonNul);
$if(BytesRef)$
        return encoder.encodeBytesRef(value, key) + 1;
$elseif(boolean)$
        TopNEncoder.DEFAULT_SORTABLE.encodeBoolean(value, key);
        return Byte.BYTES + 1;
$else$
        TopNEncoder.DEFAULT_SORTABLE.encode$Type$(value, key);
        return $BYTES$ + 1;
$endif$
    }

    protected final int nul(BreakingBytesRefBuilder key) {
        key.append(nul);
        return 1;
    }

    @Override
    public final String toString() {
$if(BytesRef)$
        return String.format(Locale.ROOT, "KeyExtractorFor$Type$%s(%s, %s, %s)", getClass().getSimpleName(), encoder, nul, nonNul);
$else$
        return String.format(Locale.ROOT, "KeyExtractorFor$Type$%s(%s, %s)", getClass().getSimpleName(), nul, nonNul);
$endif$
    }

    static class FromVector extends KeyExtractorFor$Type$ {
        private final $Type$Vector vector;

        FromVector(TopNEncoder encoder, byte nul, byte nonNul, $Type$Vector vector) {
            super(encoder, nul, nonNul);
            this.vector = vector;
        }

        @Override
        public int writeKey(BreakingBytesRefBuilder key, int position) {
$if(BytesRef)$
            return nonNul(key, vector.get$Type$(position, scratch));
$else$
            return nonNul(key, vector.get$Type$(position));
$endif$
        }
    }

    static class MinFromAscendingBlock extends KeyExtractorFor$Type$ {
        private final $Type$Block block;

        MinFromAscendingBlock(TopNEncoder encoder, byte nul, byte nonNul, $Type$Block block) {
            super(encoder, nul, nonNul);
            this.block = block;
        }

        @Override
        public int writeKey(BreakingBytesRefBuilder key, int position) {
            if (block.isNull(position)) {
                return nul(key);
            }
$if(BytesRef)$
            return nonNul(key, block.get$Type$(block.getFirstValueIndex(position), scratch));
$else$
            return nonNul(key, block.get$Type$(block.getFirstValueIndex(position)));
$endif$
        }
    }

    static class MaxFromAscendingBlock extends KeyExtractorFor$Type$ {
        private final $Type$Block block;

        MaxFromAscendingBlock(TopNEncoder encoder, byte nul, byte nonNul, $Type$Block block) {
            super(encoder, nul, nonNul);
            this.block = block;
        }

        @Override
        public int writeKey(BreakingBytesRefBuilder key, int position) {
            if (block.isNull(position)) {
                return nul(key);
            }
$if(BytesRef)$
            return nonNul(key, block.get$Type$(block.getFirstValueIndex(position) + block.getValueCount(position) - 1, scratch));
$else$
            return nonNul(key, block.get$Type$(block.getFirstValueIndex(position) + block.getValueCount(position) - 1));
$endif$
        }
    }

    static class MinFromUnorderedBlock extends KeyExtractorFor$Type$ {
        private final $Type$Block block;

$if(BytesRef)$
        private final BytesRef minScratch = new BytesRef();
$endif$

        MinFromUnorderedBlock(TopNEncoder encoder, byte nul, byte nonNul, $Type$Block block) {
            super(encoder, nul, nonNul);
            this.block = block;
        }

        @Override
        public int writeKey(BreakingBytesRefBuilder key, int position) {
            int size = block.getValueCount(position);
            if (size == 0) {
                return nul(key);
            }
            int start = block.getFirstValueIndex(position);
            int end = start + size;
$if(BytesRef)$
            BytesRef min = block.getBytesRef(start, minScratch);
            for (int i = start; i < end; i++) {
                BytesRef v = block.getBytesRef(i, scratch);
                if (v.compareTo(min) < 0) {
                    min.bytes = v.bytes;
                    min.offset = v.offset;
                    min.length = v.length;
                }
            }
            return nonNul(key, min);
$elseif(boolean)$
            for (int i = start; i < end; i++) {
                if (block.getBoolean(i) == false) {
                    return nonNul(key, false);
                }
            }
            return nonNul(key, true);
$else$
            $type$ min = block.get$Type$(start);
            for (int i = start + 1; i < end; i++) {
                min = Math.min(min, block.get$Type$(i));
            }
            return nonNul(key, min);
$endif$
        }
    }

    static class MaxFromUnorderedBlock extends KeyExtractorFor$Type$ {
        private final $Type$Block block;

$if(BytesRef)$
        private final BytesRef maxScratch = new BytesRef();
$endif$

        MaxFromUnorderedBlock(TopNEncoder encoder, byte nul, byte nonNul, $Type$Block block) {
            super(encoder, nul, nonNul);
            this.block = block;
        }

        @Override
        public int writeKey(BreakingBytesRefBuilder key, int position) {
            int size = block.getValueCount(position);
            if (size == 0) {
                return nul(key);
            }
            int start = block.getFirstValueIndex(position);
            int end = start + size;
$if(BytesRef)$
            BytesRef max = block.getBytesRef(start, maxScratch);
            for (int i = start; i < end; i++) {
                BytesRef v = block.getBytesRef(i, scratch);
                if (v.compareTo(max) > 0) {
                    max.bytes = v.bytes;
                    max.offset = v.offset;
                    max.length = v.length;
                }
            }
            return nonNul(key, max);
$elseif(boolean)$
            for (int i = start; i < end; i++) {
                if (block.getBoolean(i)) {
                    return nonNul(key, true);
                }
            }
            return nonNul(key, false);
$else$
            $type$ max = block.get$Type$(start);
            for (int i = start + 1; i < end; i++) {
                max = Math.max(max, block.get$Type$(i));
            }
            return nonNul(key, max);
$endif$
        }
    }
}
