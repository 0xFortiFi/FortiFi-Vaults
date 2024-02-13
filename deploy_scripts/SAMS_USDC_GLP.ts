import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
import "@nomiclabs/hardhat-etherscan";
import '@nomicfoundation/hardhat-ethers';
import 'hardhat-deploy';
import 'hardhat-deploy-ethers';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();

  await deploy('FortiFiSAMSVault', {
    from: deployer,
    args: [
      "Test SAMS - USDC", 
      "tsUSDC", 
      "https://ipfs.io/ipfs/bafybeign4hbi6desilmocupj3hlxj3t3eiodr2sro5bgw7ld7vcznttuja/SAMS_USDC.png",
      "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
      "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
      "0xf0F55E8C9E23c627b253876F3B4Bf1Ef3eBA4Db0",
      "0x92581e042d0A5029430562C0959aEbdFeCBfFd36",
      10000,
      [
        {strategy: "0x11F40BBEbF8C0f8b424eAc20bC1bab3f2F4186d5", isFortiFi: true, bps: 10000}
      ]
    ],
    log: true,
  });
};
export default func;