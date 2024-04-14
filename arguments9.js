module.exports = [
    "FortiFi WAVAX LST MultiYield", 
    "ffWavaxLST", 
    "ipfs://bafybeiab2shlsewtv2i4dka7qpsrozxsoqnoldsqrt3tljv37gz5baid6q/WAVAX-LST.json",
    "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
    "0xf964894470AfC11037f6BCB38609f77e9EBA9851",
    "0xC15711C7C8DEAc7A360f9B8826E7c151088D0d8C",
    "0xdFABbc3d82b8234A88A9f64faAB1f514a857a3dF",
    [
      {
        strategy: "0xca33e819B1A3e519b02830cED658Fd0543599410", // YY Wombat sAVAX
        depositToken: "0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE",
        router: "0x8E936EF88078534663929D55c3094567dca2F7Ad", 
        oracle: "0x0C53b73EfDdE61874C945395a813253326dE8eEA",
        isFortiFi: true, 
        isSAMS: false,
        bps: 5000,
        decimals: 18
      }, 
      {
        strategy: "0x666d883b9d5BB40f4d100d3c9919abfE29608F30", // YY Wombat ggAVAX
        depositToken: "0xA25EaF2906FA1a3a13EdAc9B9657108Af7B703e3",
        router: "0xa5eeC52Dd815Ee7b3b91Da8AF5FacE1aA996336C", 
        oracle: "0x4a30CB77AAC31c9B7feC0700FEaCd3Bdb44147F6",
        isFortiFi: true, 
        isSAMS: false,
        bps: 5000,
        decimals: 18
      }
    ]
  ]