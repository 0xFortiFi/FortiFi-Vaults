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

describe("Vector Strategy Tests", function () {
  let owner: SignerWithAddress,
    addr1: SignerWithAddress,
    addr2: SignerWithAddress,
    addr3: SignerWithAddress,
    MockERC20: Contract,
    MockStrat: Contract,
    Strat: Contract;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    const [facMockERC20, facMockStrat, facStrat] = await Promise.all([
      ethers.getContractFactory("contracts/mock/MockERC20.sol:MockERC20"),
      ethers.getContractFactory("contracts//mock/MockVectorStrat.sol:MockVectorStrat"),
      ethers.getContractFactory("contracts/strategies/FortiFiVectorStrategy.sol:FortiFiVectorStrategy"),
    ]);

    MockERC20 = await facMockERC20.deploy();
    await MockERC20.deployed();

    await MockERC20.mint(addr1.address, ethers.utils.parseEther("1000"));
    await MockERC20.mint(addr2.address, ethers.utils.parseEther("2000"));
    await MockERC20.mint(addr3.address, ethers.utils.parseEther("5000"));

    MockStrat = await facMockStrat.deploy(MockERC20.address);
    await MockStrat.deployed();

    Strat = await facStrat.deploy(MockStrat.address, MockERC20.address, 100);
    await Strat.deployed();

  });

  it("Check that ERC20 tokens are minted to addresses", async function () {
    let balance1 = await MockERC20.balanceOf(addr1.address);
    expect(Number(balance1)).to.equal(
      Number(ethers.utils.parseEther("1000"))
    );
  });

  it("Check that ERC20 tokens can be deposited and withdrawn", async function () {
    // Approve strategy and deposit
    await MockERC20.connect(addr1).approve(Strat.address, ethers.utils.parseEther("1000"));
    await Strat.connect(addr1).deposit(ethers.utils.parseEther("1000"));

    let balance1 = await MockERC20.balanceOf(addr1.address);
    expect(Number(balance1)).to.equal(
      0
    );

    let balance1s = await MockERC20.balanceOf(MockStrat.address);
    expect(Number(balance1s)).to.equal(
      Number(ethers.utils.parseEther("1000"))
    );

    let balance2 = await MockStrat.balanceOf(addr1.address);
    expect(Number(balance2)).to.equal(
      Number(ethers.utils.parseEther("900"))
    );

    // Don't allow 0 deposit or withdraw
    await expect(
      Strat.connect(addr1).deposit(0)
    ).to.be.revertedWith("FortiFi: Must deposit more than 0");

    await expect(
      Strat.connect(addr1).withdraw(0)
    ).to.be.revertedWith("FortiFi: Must withdraw more than 0");

    // Approve receipt token and withdraw
    await MockStrat.connect(addr1).approve(Strat.address, ethers.utils.parseEther("900"));
    await Strat.connect(addr1).withdraw(ethers.utils.parseEther("900"));

    let balance3 = await MockERC20.balanceOf(addr1.address);
    expect(Number(balance3)).to.equal(
      Number(ethers.utils.parseEther("1000"))
    );

    let balance3s = await MockERC20.balanceOf(MockStrat.address);
    expect(Number(balance3s)).to.equal(
      0
    );

    let balance4 = await MockStrat.balanceOf(addr1.address);
    expect(Number(balance4)).to.equal(
      0
    );

  });

});
