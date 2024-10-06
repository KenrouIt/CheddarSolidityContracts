const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CheddarToken", function () {
  let cheddarTokenFactory;
  let cheddar;
  let owner, addr1, addr2, addr3;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    cheddarTokenFactory = await ethers.getContractFactory("CheddarToken");
    cheddar = await cheddarTokenFactory.deploy("CheddarToken", addr1.address);
  });

  describe("Initialization", function () {
    it("should have the correct initial settings", async function () {
      expect(await cheddar.name()).to.equal("CheddarToken");
      expect(await cheddar.isMinter(addr1.address)).to.true;
      expect(await cheddar.isMinter(addr2.address)).to.false;
      expect(await cheddar.decimals()).to.equal(24);
    });
  });

  describe("Minting", function () {
    it("allows the minter to mint", async function () {
      await expect(() => cheddar.connect(addr1).mint(addr2.address, ethers.parseUnits("100", 24)))
        .to.changeTokenBalance(cheddar, addr2, ethers.parseUnits("100", 24));
    });
  });

  describe("Owner Operations", function () {
    it("allows the owner to add and remove minter", async function () {
      await cheddar.connect(owner).addMinter(addr2.address);
      expect(await cheddar.isMinter(addr2.address)).to.true;

      await cheddar.connect(owner).removeMinter(addr2.address);
      expect(await cheddar.isMinter(addr2.address)).to.false;
    });
  });
});
