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
      "FortiFi BTC.b SAMS Vault", 
      "ffBTCb", 
      "ipfs://bafybeic35wrmxrotb2e2rnnqe6a3twakuoy4vxtlpu3yscqaj2g44s4cya/BTCb.json",
      "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
      "0x152b9d0FdC40C096757F570A51E494bd4b943E50",
      "0xf964894470AfC11037f6BCB38609f77e9EBA9851",
      "0xfe3350916b44004145A30158f56F8369e096b24D",
      10000,
      [
        {strategy: "0xFE55D3eF39A25E55818e1A3900D41F561a75f4ea", isFortiFi: false, bps: 7250}, 
        {strategy: "0x8889Da43CeE581068C695A2c256Ba2D514608F4A", isFortiFi: false, bps: 2750}
      ]
    ],
    log: true,
  });
};
export default func;