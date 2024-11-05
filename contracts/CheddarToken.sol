// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CheddarToken is ERC20, ERC20Burnable, Ownable {

    mapping(address => bool) private mintersMap;

    event Mint(address indexed to, uint256 amount);
    event AddMinter(address indexed minter);
    event RemoveMinter(address indexed minter);

    constructor(
        string memory _name,
        address _minter
    ) ERC20(_name, "Cheddar") Ownable(msg.sender) {
        addMinter(_minter);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Caller is not a _minter");
        _;
    }

    function decimals() public pure override returns (uint8) {
        return 24;
    }

    function mint(
        address _recipient,
        uint256 _amount
    ) external onlyMinter {
        _mint(_recipient, _amount);
        emit Mint(_recipient, _amount);
    }

    function addMinter(address _newMinter) public onlyOwner {
        mintersMap[_newMinter] = true;
        emit AddMinter(_newMinter);
    }

    function removeMinter(address _minter) external onlyOwner {
        delete mintersMap[_minter];
        emit RemoveMinter(_minter);
    }

    function isMinter(address _addr) public view returns (bool) {
        return mintersMap[_addr];
    }
}
