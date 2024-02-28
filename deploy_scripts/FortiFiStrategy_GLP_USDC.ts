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

  await deploy('FortiFiGLPStrategy', {
    from: deployer,
    args: [
      "0x9f637540149f922145c06e1aa3f38dcDc32Aff5C",
      "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
      "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
      "0xf964894470AfC11037f6BCB38609f77e9EBA9851",
      "0x97F9fE54Aa908Ac0E8B2D10244bd4bba87D51160"
    ],
    log: true,
  });
};
export default func;