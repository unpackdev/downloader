// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

contract USDZ is ERC20Burnable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    uint256 private _totalSupplyCap;
    EnumerableSet.AddressSet private whitelist;

    constructor() ERC20("USDZ", "USDZ") Ownable(msg.sender) {
        uint256 totalSupplyCap = 1000000000 * 10**18;
        whitelist.add(msg.sender);
        _mint(msg.sender, totalSupplyCap);
        _totalSupplyCap = totalSupplyCap;
    }

    modifier onlyWhitelisted() {
        require(whitelist.contains(msg.sender), "Sender not whitelisted");
        _;
    }

    function addToWhitelist(address account) external onlyOwner {
        require(!whitelist.contains(account), "Address is already whitelisted");
        whitelist.add(account);
        emit AddedToWhitelist(account);
    }

    function removeFromWhitelist(address account) external onlyOwner {
        require(whitelist.contains(account), "Address is not whitelisted");
        whitelist.remove(account);
        emit RemovedFromWhitelist(account);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        require(whitelist.contains(msg.sender), "Sender not whitelisted");
        require(whitelist.contains(to), "Receiver not whitelisted");
        _transfer(msg.sender, to, value);
        return true;
    }
}
