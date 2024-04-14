const hre = require("hardhat");

async function main() {
  const lock = await hre.ethers.deployContract("FortiFiGLPStrategyArb", [
    "0x28f37fa106AA2159c91C769f7AE415952D28b6ac",
    "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
    "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
    "0xf0F55E8C9E23c627b253876F3B4Bf1Ef3eBA4Db0",
    "0x03d8137b35206Dda7d6313Ba0FDE02EC4c265414"
  ]);

  await lock.waitForDeployment();

  console.log(
    `deployed to ${lock.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});