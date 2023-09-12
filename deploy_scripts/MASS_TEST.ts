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

  await deploy('FortiFiMASSVault', {
    from: deployer,
    args: [
      "Test MASS - BTCb-USDC", 
      "tmBTCbUSDC", 
      "https://ipfs.io/ipfs/bafybeign4hbi6desilmocupj3hlxj3t3eiodr2sro5bgw7ld7vcznttuja/SAMS_BTCb.png",
      "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
      "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
      "0xf0F55E8C9E23c627b253876F3B4Bf1Ef3eBA4Db0",
      "0x03d8137b35206Dda7d6313Ba0FDE02EC4c265414",
      [
        {
          strategy: "0x7158017cc710585bde7d692144071eF4B4995078", 
          depositToken: "0x152b9d0FdC40C096757F570A51E494bd4b943E50",
          router: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4", 
          isFortiFi: false, 
          isSAMS: true,
          bps: 8000
        }, 
        {
          strategy: "0xFB692D03BBEA21D8665035779dd3082c2B1622d0", 
          depositToken: "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
          router: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4", 
          isFortiFi: false, 
          isSAMS: false,
          bps: 2000
        }
      ]
    ],
    log: true,
  });
};
export default func;