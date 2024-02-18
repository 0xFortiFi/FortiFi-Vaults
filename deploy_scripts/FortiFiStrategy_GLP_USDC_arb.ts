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

  await deploy('contracts/strategies/FortiFiGLPStrategyArb.sol:FortiFiGLPStrategyArb', {
    from: deployer,
    args: [
      "0x28f37fa106AA2159c91C769f7AE415952D28b6ac",
      "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
      "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
      "0xf0F55E8C9E23c627b253876F3B4Bf1Ef3eBA4Db0",
      "0x03d8137b35206Dda7d6313Ba0FDE02EC4c265414"
    ],
    log: true,
  });
};
export default func;