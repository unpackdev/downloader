// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Payable
/// @author MilkyTaste#8662 @MilkyTasteEth https://milkytaste.xyz
/// Manage payables

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./ERC2981.sol";

contract Payable is Ownable, ERC2981, ReentrancyGuard {

    address internal commyAddress = 0x6716D41029631116c5245096c46b04aca47D0Bd0;
    address private constant ADDR1 = 0x8bffc7415B1F8ceA3BF9e1f36EBb2FF15d175CF5;
    address private constant ADDR2 = 0x4c54b734471EF8080C5c252e5588F625D2e5E93E;

    constructor() {
        _setRoyalties(commyAddress, 690); // 6.9% royalties
    }

    /**
     * Set the royalties information
     * @param recipient recipient of the royalties
     * @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
     */
    function setRoyalties(address recipient, uint256 value) external onlyOwner {
        require(recipient != address(0), "Payable: Zero address");
        _setRoyalties(recipient, value);
    }

    /**
     * Withdraw funds
     */
    function withdraw() external nonReentrant() {
        require(msg.sender == owner() || msg.sender == ADDR2, "Payable: Locked withdraw");
        uint256 twenty = address(this).balance / 5;
        Address.sendValue(payable(ADDR1), twenty * 2);
        Address.sendValue(payable(ADDR2), twenty);
        Address.sendValue(payable(commyAddress), address(this).balance); // The rest
    }

}
