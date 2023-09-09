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

describe("Basic Strategy Tests", function () {
  let owner: SignerWithAddress,
    addr1: SignerWithAddress,
    addr2: SignerWithAddress,
    addr3: SignerWithAddress,
    MockERC20: Contract,
    MockStrat: Contract,
    Strategy: Contract;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    const [facMockERC20, facMockStrat, facStrategy] = await Promise.all([
      ethers.getContractFactory("contracts/mock/MockERC20.sol:MockERC20"),
      ethers.getContractFactory("contracts//mock/MockBasicStrat.sol:MockBasicStrat"),
      ethers.getContractFactory("contracts/strategies/FortiFiStrategy.sol:FortiFiStrategy"),
    ]);

    MockERC20 = await facMockERC20.deploy();
    await MockERC20.waitForDeployment();

    await MockERC20.mint(addr1.getAddress(), ethers.parseEther("1000"));
    await MockERC20.mint(addr2.getAddress(), ethers.parseEther("2000"));
    await MockERC20.mint(addr3.getAddress(), ethers.parseEther("5000"));

    MockStrat = await facMockStrat.deploy(MockERC20.getAddress());
    await MockStrat.waitForDeployment();

    Strategy = await facStrategy.deploy(MockStrat.getAddress(), MockERC20.getAddress());
    await Strategy.waitForDeployment();

  });

  it("Check that ERC20 tokens are minted to addresses", async function () {
    let balance1 = await MockERC20.balanceOf(addr1.getAddress());
    expect(Number(balance1)).to.equal(
      Number(ethers.parseEther("1000"))
    );
  });

  it("Check that ERC20 tokens can be deposited and withdrawn", async function () {
    // Approve strategy and deposit
    await MockERC20.connect(addr1).approve(Strategy.getAddress(), ethers.parseEther("1000"));
    await Strategy.connect(addr1).deposit(ethers.parseEther("1000"), addr1.getAddress());

    let balance1 = await MockERC20.balanceOf(addr1.getAddress());
    expect(Number(balance1)).to.equal(
      0
    );

    let balance1s = await MockERC20.balanceOf(MockStrat.getAddress());
    expect(Number(balance1s)).to.equal(
      Number(ethers.parseEther("1000"))
    );

    let balance2 = await Strategy.balanceOf(addr1.getAddress());
    expect(Number(balance2)).to.equal(
      Number(ethers.parseEther("1000"))
    );

    // Don't allow 0 deposit or withdraw
    await expect(
      Strategy.connect(addr1).deposit(0, addr1.getAddress())
    ).to.be.revertedWith("FortiFi: 0 deposit");

    await expect(
      Strategy.connect(addr1).withdraw(0, addr1.getAddress())
    ).to.be.revertedWith("FortiFi: 0 withdraw");

    // Approve receipt token and withdraw
    await MockStrat.connect(addr1).approve(Strategy.getAddress(), ethers.parseEther("1000"));
    await Strategy.connect(addr1).withdraw(ethers.parseEther("1000"), addr1.getAddress());

    let balance3 = await MockERC20.balanceOf(addr1.getAddress());
    expect(Number(balance3)).to.equal(
      Number(ethers.parseEther("1000"))
    );

    let balance3s = await MockERC20.balanceOf(MockStrat.getAddress());
    expect(Number(balance3s)).to.equal(
      0
    );

    let balance4 = await MockStrat.balanceOf(addr1.getAddress());
    expect(Number(balance4)).to.equal(
      0
    );

  });

  it("Check that withdrawal works when there is yield", async function () {
    // Approve strategy and deposit
    await MockERC20.connect(addr1).approve(Strategy.getAddress(), ethers.parseEther("1000"));
    await Strategy.connect(addr1).deposit(ethers.parseEther("1000"), addr1.getAddress());

    let balance1 = await MockERC20.balanceOf(addr1.getAddress());
    expect(Number(balance1)).to.equal(
      0
    );

    let balance1s = await MockERC20.balanceOf(MockStrat.getAddress());
    expect(Number(balance1s)).to.equal(
      Number(ethers.parseEther("1000"))
    );

    let balance2 = await Strategy.balanceOf(addr1.getAddress());
    expect(Number(balance2)).to.equal(
      Number(ethers.parseEther("1000"))
    );

    // Add yield to contract
    await MockERC20.mint(MockStrat.getAddress(), ethers.parseEther("100"));

    // Approve receipt token and withdraw
    await MockStrat.connect(addr1).approve(Strategy.getAddress(), ethers.parseEther("1000"));
    await Strategy.connect(addr1).withdraw(ethers.parseEther("1000"), addr1.getAddress());

    let balance3 = await MockERC20.balanceOf(addr1.getAddress());
    expect(Number(balance3)).to.equal(
      Number(ethers.parseEther("1100"))
    );

    let balance3s = await MockERC20.balanceOf(MockStrat.getAddress());
    expect(Number(balance3s)).to.equal(
      0
    );

    let balance4 = await MockStrat.balanceOf(addr1.getAddress());
    expect(Number(balance4)).to.equal(
      0
    );

  });

});
