/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

package org.elasticsearch.gradle.testclusters

import spock.lang.Specification

import java.nio.file.Paths
import java.security.cert.Certificate
import java.security.cert.CertificateException
import java.security.cert.CertificateFactory
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

class SslTrustResolverSpec extends Specification {

    def "build trust manager from trust store file"() {
        given:
        SslTrustResolver resolver = new SslTrustResolver()
        URL ca = getClass().getResource("/ca.p12")

        when:
        resolver.setTrustStoreFile(Paths.get(ca.toURI()).toFile())
        resolver.setTrustStorePassword("password")
        final TrustManager[] trustManagers = resolver.buildTrustManagers()

        then:
        trustManagers.length == 1
        trustManagers[0] instanceof X509TrustManager
        def issuers = ((X509TrustManager) trustManagers[0]).getAcceptedIssuers()
        issuers.length == 1
        issuers[0].subjectX500Principal.toString() == 'CN=Elastic Certificate Tool Autogenerated CA'
    }

    def "build trust manager from certificate authorities file"() {
        given:
        SslTrustResolver resolver = new SslTrustResolver()
        URL ca = getClass().getResource("/ca.pem")

        when:
        resolver.setCertificateAuthorities(Paths.get(ca.toURI()).toFile())
        final TrustManager[] trustManagers = resolver.buildTrustManagers()

        then:
        trustManagers.length == 1
        trustManagers[0] instanceof X509TrustManager
        def issuers = ((X509TrustManager) trustManagers[0]).getAcceptedIssuers()
        issuers.length == 1
        issuers[0].subjectX500Principal.toString() == 'CN=Elastic Certificate Tool Autogenerated CA'
    }

    def "build trust manager from keystore file"() {
        given:
        SslTrustResolver resolver = new SslTrustResolver()
        URL ks = getClass().getResource("/server.p12")
        Certificate[] serverChain = readCertificates("/server.chain")
        Certificate[] issuingChain = readCertificates("/issuing.pem")
        Certificate[] altChain = readCertificates("/ca.pem")

        when:
        resolver.setServerKeystoreFile(Paths.get(ks.toURI()).toFile())
        resolver.setServerKeystorePassword("password")
        final TrustManager[] trustManagers = resolver.buildTrustManagers()

        then:
        trustManagers.length == 1
        trustManagers[0] instanceof X509TrustManager

        def trustManager = (X509TrustManager) trustManagers[0]
        isTrusted(trustManager, serverChain) == true;
        isTrusted(trustManager, issuingChain) == false;
        isTrusted(trustManager, altChain) == false;
    }

    def "build trust manager from server certificate file"() {
        given:
        SslTrustResolver resolver = new SslTrustResolver()
        URL chain = getClass().getResource("/server.chain")
        Certificate[] serverChain = readCertificates("/server.chain")
        Certificate[] issuingChain = readCertificates("/issuing.pem")
        Certificate[] altChain = readCertificates("/ca.pem")

        when:
        resolver.setServerCertificate(Paths.get(chain.toURI()).toFile())
        final TrustManager[] trustManagers = resolver.buildTrustManagers()

        then:
        trustManagers.length == 1
        trustManagers[0] instanceof X509TrustManager

        def trustManager = (X509TrustManager) trustManagers[0]
        isTrusted(trustManager, serverChain) == true;
        isTrusted(trustManager, issuingChain) == false;
        isTrusted(trustManager, altChain) == false;
    }

    private Certificate[] readCertificates(String resourceName) {
        CertificateFactory certificateFactory = CertificateFactory.getInstance("X.509")
        return getClass().getResource(resourceName).withInputStream { stream ->
            certificateFactory.generateCertificates(stream)
        }
    }

    private boolean isTrusted(X509TrustManager trustManager, Certificate[] certificateChain) {
        try {
            trustManager.checkServerTrusted(((java.security.cert.X509Certificate[]) certificateChain), "RSA");
            return true;
        } catch(CertificateException ignore) {
            return false;
        }
    }
}
