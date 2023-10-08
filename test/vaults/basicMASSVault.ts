import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";

const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";

// when doing multiple calls its not same block so we need to add seconds
async function wait(days: number, secondsToAdd: number = 0): Promise<void> {
  const seconds = days * 24 * 60 * 60 + secondsToAdd;

  await ethers.provider.send("evm_increaseTime", [seconds]);
  await ethers.provider.send("evm_mine", []);
}

describe("Basic MASS Vault Tests", function () {
  let owner: SignerWithAddress,
    addr1: SignerWithAddress,
    addr2: SignerWithAddress,
    addr3: SignerWithAddress,
    addr4: SignerWithAddress,
    MockERC20: Contract,
    NFT1: Contract,
    MockStrat: Contract,
    MockStrat2: Contract,
    MockStrat3: Contract,
    FeeMgr: Contract,
    FeeCalc: Contract,
    SAMS: Contract,
    SAMS2: Contract,
    SAMS3: Contract,
    MASS: Contract;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    const [facMockERC20, facNFT, facMockStrat, facMgr, facCalc, facSAMS, facMASS] = await Promise.all([
      ethers.getContractFactory("contracts/mock/MockERC20.sol:MockERC20"),
      ethers.getContractFactory("contracts/mock/MockERC721.sol:MockERC721"),
      ethers.getContractFactory("contracts//mock/MockBasicStrat.sol:MockBasicStrat"),
      ethers.getContractFactory("contracts/fee-managers/FortiFiFeeManager.sol:FortiFiFeeManager"),
      ethers.getContractFactory("contracts/fee-calculators/FortiFiFeeCalculator.sol:FortiFiFeeCalculator"),
      ethers.getContractFactory("contracts/vaults/FortiFiSAMSVault.sol:FortiFiSAMSVault"),
      ethers.getContractFactory("contracts/mock/FortiFiMASSVaultNoSwap.sol:FortiFiMASSVaultNoSwap"),
    ]);

    MockERC20 = await facMockERC20.deploy();
    await MockERC20.waitForDeployment();

    await MockERC20.mint(addr2.getAddress(), ethers.parseEther("1000"));
    await MockERC20.mint(addr3.getAddress(), ethers.parseEther("2000"));
    await MockERC20.mint(addr4.getAddress(), ethers.parseEther("5000"));

    NFT1 = await facNFT.deploy();

    await NFT1.waitForDeployment();

    await NFT1.mint(addr2.getAddress(), 3);
    await NFT1.mint(addr3.getAddress(), 10);

    MockStrat = await facMockStrat.deploy(MockERC20.getAddress());
    await MockStrat.waitForDeployment();

    MockStrat2 = await facMockStrat.deploy(MockERC20.getAddress());
    await MockStrat2.waitForDeployment();

    MockStrat3 = await facMockStrat.deploy(MockERC20.getAddress());
    await MockStrat3.waitForDeployment();

    FeeMgr = await facMgr.deploy([addr1.getAddress()], [10000]);

    FeeCalc = await facCalc.deploy([NFT1.getAddress()], [0,1,3,5,10], [700,600,500,400,300], false);

    SAMS = await facSAMS.deploy("Basic Vault", 
                                  "ffBasic", 
                                  "ipfs://metadata",
                                  MockERC20.getAddress(),
                                  MockERC20.getAddress(),
                                  FeeMgr.getAddress(),
                                  FeeCalc.getAddress(),
                                  10000,
                                  [
                                    {strategy: MockStrat.getAddress(), isFortiFi: false, bps: 2000}, 
                                    {strategy: MockStrat2.getAddress(), isFortiFi: false, bps: 5000},
                                    {strategy: MockStrat3.getAddress(), isFortiFi: false, bps: 3000}
                                  ]);
    await SAMS.waitForDeployment();

    await SAMS.connect(owner).flipPaused();

    SAMS2 = await facSAMS.deploy("Basic Vault", 
                                  "ffBasic", 
                                  "ipfs://metadata",
                                  MockERC20.getAddress(),
                                  MockERC20.getAddress(),
                                  FeeMgr.getAddress(),
                                  FeeCalc.getAddress(),
                                  10000,
                                  [
                                    {strategy: MockStrat.getAddress(), isFortiFi: false, bps: 5000}, 
                                    {strategy: MockStrat2.getAddress(), isFortiFi: false, bps: 5000}
                                  ]);
    await SAMS2.waitForDeployment();

    await SAMS2.connect(owner).flipPaused();

    SAMS3 = await facSAMS.deploy("Basic Vault", 
                                  "ffBasic", 
                                  "ipfs://metadata",
                                  MockERC20.getAddress(),
                                  MockERC20.getAddress(),
                                  FeeMgr.getAddress(),
                                  FeeCalc.getAddress(),
                                  10000,
                                  [
                                    {strategy: MockStrat2.getAddress(), isFortiFi: false, bps: 5000},
                                    {strategy: MockStrat3.getAddress(), isFortiFi: false, bps: 5000}
                                  ]);
    await SAMS3.waitForDeployment();

    await SAMS3.connect(owner).flipPaused();

    MASS = await facMASS.deploy("Basic Vault", 
                                  "ffBasic", 
                                  "ipfs://metadata",
                                  MockERC20.getAddress(),
                                  MockERC20.getAddress(),
                                  FeeMgr.getAddress(),
                                  FeeCalc.getAddress(),
                                  [
                                    {
                                      strategy: SAMS.getAddress(), 
                                      depositToken: MockERC20.getAddress(),
                                      router: owner.getAddress(),
                                      oracle: owner.getAddress(), 
                                      isFortiFi: false, 
                                      isSAMS: true,
                                      bps: 4000,
                                      decimals: 8
                                    }, 
                                    {
                                      strategy: SAMS2.getAddress(), 
                                      depositToken: MockERC20.getAddress(),
                                      router: owner.getAddress(), 
                                      oracle: owner.getAddress(), 
                                      isFortiFi: false, 
                                      isSAMS: true,
                                      bps: 1000,
                                      decimals: 8
                                    }, 
                                    {
                                      strategy: SAMS3.getAddress(), 
                                      depositToken: MockERC20.getAddress(),
                                      router: owner.getAddress(), 
                                      oracle: owner.getAddress(), 
                                      isFortiFi: false, 
                                      isSAMS: true,
                                      bps: 5000,
                                      decimals: 8
                                    }
                                  ]);
    await MASS.waitForDeployment();

    await SAMS.connect(owner).setNoFeesFor(MASS.getAddress(), true);
    await SAMS2.connect(owner).setNoFeesFor(MASS.getAddress(), true);
    await SAMS3.connect(owner).setNoFeesFor(MASS.getAddress(), true);

    //  Vault Strategy Allocations
    //
    //  SAMS        MASS 40%
    //  1 - 20%  ->    8%
    //  2 - 50%  ->    20%
    //  3 - 30%  ->    12%
    //
    //  SAMS2       MASS 10%               \     MASS
    //  1 - 50%  ->    5%         ==========\   1 - 13%
    //  2 - 50%  ->    5%         ==========/   2 - 50%
    //  3 - 0%   ->    0%                  /    3 - 37%
    //
    //  SAMS3       MASS 50%
    //  1 - 0%   ->    0%
    //  2 - 50%  ->    25%
    //  3 - 50%  ->    25%
    //

  });

  it("Check that ERC20 tokens are minted to addresses", async function () {
    let balance1 = await MockERC20.balanceOf(addr2.getAddress());
    expect(Number(balance1)).to.equal(
      Number(ethers.parseEther("1000"))
    );

    let balance2 = await MockERC20.balanceOf(addr3.getAddress());
    expect(Number(balance2)).to.equal(
      Number(ethers.parseEther("2000"))
    );

    let balance3 = await MockERC20.balanceOf(addr4.getAddress());
    expect(Number(balance3)).to.equal(
      Number(ethers.parseEther("5000"))
    );
  });

  it("Check that NFT1 tokens are minted to addresses", async function () {
    let balance1 = await NFT1.balanceOf(addr2.getAddress());
    expect(Number(balance1)).to.equal(
      3
    );

    let balance2 = await NFT1.balanceOf(addr3.getAddress());
    expect(Number(balance2)).to.equal(
      10
    );
  });

  it("Check that ERC20 tokens can be deposited and withdrawn", async function () {
    // Approve vault
    await MockERC20.connect(addr2).approve(MASS.getAddress(), ethers.parseEther("1000"));

    // Can't deposit while paused
    await expect(
      MASS.connect(addr2).deposit(ethers.parseEther("1000"))
    ).to.be.revertedWith("FortiFi: Contract paused");

    // Unpause and deposit
    await MASS.connect(owner).flipPaused();
    await MASS.connect(addr2).deposit(ethers.parseEther("1000"));

    let balance1 = await MockERC20.balanceOf(addr2.getAddress());
    expect(Number(balance1)).to.equal(
      0
    );

    let balance1s = await MockERC20.balanceOf(MockStrat.getAddress());
    expect(Number(balance1s)).to.equal(
      Number(ethers.parseEther("130"))
    );

    let balance1s2 = await MockERC20.balanceOf(MockStrat2.getAddress());
    expect(Number(balance1s2)).to.equal(
      Number(ethers.parseEther("500"))
    );

    let balance1s3 = await MockERC20.balanceOf(MockStrat3.getAddress());
    expect(Number(balance1s3)).to.equal(
      Number(ethers.parseEther("370"))
    );

    let balance2 = await MASS.balanceOf(addr2.getAddress(), 1);
    expect(Number(balance2)).to.equal(
      Number(1)
    );

    // Don't allow 0 deposit or withdraw without token
    await expect(
      MASS.connect(addr2).deposit(0)
    ).to.be.revertedWith("FortiFi: Invalid deposit amount");

    await expect(
      MASS.connect(addr2).withdraw(2)
    ).to.be.revertedWith("FortiFi: Not the owner of token");

    // withdraw
    await MASS.connect(addr2).withdraw(1);

    let balance3 = await MockERC20.balanceOf(addr2.getAddress());
    expect(Number(balance3)).to.equal(
      Number(ethers.parseEther("1000"))
    );

    let balance3s = await MockERC20.balanceOf(MockStrat.getAddress());
    expect(Number(balance3s)).to.equal(
      0
    );

    let balance3s2 = await MockERC20.balanceOf(MockStrat2.getAddress());
    expect(Number(balance3s2)).to.equal(
      0
    );

    let balance3s3 = await MockERC20.balanceOf(MockStrat3.getAddress());
    expect(Number(balance3s3)).to.equal(
      0
    );

    let balance4 = await MASS.balanceOf(addr2.getAddress(), 1);
    expect(Number(balance4)).to.equal(
      0
    );

  });

  it("Check that vault can handle profits and fees", async function () {
    // Approve vault
    await MockERC20.connect(addr2).approve(MASS.getAddress(), ethers.parseEther("1000"));

    // Unpause and deposit
    await MASS.connect(owner).flipPaused();
    await MASS.connect(addr2).deposit(ethers.parseEther("1000"));

    let balance1 = await MockERC20.balanceOf(addr2.getAddress());
    expect(Number(balance1)).to.equal(
      0
    );

    let balance1s = await MockERC20.balanceOf(MockStrat.getAddress());
    expect(Number(balance1s)).to.equal(
      Number(ethers.parseEther("130"))
    );

    let balance1s2 = await MockERC20.balanceOf(MockStrat2.getAddress());
    expect(Number(balance1s2)).to.equal(
      Number(ethers.parseEther("500"))
    );

    let balance1s3 = await MockERC20.balanceOf(MockStrat3.getAddress());
    expect(Number(balance1s3)).to.equal(
      Number(ethers.parseEther("370"))
    );

    let balance2 = await MASS.balanceOf(addr2.getAddress(), 1);
    expect(Number(balance2)).to.equal(
      Number(1)
    );

    // Add yield to contract
    await MockERC20.mint(MockStrat.getAddress(), ethers.parseEther("100"));

    // withdraw
    await MASS.connect(addr2).withdraw(1);

    let balance3 = await MockERC20.balanceOf(addr2.getAddress());
    expect(Number(balance3)).to.equal(
      Number(ethers.parseEther("1095")) // 100 (profit) * .95 = 95 + 1000 (original deposit) = 1095
    );

    let balance3f = await MockERC20.balanceOf(addr1.getAddress());
    expect(Number(balance3f)).to.equal(
      Number(ethers.parseEther("5")) // 100 * .05 = 5
    );

    let balance3s = await MockERC20.balanceOf(MockStrat.getAddress());
    expect(Number(balance3s)).to.equal(
      0
    );

    let balance3s2 = await MockERC20.balanceOf(MockStrat2.getAddress());
    expect(Number(balance3s2)).to.equal(
      0
    );

    let balance3s3 = await MockERC20.balanceOf(MockStrat3.getAddress());
    expect(Number(balance3s3)).to.equal(
      0
    );

    let balance4 = await MASS.balanceOf(addr2.getAddress(), 1);
    expect(Number(balance4)).to.equal(
      0
    );

  });

  it("Check that users can add to position", async function () {
    // Approve vault
    await MockERC20.connect(addr2).approve(MASS.getAddress(), ethers.parseEther("1000"));
    await MockERC20.connect(addr3).approve(MASS.getAddress(), ethers.parseEther("2000"));
    await MockERC20.connect(addr4).approve(MASS.getAddress(), ethers.parseEther("5000"));

    // Unpause and deposit
    await MASS.connect(owner).flipPaused();
    await MASS.connect(addr2).deposit(ethers.parseEther("1000"));
    await MASS.connect(addr3).deposit(ethers.parseEther("2000"));
    await MASS.connect(addr4).deposit(ethers.parseEther("2000"));

    let balance1 = await MockERC20.balanceOf(addr2.getAddress());
    expect(Number(balance1)).to.equal(
      0
    );

    let balance1b = await MockERC20.balanceOf(addr3.getAddress());
    expect(Number(balance1b)).to.equal(
      0
    );

    let balance1c = await MockERC20.balanceOf(addr4.getAddress());
    expect(Number(balance1c)).to.equal(
      Number(ethers.parseEther("3000"))
    );

    let balance1s = await MockERC20.balanceOf(MockStrat.getAddress());
    expect(Number(balance1s)).to.equal(
      Number(ethers.parseEther("650"))
    );

    let balance1s2 = await MockERC20.balanceOf(MockStrat2.getAddress());
    expect(Number(balance1s2)).to.equal(
      Number(ethers.parseEther("2500"))
    );

    let balance1s3 = await MockERC20.balanceOf(MockStrat3.getAddress());
    expect(Number(balance1s3)).to.equal(
      Number(ethers.parseEther("1850"))
    );

    let balance2 = await MASS.balanceOf(addr2.getAddress(), 1);
    expect(Number(balance2)).to.equal(
      Number(1)
    );

    let balance2b = await MASS.balanceOf(addr3.getAddress(), 2);
    expect(Number(balance2b)).to.equal(
      Number(1)
    );

    let balance2c = await MASS.balanceOf(addr4.getAddress(), 3);
    expect(Number(balance2c)).to.equal(
      Number(1)
    );

    // withdraw
    await MASS.connect(addr2).withdraw(1);

    let balance3 = await MockERC20.balanceOf(addr2.getAddress());
    expect(Number(balance3)).to.equal(
      Number(ethers.parseEther("1000"))
    );

    let balance3s = await MockERC20.balanceOf(MockStrat.getAddress());
    expect(Number(balance3s)).to.equal(
      Number(ethers.parseEther("520"))
    );

    let balance3s2 = await MockERC20.balanceOf(MockStrat2.getAddress());
    expect(Number(balance3s2)).to.equal(
      Number(ethers.parseEther("2000"))
    );

    let balance3s3 = await MockERC20.balanceOf(MockStrat3.getAddress());
    expect(Number(balance3s3)).to.equal(
      Number(ethers.parseEther("1480"))
    );

    let balance4 = await MASS.balanceOf(addr2.getAddress(), 1);
    expect(Number(balance4)).to.equal(
      0
    );

    // add to addr4 position
    await MASS.connect(addr4).add(ethers.parseEther("3000"), 3);

    let balance5 = await MockERC20.balanceOf(addr4.getAddress());
    expect(Number(balance5)).to.equal(
      0
    );

    let balance5s = await MockERC20.balanceOf(MockStrat.getAddress());
    expect(Number(balance5s)).to.equal(
      Number(ethers.parseEther("910"))
    );

    let balance5s2 = await MockERC20.balanceOf(MockStrat2.getAddress());
    expect(Number(balance5s2)).to.equal(
      Number(ethers.parseEther("3500"))
    );

    let balance5s3 = await MockERC20.balanceOf(MockStrat3.getAddress());
    expect(Number(balance5s3)).to.equal(
      Number(ethers.parseEther("2590"))
    );

    // withdraw all positions
    await MASS.connect(addr3).withdraw(2);
    await MASS.connect(addr4).withdraw(3);

    let balance6 = await MockERC20.balanceOf(addr3.getAddress());
    expect(Number(balance6)).to.equal(
      Number(ethers.parseEther("2000"))
    );

    let balance6b = await MockERC20.balanceOf(addr4.getAddress());
    expect(Number(balance6b)).to.equal(
      Number(ethers.parseEther("5000"))
    );

    let balance6s = await MockERC20.balanceOf(MockStrat.getAddress());
    expect(Number(balance6s)).to.equal(
      0
    );

    let balance6s2 = await MockERC20.balanceOf(MockStrat2.getAddress());
    expect(Number(balance6s2)).to.equal(
      0
    );

    let balance6s3 = await MockERC20.balanceOf(MockStrat3.getAddress());
    expect(Number(balance6s3)).to.equal(
      0
    );

    let balance7 = await MASS.balanceOf(addr3.getAddress(), 2);
    expect(Number(balance7)).to.equal(
      0
    );

    let balance7b = await MASS.balanceOf(addr4.getAddress(), 3);
    expect(Number(balance7b)).to.equal(
      0
    );

  });

  it("Check that users can rebalance positions", async function () {
    // Approve vault
    await MockERC20.connect(addr2).approve(MASS.getAddress(), ethers.parseEther("1000"));
    await MockERC20.connect(addr3).approve(MASS.getAddress(), ethers.parseEther("2000"));
    await MockERC20.connect(addr4).approve(MASS.getAddress(), ethers.parseEther("5000"));

    // Unpause and deposit
    await MASS.connect(owner).flipPaused();
    await MASS.connect(addr2).deposit(ethers.parseEther("1000"));
    await MASS.connect(addr3).deposit(ethers.parseEther("2000"));
    await MASS.connect(addr4).deposit(ethers.parseEther("2000"));

    let balance1 = await MockERC20.balanceOf(addr2.getAddress());
    expect(Number(balance1)).to.equal(
      0
    );

    let balance1b = await MockERC20.balanceOf(addr3.getAddress());
    expect(Number(balance1b)).to.equal(
      0
    );

    let balance1c = await MockERC20.balanceOf(addr4.getAddress());
    expect(Number(balance1c)).to.equal(
      Number(ethers.parseEther("3000"))
    );

    let balance1s = await MockERC20.balanceOf(MockStrat.getAddress());
    expect(Number(balance1s)).to.equal(
      Number(ethers.parseEther("650"))
    );

    let balance1s2 = await MockERC20.balanceOf(MockStrat2.getAddress());
    expect(Number(balance1s2)).to.equal(
      Number(ethers.parseEther("2500"))
    );

    let balance1s3 = await MockERC20.balanceOf(MockStrat3.getAddress());
    expect(Number(balance1s3)).to.equal(
      Number(ethers.parseEther("1850"))
    );

    let balance2 = await MASS.balanceOf(addr2.getAddress(), 1);
    expect(Number(balance2)).to.equal(
      Number(1)
    );

    let balance2b = await MASS.balanceOf(addr3.getAddress(), 2);
    expect(Number(balance2b)).to.equal(
      Number(1)
    );

    let balance2c = await MASS.balanceOf(addr4.getAddress(), 3);
    expect(Number(balance2c)).to.equal(
      Number(1)
    );

    // Add yield to contract
    await MockERC20.mint(MockStrat.getAddress(), ethers.parseEther("100"));

    // rebalance
    await MASS.connect(addr2).rebalance(1);

    let balance3s = await MockERC20.balanceOf(MockStrat.getAddress());
    expect(Number(balance3s)).to.equal(
      Number(ethers.parseEther("732.6")) // 750 - 150 + 132.6
    );

    let balance3s2 = await MockERC20.balanceOf(MockStrat2.getAddress());
    expect(Number(balance3s2)).to.equal(
      Number(ethers.parseEther("2510")) // 2500 - 500 + 510
    );

    let balance3s3 = await MockERC20.balanceOf(MockStrat3.getAddress());
    expect(Number(balance3s3)).to.equal(
      Number(ethers.parseEther("1857.4")) // 1850 - 370 + 377.4
    );

  });

  it("Check that invalid configurations revert", async function () {
    const [facMASS] = await Promise.all([
      ethers.getContractFactory("contracts/mock/FortiFiMASSVaultNoSwap.sol:FortiFiMASSVaultNoSwap"),
    ]);

    await expect(
      facMASS.deploy("Basic Vault", 
                      "ffBasic", 
                      "ipfs://metadata",
                      MockERC20.getAddress(),
                      MockERC20.getAddress(),
                      FeeMgr.getAddress(),
                      FeeCalc.getAddress(),
                      [
                        {
                          strategy: SAMS.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 4000,
                          decimals: 8
                        }, 
                        {
                          strategy: SAMS2.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 1000,
                          decimals: 8
                        }, 
                        {
                          strategy: SAMS3.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 1000,
                          decimals: 8
                        }
                      ])
    ).to.be.revertedWith("FortiFi: Invalid total bps");

    await expect(
      facMASS.deploy("Basic Vault", 
                      "ffBasic", 
                      "ipfs://metadata",
                      MockERC20.getAddress(),
                      MockERC20.getAddress(),
                      FeeMgr.getAddress(),
                      FeeCalc.getAddress(),
                      [
                        {
                          strategy: SAMS.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 4000,
                          decimals: 8
                        }, 
                        {
                          strategy: SAMS2.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 1000,
                          decimals: 8
                        }, 
                        {
                          strategy: NULL_ADDRESS, 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 5000,
                          decimals: 8
                        }
                      ])
    ).to.be.revertedWith("FortiFi: Invalid strat address");

    await expect(
      facMASS.deploy("Basic Vault", 
                      "ffBasic", 
                      "ipfs://metadata",
                      MockERC20.getAddress(),
                      MockERC20.getAddress(),
                      FeeMgr.getAddress(),
                      FeeCalc.getAddress(),
                      [
                        {
                          strategy: SAMS.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 4000,
                          decimals: 8
                        }, 
                        {
                          strategy: SAMS2.getAddress(), 
                          depositToken: NULL_ADDRESS,
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 1000,
                          decimals: 8
                        }, 
                        {
                          strategy: SAMS3.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 5000,
                          decimals: 8
                        }
                      ])
    ).to.be.revertedWith("FortiFi: Invalid ERC20 address");

    await expect(
      facMASS.deploy("Basic Vault", 
                      "ffBasic", 
                      "ipfs://metadata",
                      NULL_ADDRESS,
                      MockERC20.getAddress(),
                      FeeMgr.getAddress(),
                      FeeCalc.getAddress(),
                      [
                        {
                          strategy: SAMS.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 4000,
                          decimals: 8
                        }, 
                        {
                          strategy: SAMS2.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 1000,
                          decimals: 8
                        }, 
                        {
                          strategy: SAMS3.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 5000,
                          decimals: 8
                        }
                      ])
    ).to.be.revertedWith("FortiFi: Invalid native token");

    await expect(
      facMASS.deploy("Basic Vault", 
                      "ffBasic", 
                      "ipfs://metadata",
                      MockERC20.getAddress(),
                      NULL_ADDRESS,
                      FeeMgr.getAddress(),
                      FeeCalc.getAddress(),
                      [
                        {
                          strategy: SAMS.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 4000,
                          decimals: 8
                        }, 
                        {
                          strategy: SAMS2.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 1000,
                          decimals: 8
                        }, 
                        {
                          strategy: SAMS3.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 5000,
                          decimals: 8
                        }
                      ])
    ).to.be.revertedWith("FortiFi: Invalid deposit token");

    await expect(
      facMASS.deploy("Basic Vault", 
                      "ffBasic", 
                      "ipfs://metadata",
                      MockERC20.getAddress(),
                      MockERC20.getAddress(),
                      NULL_ADDRESS,
                      FeeCalc.getAddress(),
                      [
                        {
                          strategy: SAMS.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 4000,
                          decimals: 8
                        }, 
                        {
                          strategy: SAMS2.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 1000,
                          decimals: 8
                        }, 
                        {
                          strategy: SAMS3.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 5000,
                          decimals: 8
                        }
                      ])
    ).to.be.revertedWith("FortiFi: Invalid feeManager");

    await expect(
      facMASS.deploy("Basic Vault", 
                      "ffBasic", 
                      "ipfs://metadata",
                      MockERC20.getAddress(),
                      MockERC20.getAddress(),
                      FeeMgr.getAddress(),
                      NULL_ADDRESS,
                      [
                        {
                          strategy: SAMS.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 4000,
                          decimals: 8
                        }, 
                        {
                          strategy: SAMS2.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 1000,
                          decimals: 8
                        }, 
                        {
                          strategy: SAMS3.getAddress(), 
                          depositToken: MockERC20.getAddress(),
                          router: owner.getAddress(), 
                          oracle: owner.getAddress(), 
                          isFortiFi: false, 
                          isSAMS: true,
                          bps: 5000,
                          decimals: 8
                        }
                      ])
    ).to.be.revertedWith("FortiFi: Invalid feeCalculator");

  });

  it("Check that invalid transactions revert", async function () {
        // Approve vault
        await MockERC20.connect(addr2).approve(MASS.getAddress(), ethers.parseEther("1000"));
        await MockERC20.connect(addr3).approve(MASS.getAddress(), ethers.parseEther("2000"));
        await MockERC20.connect(addr4).approve(MASS.getAddress(), ethers.parseEther("5000"));
    
        // Unpause and deposit
        await MASS.connect(owner).flipPaused();
        
        await expect(
          MASS.connect(addr2).deposit(0)
        ).to.be.revertedWith("FortiFi: Invalid deposit amount");

        await MASS.connect(addr2).deposit(ethers.parseEther("500"));
        await MASS.connect(addr3).deposit(ethers.parseEther("500"));

        await expect(
          MASS.connect(addr2).add(ethers.parseEther("500"), 2)
        ).to.be.revertedWith("FortiFi: Not the owner of token");

        await expect(
          MASS.connect(addr2).withdraw(2)
        ).to.be.revertedWith("FortiFi: Not the owner of token");

        await expect(
          MASS.connect(addr2).rebalance(2)
        ).to.be.revertedWith("FortiFi: Invalid message sender");

        await expect(MASS.connect(owner).setStrategies(
          [
            {
              strategy: SAMS2.getAddress(), 
              depositToken: MockERC20.getAddress(),
              router: owner.getAddress(), 
              oracle: owner.getAddress(), 
              isFortiFi: false, 
              isSAMS: true,
              bps: 5000,
              decimals: 8
            }, 
            {
              strategy: SAMS2.getAddress(), 
              depositToken: MockERC20.getAddress(),
              router: owner.getAddress(), 
              oracle: owner.getAddress(), 
              isFortiFi: false, 
              isSAMS: true,
              bps: 5000,
              decimals: 8
            }
          ]
        )).to.be.revertedWith(`DuplicateStrategy`);

        await MASS.connect(owner).setStrategies(
          [
            {
              strategy: SAMS2.getAddress(), 
              depositToken: MockERC20.getAddress(),
              router: owner.getAddress(), 
              oracle: owner.getAddress(), 
              isFortiFi: false, 
              isSAMS: true,
              bps: 5000,
              decimals: 8
            }, 
            {
              strategy: SAMS3.getAddress(), 
              depositToken: MockERC20.getAddress(),
              router: owner.getAddress(), 
              oracle: owner.getAddress(), 
              isFortiFi: false, 
              isSAMS: true,
              bps: 5000,
              decimals: 8
            }
          ]
        );

        await expect(
          MASS.connect(addr2).add(ethers.parseEther("500"), 1)
        ).to.be.revertedWith("FortiFi: Can't add to receipt");

  });

});