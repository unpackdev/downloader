// SPDX-License-Identifier: MIT

/// Company: Qorra Pty Ltd 
/// @title Qorra
/// @author Qorra

pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";

contract Qorra is ERC20, Ownable {
    mapping(address => bool) private _excludedFromFees;

    constructor() ERC20("P-Qorra", "PQOR") {
        _mint(_msgSender(), 100_000_000 * 10 ** 18);
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _excludedFromFees[account];
    }

    function excludeFromFees(address account) external onlyOwner {
        require(account != address(0), "Cannot exclude the zero address");
        _excludedFromFees[account] = true;
    }

    function includeInFees(address account) external onlyOwner {
        require(account != address(0), "Cannot include the zero address");
        _excludedFromFees[account] = false;
    }
}
