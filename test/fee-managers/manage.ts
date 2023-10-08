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

describe("Fee Manager Tests", function () {
  let owner: SignerWithAddress,
    addr1: SignerWithAddress,
    addr2: SignerWithAddress,
    addr3: SignerWithAddress,
    Mgr: Contract,
    ERC20: Contract;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    const [facMockERC20] = await Promise.all([
      ethers.getContractFactory("contracts/mock/MockERC20.sol:MockERC20"),
    ]);

    ERC20 = await facMockERC20.deploy();

    await ERC20.waitForDeployment();

    await ERC20.mint(owner.getAddress(), ethers.parseEther("10000"));

  });

  it("Check that ERC20 tokens are minted to addresses", async function () {
    let balance1 = await ERC20.balanceOf(owner.getAddress());
    expect(Number(balance1)).to.equal(
      Number(ethers.parseEther("10000"))
    );
  });

  it("Check fee disbursement when only using 1 receiver", async function () {
    const [facMgr] = await Promise.all([
      ethers.getContractFactory("contracts/fee-managers/FortiFiFeeManager.sol:FortiFiFeeManager"),
    ]);

    Mgr = await facMgr.deploy([addr1.getAddress()], [10000]);

    await ERC20.connect(owner).approve(Mgr.getAddress(), ethers.parseEther("10000"));

    await Mgr.connect(owner).collectFees(ERC20.getAddress(), 500);

    let balance1 = await ERC20.balanceOf(Mgr.getAddress());
    expect(Number(balance1)).to.equal(
      500 
    );

    let ownerBalance = Number(ethers.parseEther("10000")) - 500;

    let balance2 = await ERC20.balanceOf(owner.getAddress());
    expect(Number(balance2)).to.equal(
      (ownerBalance)
    );

    await Mgr.connect(owner).collectFees(ERC20.getAddress(), 500);

    let balance3 = await ERC20.balanceOf(Mgr.getAddress());
    expect(Number(balance3)).to.equal(
      0
    );

    let balance4 = await ERC20.balanceOf(owner.getAddress());
    expect(Number(balance4)).to.equal(
      (ownerBalance - 500) 
    );

    let balance5 = await ERC20.balanceOf(addr1.getAddress());
    expect(Number(balance5)).to.equal(
      1000
    );

  });

  it("Check fee disbursement when only using multiple receivers", async function () {
    const [facMgr] = await Promise.all([
      ethers.getContractFactory("contracts/fee-managers/FortiFiFeeManager.sol:FortiFiFeeManager"),
    ]);

    Mgr = await facMgr.deploy([addr1.getAddress(), addr2.getAddress(), addr3.getAddress()], [2500, 2500, 5000]);

    await ERC20.connect(owner).approve(Mgr.getAddress(), ethers.parseEther("10000"));

    await Mgr.connect(owner).collectFees(ERC20.getAddress(), 500);

    let balance1 = await ERC20.balanceOf(Mgr.getAddress());
    expect(Number(balance1)).to.equal(
      500 
    );

    let ownerBalance = Number(ethers.parseEther("10000")) - 500;

    let balance2 = await ERC20.balanceOf(owner.getAddress());
    expect(Number(balance2)).to.equal(
      (ownerBalance)
    );

    await Mgr.connect(owner).collectFees(ERC20.getAddress(), 500);

    let balance3 = await ERC20.balanceOf(Mgr.getAddress());
    expect(Number(balance3)).to.equal(
      0
    );

    let balance4 = await ERC20.balanceOf(owner.getAddress());
    expect(Number(balance4)).to.equal(
      (ownerBalance - 500) 
    );

    let balance5 = await ERC20.balanceOf(addr1.getAddress());
    expect(Number(balance5)).to.equal(
      250
    );

    let balance6 = await ERC20.balanceOf(addr2.getAddress());
    expect(Number(balance6)).to.equal(
      250
    );

    let balance7 = await ERC20.balanceOf(addr3.getAddress());
    expect(Number(balance7)).to.equal(
      500
    );

  });

  it("Check that invalid configurations revert", async function () {
    const [facMgr] = await Promise.all([
      ethers.getContractFactory("contracts/fee-managers/FortiFiFeeManager.sol:FortiFiFeeManager"),
    ]);

    await expect(
      facMgr.deploy([], [2500, 2500, 5000])
    ).to.be.revertedWith(`InvalidArrayLength`);

    await expect(
      facMgr.deploy([NULL_ADDRESS], [2500, 2500, 5000])
    ).to.be.revertedWith(`ZeroAddress`);

    await expect(
      facMgr.deploy([addr1.getAddress()], [2500, 2500, 5000])
    ).to.be.revertedWith(`InvalidArrayLength`);

    await expect(
      facMgr.deploy([addr1.getAddress()], [0])
    ).to.be.revertedWith(`InvalidBps`);

    await expect(
      facMgr.deploy([addr1.getAddress()], [5000])
    ).to.be.revertedWith(`InvalidBps`);

  });

});
