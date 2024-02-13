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
      "0xf0F55E8C9E23c627b253876F3B4Bf1Ef3eBA4Db0",
      "0x92581e042d0A5029430562C0959aEbdFeCBfFd36"
    ],
    log: true,
  });
};
export default func;