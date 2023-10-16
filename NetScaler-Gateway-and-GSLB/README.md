Users may authenticate successfully using HTTP through the NetScaler gateway that is dedicated to authentication. The Setting SSLProxyHost needs to be modified so that after users successfully authenticate, the ICA file that launches the virtual app or desktop will communicate with the NetScaler Gateway VIP that is able to handle the ICA traffic. This is because the Fastly Next-Gen WAF will only handle HTTP based traffic.

[Citrix Default ICA docs](https://docs.citrix.com/en-us/storefront/current-release/configure-manage-stores/default-ica.html)

```mermaid
flowchart TD
    Client[HTTP Client]
    NS_AUTH_GSLB{NetScaler Auth GSLB}
    NS_AUTH_1[NS Auth 1]
    NS_AUTH_2[NS Auth 2]
    NGWAF[Fastly Next-Gen WAF]
    NS_WAF_GSLB{NetScaler WAF GSLB}
    
    Client --> |auth.foo.bar:443| NS_WAF_GSLB
    NS_WAF_GSLB -->|ngwaf.foo.bar| NGWAF
    NS_WAF_GSLB -.->|auth-sites.foo.bar failover| NS_AUTH_GSLB
    NGWAF -->|auth-sites.foo.bar| NS_AUTH_GSLB
    
    NS_AUTH_GSLB --> |auth-site-1.foo.bar| NS_AUTH_1
    NS_AUTH_GSLB --> |auth-site-2.foo.bar| NS_AUTH_2

    

    Client_ICA[ICA Client]
    NS_ICA_GSLB{NetScaler ICA GSLB}
    NS_ICA_1[NetScaler ICA 1]
    NS_ICA_2[NetScaler ICA 2]

    Client_ICA -->|ica.foo.bar:443| NS_ICA_GSLB
    NS_ICA_GSLB -->|ica-site-1.foo.bar| NS_ICA_1
    NS_ICA_GSLB -->|ica-site-2.foo.bar| NS_ICA_2

```