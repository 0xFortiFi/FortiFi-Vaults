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
      "Test SAMS - sAVAX", 
      "tssAVAX", 
      "https://ipfs.io/ipfs/bafybeign4hbi6desilmocupj3hlxj3t3eiodr2sro5bgw7ld7vcznttuja/SAMS_sAVAX.png",
      "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
      "0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE",
      "0xf0F55E8C9E23c627b253876F3B4Bf1Ef3eBA4Db0",
      "0x1acD9eAB461267c7cD044a088269E7aFA3ea2184",
      10000,
      [
        {strategy: "0xd0F41b1C9338eB9d374c83cC76b684ba3BB71557", isFortiFi: false, bps: 2500}, 
        {strategy: "0xc8cEeA18c2E168C6e767422c8d144c55545D23e9", isFortiFi: false, bps: 4500},
        {strategy: "0xb8f531c0d3c53B1760bcb7F57d87762Fd25c4977", isFortiFi: false, bps: 3000}
      ]
    ],
    log: true,
  });
};
export default func;