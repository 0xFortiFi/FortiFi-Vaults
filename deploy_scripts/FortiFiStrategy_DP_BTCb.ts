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

  await deploy('FortiFiDPStrategy', {
    from: deployer,
    args: [
      "0x475589b0Ed87591A893Df42EC6076d2499bB63d0",
      "0x152b9d0FdC40C096757F570A51E494bd4b943E50",
      "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7"
    ],
    log: true,
  });
};
export default func;