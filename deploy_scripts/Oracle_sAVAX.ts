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

  await deploy('FortiFiDIAPriceOracle', {
    from: deployer,
    args: ["0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE", "0x28101134A61a4c768eDAf2e32487F920314D3118", "sAVAX/USD"],
    log: true,
  });
};
export default func;