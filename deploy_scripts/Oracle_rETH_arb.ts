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

  await deploy('FortiFiDIAPriceOracleL2', {
    from: deployer,
    args: ["0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8", 
      "0xD210347A7F3E4D3B5f96D4AFa59372247f3A2f84",
      "0xFdB631F5EE196F0ed6FAa767959853A9F217697D",
      "rETH/USD"
    ],
    log: true,
  });
};
export default func;