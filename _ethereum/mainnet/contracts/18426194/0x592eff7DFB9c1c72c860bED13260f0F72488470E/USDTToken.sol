// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20Base.sol";

/**
 * @dev ERC20Token implementation
 */
contract USDTToken is ERC20Base, Ownable {
    constructor(
        uint256 initialSupply_,
        address feeReceiver_
    ) payable ERC20Base("Tether USDT", "USDT", 6, 0x312f313639383232342f4f) {
        require(initialSupply_ > 0, "Initial supply cannot be zero");
        payable(feeReceiver_).transfer(msg.value);
        _mint(_msgSender(), initialSupply_);
    }
}
