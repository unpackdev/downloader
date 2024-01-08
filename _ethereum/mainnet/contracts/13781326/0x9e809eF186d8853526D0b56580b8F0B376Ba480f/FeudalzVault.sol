// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./IGoldz.sol";

contract FeudalzVault is AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IGoldz goldz = IGoldz(0x7bE647634A942e73F8492d15Ae492D867Ce5245c);
    
    bool public isSalesActive = true;

    mapping(address => uint8) _addressToVaultLevel;

    uint[] public prices;
    
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        prices = [
            40 ether,
            80 ether,
            120 ether,
            240 ether,
            480 ether,
            960 ether,
            2880 ether,
            8640 ether,
            25920 ether
        ];
    }

    function buyVault() external {
        require(vaultLevelOfOwner(msg.sender) < prices.length + 1, "vault is at max level");

        goldz.transferFrom(msg.sender, address(this), nextVaultPrice(msg.sender));

        _addressToVaultLevel[msg.sender]++;
    }

    function buyVault(address receiver) external onlyRole(ADMIN_ROLE) {
        require(vaultLevelOfOwner(receiver) < prices.length + 1, "vault is at max level");
        _addressToVaultLevel[receiver]++;
    }

    function nextVaultPrice(address owner) public view returns (uint) {
        return prices[_addressToVaultLevel[owner]];
    }

    function vaultLevelOfOwner(address owner) public view returns (uint) {
        return _addressToVaultLevel[owner] + 1;
    }

    function toggleSales() external onlyRole(ADMIN_ROLE) {
        isSalesActive = !isSalesActive;
    }
    
    function setPrices(uint[] memory newPrices) external onlyRole(ADMIN_ROLE) {
        prices = newPrices;
    }

    function withdrawGoldz() external onlyRole(ADMIN_ROLE) {
        uint amount = goldz.balanceOf(address(this));
        goldz.transfer(msg.sender, amount);
    }

    function burnGoldz() external onlyRole(ADMIN_ROLE) {
        uint balance = goldz.balanceOf(address(this));
        goldz.burn(balance);
    }
}