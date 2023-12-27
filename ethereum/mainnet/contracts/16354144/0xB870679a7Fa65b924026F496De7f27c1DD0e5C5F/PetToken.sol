// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./ERC20Burnable.sol";
import "./ReentrancyGuard.sol";

contract PetToken is ERC20Burnable, ReentrancyGuard {

    uint256 private constant MAX_SUPPLY = 2 * (10 ** 8) * (10 ** 18);

    constructor(address account) ERC20('Pet Token', 'PET') {
        _mint(account, MAX_SUPPLY);
    }
}
