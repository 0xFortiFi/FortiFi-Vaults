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

  await deploy('FortiFiNativeStrategy', {
    from: deployer,
    args: [
      "0x8B414448de8B609e96bd63Dcf2A8aDbd5ddf7fdd",
      "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
      "0xf964894470AfC11037f6BCB38609f77e9EBA9851",
      "0xC15711C7C8DEAc7A360f9B8826E7c151088D0d8C"
    ],
    log: true,
  });
};
export default func;