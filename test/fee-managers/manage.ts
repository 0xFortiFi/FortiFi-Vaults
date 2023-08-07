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

    await ERC20.deployed();

    await ERC20.mint(owner.address, ethers.utils.parseEther("10000"));

  });

  it("Check that ERC20 tokens are minted to addresses", async function () {
    let balance1 = await ERC20.balanceOf(owner.address);
    expect(Number(balance1)).to.equal(
      Number(ethers.utils.parseEther("10000"))
    );
  });

  it("Check fee disbursement when only using 1 receiver", async function () {
    const [facMgr] = await Promise.all([
      ethers.getContractFactory("contracts/fee-managers/FortiFiFeeManager.sol:FortiFiFeeManager"),
    ]);

    Mgr = await facMgr.deploy([addr1.address], [10000]);

    await ERC20.connect(owner).approve(Mgr.address, ethers.utils.parseEther("10000"));

    await Mgr.connect(owner).collectFees(ERC20.address, 500);

    let balance1 = await ERC20.balanceOf(Mgr.address);
    expect(Number(balance1)).to.equal(
      500 
    );

    let ownerBalance = Number(ethers.utils.parseEther("10000")) - 500;

    let balance2 = await ERC20.balanceOf(owner.address);
    expect(Number(balance2)).to.equal(
      (ownerBalance)
    );

    await Mgr.connect(owner).collectFees(ERC20.address, 500);

    let balance3 = await ERC20.balanceOf(Mgr.address);
    expect(Number(balance3)).to.equal(
      0
    );

    let balance4 = await ERC20.balanceOf(owner.address);
    expect(Number(balance4)).to.equal(
      (ownerBalance - 500) 
    );

    let balance5 = await ERC20.balanceOf(addr1.address);
    expect(Number(balance5)).to.equal(
      1000
    );

  });

  it("Check fee disbursement when only using multiple receivers", async function () {
    const [facMgr] = await Promise.all([
      ethers.getContractFactory("contracts/fee-managers/FortiFiFeeManager.sol:FortiFiFeeManager"),
    ]);

    Mgr = await facMgr.deploy([addr1.address, addr2.address, addr3.address], [2500, 2500, 5000]);

    await ERC20.connect(owner).approve(Mgr.address, ethers.utils.parseEther("10000"));

    await Mgr.connect(owner).collectFees(ERC20.address, 500);

    let balance1 = await ERC20.balanceOf(Mgr.address);
    expect(Number(balance1)).to.equal(
      500 
    );

    let ownerBalance = Number(ethers.utils.parseEther("10000")) - 500;

    let balance2 = await ERC20.balanceOf(owner.address);
    expect(Number(balance2)).to.equal(
      (ownerBalance)
    );

    await Mgr.connect(owner).collectFees(ERC20.address, 500);

    let balance3 = await ERC20.balanceOf(Mgr.address);
    expect(Number(balance3)).to.equal(
      0
    );

    let balance4 = await ERC20.balanceOf(owner.address);
    expect(Number(balance4)).to.equal(
      (ownerBalance - 500) 
    );

    let balance5 = await ERC20.balanceOf(addr1.address);
    expect(Number(balance5)).to.equal(
      250
    );

    let balance6 = await ERC20.balanceOf(addr2.address);
    expect(Number(balance6)).to.equal(
      250
    );

    let balance7 = await ERC20.balanceOf(addr3.address);
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
    ).to.be.revertedWith("FortiFi: Invalid receiver array");

    await expect(
      facMgr.deploy([NULL_ADDRESS], [2500, 2500, 5000])
    ).to.be.revertedWith("FortiFi: Invalid receiver address");

    await expect(
      facMgr.deploy([addr1.address], [2500, 2500, 5000])
    ).to.be.revertedWith("FortiFi: Invalid array lengths");

    await expect(
      facMgr.deploy([addr1.address], [0])
    ).to.be.revertedWith("FortiFi: Invalid bps amount");

    await expect(
      facMgr.deploy([addr1.address], [5000])
    ).to.be.revertedWith("FortiFi: Invalid total bps");

  });

});
