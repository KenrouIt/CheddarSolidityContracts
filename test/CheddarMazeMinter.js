const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CheddarMazeMinter", function () {
    let cheddarTokenFactory;
    let cheddarTokenContract;
    let cheddarMazeMinterFactory
    let cheddarMazeMinterContract;
    let owner, addr1, addr2, addr3, addr4;
    let DAY_IN_SECONDS = 86400;
    const zeroAddress = "0x0000000000000000000000000000000000000000"


    beforeEach(async function () {
        [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
        cheddarTokenFactory = await ethers.getContractFactory("CheddarToken");
        cheddarTokenContract = await cheddarTokenFactory.deploy("CheddarToken", addr1.address);
        
        cheddarMazeMinterFactory = await ethers.getContractFactory("CheddarMazeMinter");
        cheddarMazeMinterContract = await cheddarMazeMinterFactory.deploy(cheddarTokenContract.target, addr2.address);

        await cheddarTokenContract.connect(owner).addMinter(cheddarMazeMinterContract.target);
    });

    describe("Initialization", function () {
        it("should have the correct initial settings", async function () {
            expect(await cheddarMazeMinterContract.owner()).to.equal(owner.address);
            expect(await cheddarMazeMinterContract.minter()).to.equal(addr2.address);
            expect(await cheddarMazeMinterContract.cheddarToken()).to.equal(cheddarTokenContract.target);
            expect(await cheddarMazeMinterContract.active()).to.true;
            expect(await cheddarMazeMinterContract.dailyQuota()).to.equal(ethers.parseUnits("10000", 24));
            expect(await cheddarMazeMinterContract.userQuota()).to.equal(ethers.parseUnits("555", 24));
            expect(await cheddarMazeMinterContract.todayMinted()).to.equal(0);
            expect(await cheddarMazeMinterContract.currentDay()).to.equal(Math.floor(Date.now() / (DAY_IN_SECONDS * 1000)));
        });
    });

    describe("Minting", function () {
        it("allows the minter to mint within the quota", async function () {
            await expect(() => cheddarMazeMinterContract.connect(addr2).mint(addr3.address, ethers.parseUnits("100", 24), zeroAddress))
                .to.changeTokenBalance(cheddarTokenContract, addr3, ethers.parseUnits("100", 24));
        });

        it("resets the daily quota after a day", async function () {
            await cheddarMazeMinterContract.connect(addr2).mint(addr3.address, ethers.parseUnits("555", 24), "0x0000000000000000000000000000000000000000");
            const transactionReceipt = await cheddarMazeMinterContract.getTodayMinted()
            expect(transactionReceipt).to.equal(ethers.parseUnits("555", 24));
            await network.provider.send("evm_increaseTime", [DAY_IN_SECONDS]);
            await network.provider.send("evm_mine");
            expect(await cheddarMazeMinterContract.getTodayMinted()).to.equal(ethers.parseUnits("0", 24));

            await expect(() => cheddarMazeMinterContract.connect(addr2).mint(addr3.address, ethers.parseUnits("100", 24), "0x0000000000000000000000000000000000000000"))
                .to.changeTokenBalance(cheddarTokenContract, addr3, ethers.parseUnits("100", 24));
            expect(await cheddarMazeMinterContract.getTodayMinted()).to.equal(ethers.parseUnits("100", 24));
        });

        it("handles referral bonus correctly", async function () {
            await cheddarMazeMinterContract.connect(addr2).mint(addr3.address, ethers.parseUnits("100", 24), addr4.address);
            expect(await cheddarTokenContract.balanceOf(addr3.address)).to.equal(ethers.parseUnits("95", 24));
            expect(await cheddarTokenContract.balanceOf(addr4.address)).to.equal(ethers.parseUnits("5", 24)); // 5% referral bonus
        });
    });

    describe("Owner Operations", function () {
        it("allows the owner to deactivate and reactivate the contract", async function () {
            await cheddarMazeMinterContract.connect(owner).toggleActive();
            expect(await cheddarMazeMinterContract.active()).to.be.false;
            await cheddarMazeMinterContract.connect(owner).toggleActive();
            expect(await cheddarMazeMinterContract.active()).to.be.true;
        });

        it("allows the owner to change the minter", async function () {
            await cheddarMazeMinterContract.connect(owner).setMinter(addr3.address);
            expect(await cheddarMazeMinterContract.minter()).to.equal(addr3.address);
        });

        it("allows the owner to adjust quotas", async function () {
            await cheddarMazeMinterContract.connect(owner).setDailyQuota(ethers.parseUnits("1000", 24));
            expect(await cheddarMazeMinterContract.dailyQuota()).to.equal(ethers.parseUnits("1000", 24));
            await cheddarMazeMinterContract.connect(owner).setUserQuota(ethers.parseUnits("0.5", 24));
            expect(await cheddarMazeMinterContract.userQuota()).to.equal(ethers.parseUnits("0.5", 24));
        });

        it("allows the owner to adjust cheddar token contract", async function () {
            await cheddarMazeMinterContract.connect(owner).setCheddarToken(addr1.address);
            expect(await cheddarMazeMinterContract.cheddarToken()).to.equal(addr1.address);
        });

        it("denies owner actions to non owner users", async function() {
            await expect(cheddarMazeMinterContract.connect(addr1).setCheddarToken(addr1.address)).to.be.reverted;
            await expect(cheddarMazeMinterContract.connect(addr2).setDailyQuota("100")).to.be.reverted;
            await expect(cheddarMazeMinterContract.connect(addr3).setUserQuota("100")).to.be.reverted;
            await expect(cheddarMazeMinterContract.connect(addr4).setMinter(addr1.address)).to.be.reverted;
        });
    });
});
