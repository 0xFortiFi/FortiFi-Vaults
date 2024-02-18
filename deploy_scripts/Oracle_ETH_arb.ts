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

  await deploy('FortiFiPriceOracleL2', {
    from: deployer,
    args: ["0x82aF49447D8a07e3bd95BD0d56f35241523fBab1", 
      "0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612",
      "0xFdB631F5EE196F0ed6FAa767959853A9F217697D"
    ],
    log: true,
  });
};
export default func;