module.exports = [
    "FortiFi AVAX Stability Vault", 
    "ffAvaSV", 
    "ipfs://bafybeic35wrmxrotb2e2rnnqe6a3twakuoy4vxtlpu3yscqaj2g44s4cya/avaSV.json",
    "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
    "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
    "0xf964894470AfC11037f6BCB38609f77e9EBA9851",
    "0x97F9fE54Aa908Ac0E8B2D10244bd4bba87D51160",
    [
      {
        strategy: "0x72a1702785E1208973819B9F692801ab26FCa882", 
        depositToken: "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
        router: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4", 
        oracle: "0x0000000000000000000000000000000000000000",
        isFortiFi: true, 
        isSAMS: false,
        bps: 2500,
        decimals: 6
      }, 
      {
        strategy: "0x68D8108f6FB797e7eb0C8d9524ba08D98BF27Bcb", 
        depositToken: "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
        router: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4", 
        oracle: "0x0000000000000000000000000000000000000000",
        isFortiFi: false, 
        isSAMS: false,
        bps: 3750,
        decimals: 6
      },
      {
        strategy: "0xFB692D03BBEA21D8665035779dd3082c2B1622d0", 
        depositToken: "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
        router: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4", 
        oracle: "0x0000000000000000000000000000000000000000",
        isFortiFi: false, 
        isSAMS: false,
        bps: 3750,
        decimals: 6
      }
    ]
  ]