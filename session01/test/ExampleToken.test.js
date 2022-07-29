const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("ExampleToken", function () {
  let alice, bob;
  let token, tokenFactory;

  beforeEach(async function () {
    [alice, bob] = await ethers.getSigners();
    tokenFactory = await ethers.getContractFactory("ExampleToken");
    token = await tokenFactory.connect(alice).deploy("A Token", "ATT");
  })

  it("constructor() should assign the total supply of tokens to the deployer", async function () {
    deployerBalance = await token.balanceOf(alice.address);
    expect(await token.totalSupply()).to.equal(deployerBalance);
  });
  it("transfer() should revert when balance is smaller than transfer amount", async function () {
    expect(token.connect(bob).transfer(alice.address, 100)).to.be.reverted;
  });
  it("mint() should emit Transfer event", async function () {
    expect(await token.connect(alice).mint(100)).to.emit(token, 'Transfer').withArgs(ethers.constants.AddressZero, alice.address, 100);
  });
  it("transfer() should return true when transfer done without revert", async function () {
    let ret = await token.connect(alice).callStatic.transfer(bob.address, 100);
    expect(ret).to.be.equal(true);
  });
  it("approve() should change allowance", async function () {
    await token.connect(bob).approve(alice.address, 100);
    expect(await token.allowance(bob.address, alice.address)).to.be.equal(100);
  });
  it("transferFrom() should fail when allowance is smaller than transfer amount", async function () {
    expect(token.connect(bob).transferFrom(alice.address, bob.address, 100)).to.be.reverted;
  });
  it("transferFrom() should return true when transfer done without revert", async function () {
    await token.connect(alice).approve(bob.address, 100);
    let ret = await token.connect(bob).callStatic.transferFrom(alice.address, bob.address, 100);
    expect(ret).to.be.equal(true);
  });
  it("burn() should emit Transfer event", async function () {
    expect(await token.connect(alice).burn(100)).to.emit(token, 'Transfer').withArgs(alice.address, ethers.constants.AddressZero, 100);
  });
});