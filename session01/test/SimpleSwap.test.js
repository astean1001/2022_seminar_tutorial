const { expect } = require("chai");

describe("SimpleSwap", function () {
  let tokenA, tokenB, tokenSwap;
  let alice, bob, mallory;
  beforeEach(async function () {})
  it("swap() should revert if caller is not owner1 and owner2", async function () { });
  it("swap() should revert when owner1 allowance is smaller than swap amount", async function () { });
  it("swap() should revert when owner2 balance is smaller than swap amount", async function () { });
  it("swap() should revert if tokenA is not ERC20", async function () { });
  it("swap() should tranfer swap amount to each owners", async function () { });
  it("swap() might not work properly if token is malicious", async function () { });
});