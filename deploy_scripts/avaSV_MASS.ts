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

  await deploy('FortiFiMASSVault', {
    from: deployer,
    args: [
      "FortiFi AVAX Stability Vault", 
      "ffAvaSV", 
      "ipfs://bafybeic35wrmxrotb2e2rnnqe6a3twakuoy4vxtlpu3yscqaj2g44s4cya/avaSV.json",
      "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
      "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
      "0xf964894470AfC11037f6BCB38609f77e9EBA9851",
      "0x97F9fE54Aa908Ac0E8B2D10244bd4bba87D51160",
      [
        {
          strategy: "0xb97AFc8d6d6F100358E21D6Ab3A3aa3Ec1435731", 
          depositToken: "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
          router: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4", 
          oracle: "0x0000000000000000000000000000000000000000",
          isFortiFi: true, 
          isSAMS: false,
          bps: 2500,
          decimals: 6
        }, 
        {
          strategy: "0x68D8108f6FB797e7eb0C8d9524ba08D98BF27Bcb", 
          depositToken: "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
          router: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4", 
          oracle: "0x0000000000000000000000000000000000000000",
          isFortiFi: false, 
          isSAMS: false,
          bps: 3000,
          decimals: 6
        },
        {
          strategy: "0xFB692D03BBEA21D8665035779dd3082c2B1622d0", 
          depositToken: "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
          router: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4", 
          oracle: "0x0000000000000000000000000000000000000000",
          isFortiFi: false, 
          isSAMS: false,
          bps: 3000,
          decimals: 6
        },
        {
          strategy: "0x701792A64Cea365a2cBd8e3F2e544654dc3307eF", 
          depositToken: "0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7",
          router: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4", 
          oracle: "0xDC655E3Dc8f36096c779294D03C62b3af15De8b0",
          isFortiFi: false, 
          isSAMS: false,
          bps: 1500,
          decimals: 6
        }
      ]
    ],
    log: true,
  });
};
export default func;