module.exports = [
    "FortiFi Arbitrum Stability Vault", 
    "ffArbiSV", 
    "ipfs://bafybeic35wrmxrotb2e2rnnqe6a3twakuoy4vxtlpu3yscqaj2g44s4cya/arbiSV.json",
    "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
    "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
    "0xf0F55E8C9E23c627b253876F3B4Bf1Ef3eBA4Db0",
    "0x03d8137b35206Dda7d6313Ba0FDE02EC4c265414",
    [
      {
        strategy: "0x4D7604D1c1e7c1998CD44a1b49a3d79f43b93E24", 
        depositToken: "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
        router: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4", 
        oracle: "0x0000000000000000000000000000000000000000",
        isFortiFi: true, 
        isSAMS: false,
        bps: 3500,
        decimals: 6
      }, 
      {
        strategy: "0x5847EB0aC310845510880c6871E0cE6d8b0f57Fc", 
        depositToken: "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
        router: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4", 
        oracle: "0x0000000000000000000000000000000000000000",
        isFortiFi: false, 
        isSAMS: false,
        bps: 3750,
        decimals: 6
      },
      {
        strategy: "0x502537b1491065D733f3a48b6a6C287a74aa519B", 
        depositToken: "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
        router: "0xd439fcd7fc5d62D44dbB2A5ebf4662E619c72873", 
        oracle: "0x33787e3459415e6b346f3e564309497e18A722cD",
        isFortiFi: false, 
        isSAMS: false,
        bps: 2750,
        decimals: 6
      }
    ]
  ]