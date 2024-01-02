// SPDX-License-Identifier: MIT
/**
 * HighWei token.
*/
pragma solidity ^0.8.19;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20.sol";

contract HighWei is ERC20, Ownable {
    uint256 private _totalSupply = 1000000000 * (10 ** 18);

    constructor() ERC20("HighWei", "HighWei") {
        _mint(msg.sender, _totalSupply);
    }

}
