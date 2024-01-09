// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Payable
/// Manage payables

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./ERC2981.sol";

contract Payable is Ownable, ERC2981, ReentrancyGuard {

    address private constant ADDR1 = 0x9CBcFb399312F8e8A8576140F226937261CC82bd; // The rest
    address private constant ADDR2 = 0x3142829D0D9Ab30a1Dc56E3932949b4c10497E75; // 20
    address private constant ADDR3 = 0xfeE840fFC2b70E5a4C280C852E30B13DB39CEd7a; // 20
    address private constant ADDR4 = 0x235834A1E754996D825a92f2eA0bd39603d120Ec; // 5

    constructor() {
        _setRoyalties(ADDR1, 500); // 5% royalties
    }

    /**
     * Set the royalties information
     * @param recipient recipient of the royalties
     * @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
     */
    function setRoyalties(address recipient, uint256 value) external onlyOwner {
        require(recipient != address(0), "zero address");
        _setRoyalties(recipient, value);
    }

    /**
     * Withdraw funds
     */
    function withdraw() external nonReentrant() {
        require(msg.sender == owner() || msg.sender == ADDR2, "Payable: Locked withdraw");
        uint256 five = address(this).balance / 20;
        Address.sendValue(payable(ADDR1), five * 11);
        Address.sendValue(payable(ADDR2), five * 4);
        Address.sendValue(payable(ADDR3), five * 4);
        Address.sendValue(payable(ADDR4), five);
    }

}
