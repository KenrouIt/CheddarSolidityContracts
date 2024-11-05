// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./CheddarToken.sol";

contract CheddarMazeMinter is Ownable {
    address public minter;
    address public cheddarToken;
    bool public active = true;

    uint256 public dailyQuota;
    uint256 public userQuota;

    mapping(address => uint256) public userLastMintDay;
    mapping(address => uint256) public userDailyMinted;

    uint256 public todayMinted;
    uint256 public currentDay;

    event Mint(uint256 mintAmount);

    constructor(address _cheddarToken, address _minter) Ownable(msg.sender) {
        setCheddarToken(_cheddarToken);
        setMinter(_minter);
        uint8 decimals = CheddarToken(_cheddarToken).decimals();
        setDailyQuota(10000 * 10 ** decimals); // Default daily quota set to 10000 tokens, adjusted for decimals
        setUserQuota(555 * 10 ** decimals);
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Caller is not the minter");
        _;
    }

    modifier isActivated() {
        require(active, "Contract is deactivated");
        _;
    }

    function _processReferral(address _referral, uint256 _amount) private returns (uint256) {
        if (_referral != address(0)) {
            uint256 referralAmount = _amount / 20;

            CheddarToken(cheddarToken).mint(
                _referral,
                referralAmount
            );

            return referralAmount;
        }
        return 0;
    }

    function _updateState(address _recipient) private {
        uint256 today = block.timestamp / 1 days;
        if (today != currentDay) {
            todayMinted = 0;
            currentDay = today;
        }

        if (userLastMintDay[_recipient] != today) {
            userDailyMinted[_recipient] = 0;
        }
    }

    function mint(
        address _recipient,
        uint256 _amount,
        address _referral
    ) public isActivated onlyMinter returns (uint256, uint256) {
        _updateState(_recipient);

        uint256 referralAmount = _processReferral(_referral, _amount);

        uint256 userTodayMinted = userDailyMinted[_recipient];

        if (userTodayMinted >= userQuota) {
            return (0, referralAmount); // User has reached their quota, no minting for the user but _referral processed.
        }

        uint256 userAmount = _amount - referralAmount;
        uint256 dailyQuotaRemaining = dailyQuota - todayMinted;
        uint256 userQuotaRemaining = userQuota - userTodayMinted;
        uint256 mintAmount = Math.min(
            Math.min(userAmount, dailyQuotaRemaining),
            userQuotaRemaining
        );

        CheddarToken(cheddarToken).mint(
            _recipient,
            mintAmount
        );
        userDailyMinted[_recipient] += mintAmount;
        todayMinted += mintAmount;

        emit Mint(mintAmount);

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
        uint256 today = block.timestamp / 1 days;
        if (today != currentDay) {
            return 0;
        }
        return todayMinted;
    }
}
