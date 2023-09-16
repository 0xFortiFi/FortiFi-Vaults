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
        {strategy: "0x14517a26005f3F92AEa60b6619aC0e10E3A718d1", isFortiFi: true, bps: 2000}, 
        {strategy: "0xFB692D03BBEA21D8665035779dd3082c2B1622d0", isFortiFi: false, bps: 4000},
        {strategy: "0x45C53FB370CA5066D93FE64913e24B886322bE3B", isFortiFi: true, bps: 4000}
      ]
    ],
    log: true,
  });
};
export default func;