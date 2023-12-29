// SPDX-License-Identifier: MIT
/**
 * Pudgy Coin
 * Twitter: https://twitter.com/pudgycoineth
*/
pragma solidity ^0.8.19;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20.sol";

contract Pudgy is ERC20, Ownable {
    uint256 private _totalSupply = 1000000000 * (10 ** 18);

    constructor() ERC20("Pudgy", "PUDGY") {
        _mint(msg.sender, _totalSupply);
    }

}
