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
      "Test SAMS - BTCb", 
      "tsBTCb", 
      "https://ipfs.io/ipfs/bafybeign4hbi6desilmocupj3hlxj3t3eiodr2sro5bgw7ld7vcznttuja/SAMS_BTCb.png",
      "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
      "0x152b9d0FdC40C096757F570A51E494bd4b943E50",
      "0xf0F55E8C9E23c627b253876F3B4Bf1Ef3eBA4Db0",
      "0x03d8137b35206Dda7d6313Ba0FDE02EC4c265414",
      10000,
      [
        {strategy: "0xf9cD4Db17a3FB8bc9ec0CbB34780C91cE13ce767", isFortiFi: false, bps: 3500}, 
        {strategy: "0x642FDAd3916E3aC6bfe7234376F2414BEF895Be8", isFortiFi: true, bps: 6500}
      ]
    ],
    log: true,
  });
};
export default func;