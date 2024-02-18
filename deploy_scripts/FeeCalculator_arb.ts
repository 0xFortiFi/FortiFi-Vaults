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

  await deploy('FortiFiFeeCalculator', {
    from: deployer,
    args: [
      ["0x18b90eB9c0c3840d19333E4B1D943Bc04de05313"], 
      [0, 1, 3, 5, 7, 10],
      [800, 600, 550, 500, 450, 400],
      false
    ],
    log: true,
  });
};
export default func;