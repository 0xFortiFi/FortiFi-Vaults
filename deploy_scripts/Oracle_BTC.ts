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

  await deploy('FortiFiPriceOracle', {
    from: deployer,
    args: ["0x152b9d0FdC40C096757F570A51E494bd4b943E50", "0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743"],
    log: true,
  });
};
export default func;