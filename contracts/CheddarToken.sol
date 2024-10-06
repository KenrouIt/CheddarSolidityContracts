// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CheddarToken is ERC20, ERC20Burnable, Ownable(msg.sender) {

    mapping(address => bool) public mintersMap;

    constructor(
        string memory name,
        address _minter
    ) ERC20(name, "Cheddar") {
        mintersMap[_minter] = true;
    }

    function decimals() public pure override returns (uint8) {
        return 24;
    }

    function mint(
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(mintersMap[msg.sender], "Caller is not a minter");
        _mint(recipient, amount);
        return true;
    }

    function addMinter(address newMinter) public onlyOwner {
        mintersMap[newMinter] = true;
    }

    function removeMinter(address minter) public onlyOwner {
        delete mintersMap[minter];
    }

    function isMinter(address addr) public view returns (bool) {
        return mintersMap[addr];
    }
}
