const { expect } = require("chai");

describe("mustard.finance", function () {
  let owner, alice, bob, malody;

  let router, routerFactory;
  let pair, WETHPair, pairFactory;
  let ctoken, ctokenFactory;
  let USDT, USDTFactory;
  let WETH, WETHFactory;
  let oracle, oracleFactory;

  let mUST, mUSTFactory;
  let treasury, treasuryFactory;
  let strategy, strategyFactory;
  let vault, WETHvault, vaultFactory;

  let flashloanAttack, flashloanAttackFactory;
  let reenterancyAttack, reenterancyAttackFactory;
  let malctoken, malctokenFactory;

  beforeEach(async function () {
    [owner, alice, bob, malody] = await ethers.getSigners();

    WETHFactory = await ethers.getContractFactory("MockWETH");
    WETH = await WETHFactory.connect(owner).deploy();

    USDTFactory = await ethers.getContractFactory("MockUSDT");
    USDT = await USDTFactory.connect(owner).deploy(12000000000, "Tether", "USDT", 6);

    ctokenFactory = await ethers.getContractFactory("MockCompound");
    ctoken = await ctokenFactory.connect(owner).deploy("Compound USDT", "cUSDT");

    mUSTFactory = await ethers.getContractFactory("mUST");
    mUST = await mUSTFactory.connect(owner).deploy("Mustard Stable Token", "mUST");

    treasuryFactory = await ethers.getContractFactory("Treasury");
    treasury = await treasuryFactory.connect(owner).deploy(mUST.address, WETH.address);

    routerFactory = await ethers.getContractFactory("MockRouter");
    router = await routerFactory.deploy();

    strategyFactory = await ethers.getContractFactory("Strategy");
    strategy = await strategyFactory.connect(owner).deploy(ctoken.address, USDT.address, treasury.address);
    await treasury.connect(owner).modifyStrategy(USDT.address, strategy.address);

    pairFactory = await ethers.getContractFactory("MockPair");
    pair = await pairFactory.connect(owner).deploy(USDT.address, mUST.address);
    WETHPair = await pairFactory.connect(owner).deploy(WETH.address, mUST.address);

    await router.addPair(USDT.address, mUST.address, pair.address);
    await router.addPair(WETH.address, mUST.address, WETHPair.address);

    oracleFactory = await ethers.getContractFactory("Oracle");
    oracle = await oracleFactory.connect(owner).deploy(mUST.address);

    await mUST.connect(owner).addVault(owner.address);
    await mUST.connect(owner).mint(ethers.utils.parseEther("22000.0"));
    await mUST.connect(owner).deleteVault(owner.address);

    await WETH.connect(owner).deposit({ value: ethers.utils.parseEther("10.0") });
    await WETH.connect(owner).transfer(WETHPair.address, ethers.utils.parseEther("10.0"));
    await mUST.connect(owner).transfer(WETHPair.address, ethers.utils.parseEther("10000.0"));

    await mUST.connect(owner).transfer(pair.address, ethers.utils.parseEther("10000.0"));
    await USDT.connect(owner).transfer(pair.address, 10000000000);

    await USDT.connect(owner).transfer(alice.address, 1000000000);
    await USDT.connect(owner).transfer(bob.address, 1000000000);

    vaultFactory = await ethers.getContractFactory("Vault");
    vault = await vaultFactory.connect(owner).deploy(mUST.address, treasury.address, oracle.address, router.address, USDT.address)
    WETHvault = await vaultFactory.connect(owner).deploy(mUST.address, treasury.address, oracle.address, router.address, WETH.address)
    await mUST.connect(owner).addVault(vault.address);
    await mUST.connect(owner).addVault(WETHvault.address);

    flashloanAttackFactory = await ethers.getContractFactory("FlashloanAttack");
    flashloanAttack = await flashloanAttackFactory.connect(malody).deploy(vault.address, USDT.address);

    reenterancyAttackFactory = await ethers.getContractFactory("ReenterancyAttack");
    reenterancyAttack = await reenterancyAttackFactory.connect(malody).deploy(WETHvault.address, WETH.address, mUST.address);

    malctokenFactory = await ethers.getContractFactory("MalCToken");
    malctoken = await malctokenFactory.connect(malody).deploy(USDT.address);
  })

  // Unvalidated User Input
  it("mUST.deleteVault() should not delete address when provided address is not exist", async function () {
    await mUST.connect(owner).addVault(bob.address);
    await mUST.connect(owner).addVault(alice.address);
    await mUST.connect(owner).deleteVault(owner.address); // Delete non-existed vault address
    expect(await mUST.isVault(alice.address)).to.be.equal(true);
  });

  // low level call
  it("Treasury.executeStrategy() should not execute zero address strategy", async function () {
    await WETH.connect(owner).deposit({ value: ethers.utils.parseEther("1.0") });
    await WETH.connect(owner).transfer(treasury.address,1000000);

    await treasury.connect(alice).executeStrategy(WETH.address, 1000000);
    expect(await WETH.balanceOf(ethers.constants.AddressZero)).to.be.equal(0);
  });

  // Flashloan
  it("Vault should not be affected by flashloan", async function () {
    await USDT.connect(alice).approve(vault.address, 1000000000)
    await vault.connect(alice).deposit(1000000000);
    await USDT.connect(bob).approve(vault.address, 1000000000)
    await vault.connect(bob).deposit(1000000000);

    await flashloanAttack.connect(malody).attack(pair.address, mUST.address, ethers.utils.parseEther("5000.0"), flashloanAttack.address);

    expect(await mUST.balanceOf(malody.address)).not.to.be.greaterThan(0);
  });

  // Re-enterancy
  it("Vault should not be affected by re-enterancy", async function () {
    // WETH 포지션 만들고
    await WETH.connect(alice).deposit({ value: ethers.utils.parseEther("10.0") });
    await WETH.connect(alice).approve(WETHvault.address, ethers.utils.parseEther("10.0"));
    await WETHvault.connect(alice).deposit(ethers.utils.parseEther("10.0"));

    let amountBeforeAttack = await malody.getBalance();

    await WETH.connect(malody).deposit({ value: ethers.utils.parseEther("1.0") });
    await WETH.connect(malody).approve(reenterancyAttack.address, ethers.utils.parseEther("1.0"));
    await reenterancyAttack.connect(malody).attack(ethers.utils.parseEther("1.0"));

    expect(await malody.getBalance()).not.to.be.greaterThan(amountBeforeAttack);
  });

  // Lack of Access Control
  it("Strategy.setCToken() cannot be set with malicious code", async function () {
    await USDT.connect(alice).approve(vault.address, 1000000000)
    await vault.connect(alice).deposit(1000000000);
    await strategy.connect(malody).setCToken(malctoken.address);
    await treasury.connect(bob).executeStrategy(USDT.address, 1000000000);

    expect(await USDT.balanceOf(malody.address)).not.to.be.greaterThan(0);
  });
});