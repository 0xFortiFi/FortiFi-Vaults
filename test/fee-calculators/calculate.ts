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

describe("Fee Calculator Tests", function () {
  let owner: SignerWithAddress,
    addr1: SignerWithAddress,
    addr2: SignerWithAddress,
    addr3: SignerWithAddress,
    Calc: Contract,
    NFT1: Contract,
    NFT2: Contract,
    NFT3: Contract;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    const [facMockERC721] = await Promise.all([
      ethers.getContractFactory("contracts/mock/MockERC721.sol:MockERC721"),
    ]);

    NFT1 = await facMockERC721.deploy();

    await NFT1.waitForDeployment();

    await NFT1.mint(addr1.getAddress(), 3);
    await NFT1.mint(addr2.getAddress(), 10);

    NFT2 = await facMockERC721.deploy();

    await NFT2.waitForDeployment();

    await NFT2.mint(addr1.getAddress(), 10);
    await NFT2.mint(addr3.getAddress(), 3);

    NFT3 = await facMockERC721.deploy();

    await NFT3.waitForDeployment();

    await NFT3.mint(addr1.getAddress(), 3);
    await NFT3.mint(addr3.getAddress(), 3);

  });

  it("Check that NFT1 tokens are minted to addresses", async function () {
    let balance1 = await NFT1.balanceOf(addr1.getAddress());
    expect(Number(balance1)).to.equal(
      3
    );

    let balance2 = await NFT1.balanceOf(addr2.getAddress());
    expect(Number(balance2)).to.equal(
      10
    );

    let balance3 = await NFT1.balanceOf(addr3.getAddress());
    expect(Number(balance3)).to.equal(
      0
    );
  });

  it("Check that NFT2 tokens are minted to addresses", async function () {
    let balance1 = await NFT2.balanceOf(addr1.getAddress());
    expect(Number(balance1)).to.equal(
      10
    );

    let balance2 = await NFT2.balanceOf(addr2.getAddress());
    expect(Number(balance2)).to.equal(
      0
    );

    let balance3 = await NFT2.balanceOf(addr3.getAddress());
    expect(Number(balance3)).to.equal(
      3
    );
  });

  it("Check that NFT3 tokens are minted to addresses", async function () {
    let balance1 = await NFT3.balanceOf(addr1.getAddress());
    expect(Number(balance1)).to.equal(
      3
    );

    let balance2 = await NFT3.balanceOf(addr2.getAddress());
    expect(Number(balance2)).to.equal(
      0
    );

    let balance3 = await NFT3.balanceOf(addr3.getAddress());
    expect(Number(balance3)).to.equal(
      3
    );
  });

  it("Check fees when only using 1 collection", async function () {
    const [facCalc] = await Promise.all([
      ethers.getContractFactory("contracts/fee-calculators/FortiFiFeeCalculator.sol:FortiFiFeeCalculator"),
    ]);

    Calc = await facCalc.deploy([NFT1.getAddress()], [0,1,3,5,10], [700,600,500,400,300], false);

    let fee1 = await Calc.getFees(addr1.getAddress(), 10000);
    expect(Number(fee1)).to.equal(
      500 
    );

    let fee2 = await Calc.getFees(addr2.getAddress(), 10000);
    expect(Number(fee2)).to.equal(
      300
    );

    let fee3 = await Calc.getFees(addr3.getAddress(), 10000);
    expect(Number(fee3)).to.equal(
      700
    );

    // Amounts that are too small have 0 fees
    let fee4 = await Calc.getFees(addr1.getAddress(), 10);
    expect(Number(fee4)).to.equal(
      0
    );
  });

  it("Check fees when using multiple collections uncombined", async function () {
    const [facCalc] = await Promise.all([
      ethers.getContractFactory("contracts/fee-calculators/FortiFiFeeCalculator.sol:FortiFiFeeCalculator"),
    ]);

    Calc = await facCalc.deploy([NFT1.getAddress(), NFT2.getAddress(), NFT3.getAddress()], [0,1,3,5,10], [700,600,500,400,300], false);

    let fee1 = await Calc.getFees(addr1.getAddress(), 10000);
    expect(Number(fee1)).to.equal(
      300 
    );

    let fee2 = await Calc.getFees(addr2.getAddress(), 10000);
    expect(Number(fee2)).to.equal(
      300
    );

    let fee3 = await Calc.getFees(addr3.getAddress(), 10000);
    expect(Number(fee3)).to.equal(
      500
    );

    // Amounts that are too small have 0 fees
    let fee4 = await Calc.getFees(addr1.getAddress(), 10);
    expect(Number(fee4)).to.equal(
      0
    );
  });

  it("Check fees when using multiple collections combined", async function () {
    const [facCalc] = await Promise.all([
      ethers.getContractFactory("contracts/fee-calculators/FortiFiFeeCalculator.sol:FortiFiFeeCalculator"),
    ]);

    Calc = await facCalc.deploy([NFT1.getAddress(), NFT2.getAddress(), NFT3.getAddress()], [0,1,3,5,10], [700,600,500,400,300], true);

    let fee1 = await Calc.getFees(addr1.getAddress(), 10000);
    expect(Number(fee1)).to.equal(
      300 
    );

    let fee2 = await Calc.getFees(addr2.getAddress(), 10000);
    expect(Number(fee2)).to.equal(
      300
    );

    let fee3 = await Calc.getFees(addr3.getAddress(), 10000);
    expect(Number(fee3)).to.equal(
      400
    );

    // Amounts that are too small have 0 fees
    let fee4 = await Calc.getFees(addr1.getAddress(), 10);
    expect(Number(fee4)).to.equal(
      0
    );
  });

  it("Check that invalid configurations revert", async function () {
    const [facCalc] = await Promise.all([
      ethers.getContractFactory("contracts/fee-calculators/FortiFiFeeCalculator.sol:FortiFiFeeCalculator"),
    ]);

    await expect(
      facCalc.deploy([], [0,1,3,5,10], [700,600,500,400,300], true)
    ).to.be.revertedWith(`InvalidArrayLength`);

    await expect(
      facCalc.deploy([NULL_ADDRESS], [0,1,3,5,10], [700,600,500,400,300], true)
    ).to.be.revertedWith(`ZeroAddress`);

    await expect(
      facCalc.deploy([NFT1.getAddress()], [], [700,600,500,400,300], true)
    ).to.be.revertedWith(`InvalidArrayLength`);

    await expect(
      facCalc.deploy([NFT1.getAddress()], [], [], true)
    ).to.be.revertedWith(`InvalidAmounts`);

    await expect(
      facCalc.deploy([NFT1.getAddress()], [1,3,5,10], [600,500,400,300], true)
    ).to.be.revertedWith(`InvalidAmounts`);

    await expect(
      facCalc.deploy([NFT1.getAddress()], [0,1,3,5,10], [700,800,500,400,300], true)
    ).to.be.revertedWith(`InvalidBps`);
  });

});
