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

describe("Base Test Setup", function () {
  let owner: SignerWithAddress,
    addr1: SignerWithAddress,
    addr2: SignerWithAddress,
    addr3: SignerWithAddress,
    MockERC20: Contract,
    MockERC721: Contract;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    const [facMockERC20, facMockERC721] = await Promise.all([
      ethers.getContractFactory("contracts/mock/MockERC20.sol:MockERC20"),
      ethers.getContractFactory("contracts/mock/MockERC721.sol:MockERC721"),
    ]);

    MockERC20 = await facMockERC20.deploy();

    await MockERC20.waitForDeployment();

    await MockERC20.mint(addr1.getAddress(), ethers.utils.parseEther("1000"));
    await MockERC20.mint(addr2.getAddress(), ethers.utils.parseEther("2000"));
    await MockERC20.mint(addr3.getAddress(), ethers.utils.parseEther("5000"));

    MockERC721 = await facMockERC721.deploy();

    await MockERC721.waitForDeployment();

    await MockERC721.mint(addr1.getAddress(), 1);
    await MockERC721.mint(addr2.getAddress(), 5);
    await MockERC721.mint(addr3.getAddress(), 10);

  });

  it("Check that ERC20 tokens are minted to addresses", async function () {
    let balance1 = await MockERC20.balanceOf(addr1.getAddress());
    expect(Number(balance1)).to.equal(
      Number(ethers.utils.parseEther("1000"))
    );

    let balance2 = await MockERC20.balanceOf(addr2.getAddress());
    expect(Number(balance2)).to.equal(
      Number(ethers.utils.parseEther("2000"))
    );

    let balance3 = await MockERC20.balanceOf(addr3.getAddress());
    expect(Number(balance3)).to.equal(
      Number(ethers.utils.parseEther("5000"))
    );
  });

  it("Check that ERC721 tokens are minted to addresses", async function () {
    let balance1 = await MockERC721.balanceOf(addr1.getAddress());
    expect(Number(balance1)).to.equal(
      1
    );

    let balance2 = await MockERC721.balanceOf(addr2.getAddress());
    expect(Number(balance2)).to.equal(
      5
    );

    let balance3 = await MockERC721.balanceOf(addr3.getAddress());
    expect(Number(balance3)).to.equal(
      10
    );
  });

});
