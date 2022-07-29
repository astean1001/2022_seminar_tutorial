const { expect } = require("chai");

describe("SimpleSwap", function () {
  let tokenA, tokenB, tokenM, simpleSwap;
  let alice, bob, mallory;
  beforeEach(async function () {
    [alice, bob, mallory] = await ethers.getSigners();
    tokenFactory = await ethers.getContractFactory("ExampleToken");
    malTokenFactory = await ethers.getContractFactory("MalToken");
    swapFactory = await ethers.getContractFactory("SimpleSwap");
    tokenA = await tokenFactory.connect(alice).deploy("A Token", "ATT");
    tokenB = await tokenFactory.connect(bob).deploy("B Token", "BTT");
    tokenM = await malTokenFactory.connect(mallory).deploy("Mal Token", "MTT");
    simpleSwap = await swapFactory.connect(bob).deploy(tokenA.address, alice.address, 100, tokenB.address, bob.address, 20);
  })
  it("swap() should revert if caller is not owner1 and owner2", async function () {
    expect(simpleSwap.connect(mallory).swap()).to.be.revertedWith("Not authorized")
  });
  it("swap() should revert when owner1 allowance is smaller than swap amount", async function () {
    expect(simpleSwap.connect(alice).swap()).to.be.revertedWith("Token 1 allowance too low")
  });
  it("swap() should revert when owner2 balance is smaller than swap amount", async function () {
    await tokenA.connect(alice).approve(simpleSwap.address, 100);
    await tokenB.connect(bob).approve(simpleSwap.address, 20);
    await tokenB.connect(bob).burn(await tokenB.totalSupply());
    expect(simpleSwap.connect(alice).swap()).to.be.reverted;
  });
  it("swap() should revert if tokenA is not ERC20", async function () {
    simpleSwap = await swapFactory.connect(bob).deploy(mallory.address, alice.address, 100, tokenB.address, bob.address, 20);
    await tokenA.connect(alice).approve(simpleSwap.address, 100);
    await tokenB.connect(bob).approve(simpleSwap.address, 20);
    expect(simpleSwap.connect(alice).swap()).to.be.reverted;
  });
  it("swap() should tranfer swap amount to each owners", async function () {
    await tokenA.connect(alice).approve(simpleSwap.address, 100);
    await tokenB.connect(bob).approve(simpleSwap.address, 20);
    await simpleSwap.connect(alice).swap();
    expect(await tokenB.balanceOf(alice.address)).to.be.equal(20);
    expect(await tokenA.balanceOf(bob.address)).to.be.equal(100);
  });
  it("swap() might not work properly if token is malicious", async function () {
    simpleSwap = await swapFactory.connect(bob).deploy(tokenM.address, mallory.address, 10, tokenB.address, bob.address, 100000);
    await tokenM.connect(mallory).approve(simpleSwap.address, 10);
    await tokenB.connect(bob).approve(simpleSwap.address, 100000);
    await simpleSwap.connect(mallory).swap();
    expect(await tokenB.balanceOf(mallory.address)).to.be.equal(100000);
    expect(await tokenM.balanceOf(bob.address)).to.be.equal(0);
  });
});