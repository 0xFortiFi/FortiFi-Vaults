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
      "FortiFi WAVAX MASS Vault", 
      "ffWAVAX", 
      "ipfs://bafybeic35wrmxrotb2e2rnnqe6a3twakuoy4vxtlpu3yscqaj2g44s4cya/WAVAX.json",
      "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
      "0xf964894470AfC11037f6BCB38609f77e9EBA9851",
      "0xC15711C7C8DEAc7A360f9B8826E7c151088D0d8C",
      "0xdFABbc3d82b8234A88A9f64faAB1f514a857a3dF",
      [
        {
          strategy: "0xb97D7C44cA03abA8d41FDaC81683312e4ACbba00", // YY DP WAVAX
          depositToken: "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
          router: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4", 
          oracle: "0x0000000000000000000000000000000000000000",
          isFortiFi: false, 
          isSAMS: false,
          bps: 5500,
          decimals: 18
        }, 
        {
          strategy: "0x0A4BC64396EA683244Ce36a40114Ac6713aFC725", // YY Benqi AVAX
          depositToken: "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
          router: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4", 
          oracle: "0x0000000000000000000000000000000000000000",
          isFortiFi: true, 
          isSAMS: false,
          bps: 2250,
          decimals: 18
        },
        {
          strategy: "0xc8cEeA18c2E168C6e767422c8d144c55545D23e9", // YY Benqi sAVAX
          depositToken: "0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE",
          router: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4", 
          oracle: "0x0C53b73EfDdE61874C945395a813253326dE8eEA",
          isFortiFi: false, 
          isSAMS: false,
          bps: 2250,
          decimals: 18
        }
      ]
    ],
    log: true,
  });
};
export default func;