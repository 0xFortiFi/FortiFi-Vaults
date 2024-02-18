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

  await deploy('FortiFiWNativeMASSVault', {
    from: deployer,
    args: [
      "FortiFi WETH MASS Vault", 
      "ffWETH", 
      "ipfs://bafybeic35wrmxrotb2e2rnnqe6a3twakuoy4vxtlpu3yscqaj2g44s4cya/WETH.json",
      "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
      "0xf0F55E8C9E23c627b253876F3B4Bf1Ef3eBA4Db0",
      "0x92581e042d0A5029430562C0959aEbdFeCBfFd36",
      "0x7158017cc710585bde7d692144071eF4B4995078",
      [
        {
          strategy: "0x2Fc8e171b2688832b41881aAf3Da4D180bDa1F33", // YY DP WETH
          depositToken: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
          router: "0xd439fcd7fc5d62D44dbB2A5ebf4662E619c72873", 
          oracle: "0x0000000000000000000000000000000000000000",
          isFortiFi: false, 
          isSAMS: false,
          bps: 5500,
          decimals: 18
        }, 
        {
          strategy: "0x4719f490A20b1cC4d6ee442D5a8f3EE87fCc41f7", // YY rETH Market Silo
          depositToken: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
          router: "0xd439fcd7fc5d62D44dbB2A5ebf4662E619c72873", 
          oracle: "0x0000000000000000000000000000000000000000",
          isFortiFi: false, 
          isSAMS: false,
          bps: 2000,
          decimals: 18
        },
        {
          strategy: "0x8Bf6402AfcfE11519947829Af44770Fa44A01949", // YY Arb Market Silo
          depositToken: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
          router: "0xd439fcd7fc5d62D44dbB2A5ebf4662E619c72873", 
          oracle: "0x0000000000000000000000000000000000000000",
          isFortiFi: false, 
          isSAMS: false,
          bps: 2500,
          decimals: 18
        }
      ]
    ],
    log: true,
  });
};
export default func;