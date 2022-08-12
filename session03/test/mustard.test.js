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
  })

  it("Test Here!", async function () {
    await mUST.connect(owner).addVault(bob.address);
  });
});