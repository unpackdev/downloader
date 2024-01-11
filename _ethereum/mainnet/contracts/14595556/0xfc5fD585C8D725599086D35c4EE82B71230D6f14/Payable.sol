// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Payable
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// Manage payables

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./ERC2981.sol";

contract Payable is Ownable, ERC2981, ReentrancyGuard {
    address public mixDaoAddress = 0x621D420DC767a4fdc3C0eAfE39b915208bc7CC51;

    constructor() {
        _setRoyalties(mixDaoAddress, 1000); // 10% royalties
    }

    /**
     * Set the royalties information.
     * @param recipient recipient of the royalties.
     * @param value percentage (using 2 decimals - 10000 = 100, 0 = 0).
     */
    function setRoyalties(address recipient, uint256 value) external onlyOwner {
        require(recipient != address(0), "zero address");
        _setRoyalties(recipient, value);
    }

    /**
     * Update MixDAO address for withdraw and royalties.
     * @param mixDaoAddress_ The new Mix DAO address.
     */
    function setMixDaoAddress(address mixDaoAddress_) external nonReentrant onlyOwner {
        mixDaoAddress = mixDaoAddress_;
        _setRoyalties(mixDaoAddress, _royalties.amount);
    }

    /**
     * Withdraw funds.
     */
    function withdraw() external nonReentrant onlyOwner {
        Address.sendValue(payable(mixDaoAddress), address(this).balance);
    }
}
