// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./CheddarToken.sol";

contract CheddarMazeMinter is Ownable(msg.sender) {
    event mintAmountEvent(uint256 mintAmount);

    address public minter;
    address public cheddarToken;
    bool public active = true;

    uint256 public dailyQuota = 10000 * 10 ** 24; // Default daily quota set to 10000 tokens, adjusted for decimals
    uint256 public userQuota = 555 * 10 ** 24;

    mapping(address => uint256) public userLastMintDay;
    mapping(address => uint256) public userDailyMinted;

    uint256 public todayMinted;
    uint256 public currentDay;

    uint256 private constant DAY_IN_SECONDS = 86400;

    constructor(address _cheddarToken, address _minter) {
        cheddarToken = _cheddarToken;
        minter = _minter;
        currentDay = block.timestamp / DAY_IN_SECONDS;
    }

    function mint(
        address recipient,
        uint256 amount,
        address referral
    ) public returns (uint256, uint256) {
        require(msg.sender == minter, "Caller is not the minter");
        require(active, "Contract is deactivated");
        uint256 today = block.timestamp / DAY_IN_SECONDS;
        if (today != currentDay) {
            todayMinted = 0;
            currentDay = today;
        }

        uint256 referralAmount = referral != address(0) ? amount / 20 : 0;
        if (referral != address(0)) {
            bool isReferralSuccessfull = CheddarToken(cheddarToken).mint(
                referral,
                referralAmount
            );
            require(isReferralSuccessfull, "Referral minting failed");
        }

        if (userLastMintDay[recipient] != today) {
            userDailyMinted[recipient] = 0;
        }

        uint256 userTodayMinted = userDailyMinted[recipient];
        uint256 userAmount = amount - referralAmount;
        uint256 mintAmount = Math.min(
            Math.min(userAmount, dailyQuota - todayMinted),
            userQuota - userTodayMinted
        );
        emit mintAmountEvent(mintAmount);
        todayMinted = todayMinted + mintAmount;
        if (userTodayMinted >= userQuota) {
            return (0, referralAmount); // User has reached their quota, no minting for the user but referral processed.
        }

        userDailyMinted[recipient] += mintAmount;
        bool isUserSuccessfull = CheddarToken(cheddarToken).mint(
            recipient,
            mintAmount
        );
        require(isUserSuccessfull, "User minting failed");

        return (mintAmount, referralAmount);
    }

    function toggleActive() public onlyOwner {
        active = !active;
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    function setDailyQuota(uint256 _dailyQuota) public onlyOwner {
        dailyQuota = _dailyQuota;
    }

    function setUserQuota(uint256 _userQuota) public onlyOwner {
        userQuota = _userQuota;
    }

    function setCheddarToken(address _cheddarToken) public onlyOwner {
        cheddarToken = _cheddarToken;
    }

    function getTodayMinted() public view returns (uint256) {
        uint256 today = block.timestamp / DAY_IN_SECONDS;
        if (today != currentDay) {
            return 0;
        }
        return todayMinted;
    }
}
