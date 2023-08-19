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

describe("Basic Vault Tests", function () {
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
    Vault: Contract;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    const [facMockERC20, facNFT, facMockStrat, facMgr, facCalc, facVault] = await Promise.all([
      ethers.getContractFactory("contracts/mock/MockERC20.sol:MockERC20"),
      ethers.getContractFactory("contracts/mock/MockERC721.sol:MockERC721"),
      ethers.getContractFactory("contracts//mock/MockBasicStrat.sol:MockBasicStrat"),
      ethers.getContractFactory("contracts/fee-managers/FortiFiFeeManager.sol:FortiFiFeeManager"),
      ethers.getContractFactory("contracts/fee-calculators/FortiFiFeeCalculator.sol:FortiFiFeeCalculator"),
      ethers.getContractFactory("contracts/vaults/FortiFiSAMSVault.sol:FortiFiSAMSVault"),
    ]);

    MockERC20 = await facMockERC20.deploy();
    await MockERC20.deployed();

    await MockERC20.mint(addr2.address, ethers.utils.parseEther("1000"));
    await MockERC20.mint(addr3.address, ethers.utils.parseEther("2000"));
    await MockERC20.mint(addr4.address, ethers.utils.parseEther("5000"));

    NFT1 = await facNFT.deploy();

    await NFT1.deployed();

    await NFT1.mint(addr2.address, 3);
    await NFT1.mint(addr3.address, 10);

    MockStrat = await facMockStrat.deploy(MockERC20.address);
    await MockStrat.deployed();

    MockStrat2 = await facMockStrat.deploy(MockERC20.address);
    await MockStrat2.deployed();

    MockStrat3 = await facMockStrat.deploy(MockERC20.address);
    await MockStrat3.deployed();

    FeeMgr = await facMgr.deploy([addr1.address], [10000]);

    FeeCalc = await facCalc.deploy([NFT1.address], [0,1,3,5,10], [700,600,500,400,300], false);

    Vault = await facVault.deploy("Basic Vault", 
                                  "ffBasic", 
                                  "ipfs://metadata",
                                  MockERC20.address,
                                  FeeMgr.address,
                                  FeeCalc.address,
                                  [MockStrat.address, MockStrat2.address, MockStrat3.address],
                                  [false, false, false],
                                  [2000, 5000, 3000],
                                  10000);
    await Vault.deployed();

  });

  it("Check that ERC20 tokens are minted to addresses", async function () {
    let balance1 = await MockERC20.balanceOf(addr2.address);
    expect(Number(balance1)).to.equal(
      Number(ethers.utils.parseEther("1000"))
    );

    let balance2 = await MockERC20.balanceOf(addr3.address);
    expect(Number(balance2)).to.equal(
      Number(ethers.utils.parseEther("2000"))
    );

    let balance3 = await MockERC20.balanceOf(addr4.address);
    expect(Number(balance3)).to.equal(
      Number(ethers.utils.parseEther("5000"))
    );
  });

  it("Check that NFT1 tokens are minted to addresses", async function () {
    let balance1 = await NFT1.balanceOf(addr2.address);
    expect(Number(balance1)).to.equal(
      3
    );

    let balance2 = await NFT1.balanceOf(addr3.address);
    expect(Number(balance2)).to.equal(
      10
    );
  });

  it("Check that ERC20 tokens can be deposited and withdrawn", async function () {
    // Approve vault
    await MockERC20.connect(addr2).approve(Vault.address, ethers.utils.parseEther("1000"));

    // Can't deposit while paused
    await expect(
      Vault.connect(addr2).deposit(ethers.utils.parseEther("1000"))
    ).to.be.revertedWith("FortiFi: Contract paused");

    // Unpause and deposit
    await Vault.connect(owner).flipPaused();
    await Vault.connect(addr2).deposit(ethers.utils.parseEther("1000"));

    let balance1 = await MockERC20.balanceOf(addr1.address);
    expect(Number(balance1)).to.equal(
      0
    );

    let balance1s = await MockERC20.balanceOf(MockStrat.address);
    expect(Number(balance1s)).to.equal(
      Number(ethers.utils.parseEther("200"))
    );

    let balance1s2 = await MockERC20.balanceOf(MockStrat2.address);
    expect(Number(balance1s2)).to.equal(
      Number(ethers.utils.parseEther("500"))
    );

    let balance1s3 = await MockERC20.balanceOf(MockStrat3.address);
    expect(Number(balance1s3)).to.equal(
      Number(ethers.utils.parseEther("300"))
    );

    let balance2 = await Vault.balanceOf(addr2.address, 1);
    expect(Number(balance2)).to.equal(
      Number(1)
    );

    // Don't allow 0 deposit or withdraw without token
    await expect(
      Vault.connect(addr2).deposit(0)
    ).to.be.revertedWith("FortiFi: Invalid deposit amount");

    await expect(
      Vault.connect(addr2).withdraw(2)
    ).to.be.revertedWith("FortiFi: Not the owner of token");

    // withdraw
    await Vault.connect(addr2).withdraw(1);

    let balance3 = await MockERC20.balanceOf(addr2.address);
    expect(Number(balance3)).to.equal(
      Number(ethers.utils.parseEther("1000"))
    );

    let balance3s = await MockERC20.balanceOf(MockStrat.address);
    expect(Number(balance3s)).to.equal(
      0
    );

    let balance3s2 = await MockERC20.balanceOf(MockStrat2.address);
    expect(Number(balance3s2)).to.equal(
      0
    );

    let balance3s3 = await MockERC20.balanceOf(MockStrat3.address);
    expect(Number(balance3s3)).to.equal(
      0
    );

    let balance4 = await Vault.balanceOf(addr2.address, 1);
    expect(Number(balance4)).to.equal(
      0
    );

  });

  it("Check that vault can handle profits and fees", async function () {
    // Approve vault
    await MockERC20.connect(addr2).approve(Vault.address, ethers.utils.parseEther("1000"));

    // Unpause and deposit
    await Vault.connect(owner).flipPaused();
    await Vault.connect(addr2).deposit(ethers.utils.parseEther("1000"));

    let balance1 = await MockERC20.balanceOf(addr1.address);
    expect(Number(balance1)).to.equal(
      0
    );

    let balance1s = await MockERC20.balanceOf(MockStrat.address);
    expect(Number(balance1s)).to.equal(
      Number(ethers.utils.parseEther("200"))
    );

    let balance1s2 = await MockERC20.balanceOf(MockStrat2.address);
    expect(Number(balance1s2)).to.equal(
      Number(ethers.utils.parseEther("500"))
    );

    let balance1s3 = await MockERC20.balanceOf(MockStrat3.address);
    expect(Number(balance1s3)).to.equal(
      Number(ethers.utils.parseEther("300"))
    );

    let balance2 = await Vault.balanceOf(addr2.address, 1);
    expect(Number(balance2)).to.equal(
      Number(1)
    );

    // Add yield to contract
    await MockERC20.mint(MockStrat.address, ethers.utils.parseEther("100"));

    // withdraw
    await Vault.connect(addr2).withdraw(1);

    let balance3 = await MockERC20.balanceOf(addr2.address);
    expect(Number(balance3)).to.equal(
      Number(ethers.utils.parseEther("1095")) // 100 (profit) * .95 = 95 + 1000 (original deposit) = 1095
    );

    let balance3f = await MockERC20.balanceOf(addr1.address);
    expect(Number(balance3f)).to.equal(
      Number(ethers.utils.parseEther("5")) // 100 * .05 = 5
    );

    let balance3s = await MockERC20.balanceOf(MockStrat.address);
    expect(Number(balance3s)).to.equal(
      0
    );

    let balance3s2 = await MockERC20.balanceOf(MockStrat2.address);
    expect(Number(balance3s2)).to.equal(
      0
    );

    let balance3s3 = await MockERC20.balanceOf(MockStrat3.address);
    expect(Number(balance3s3)).to.equal(
      0
    );

    let balance4 = await Vault.balanceOf(addr2.address, 1);
    expect(Number(balance4)).to.equal(
      0
    );

  });

});
