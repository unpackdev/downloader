// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./ERC20Fee.sol";
import "./Ownable.sol";
import "./TransactionThrottler.sol";

contract Spc is Ownable, ERC20Fee, TransactionThrottler {
    constructor(address _owner) ERC20Fee("SPC", "SPC", 18) {
        _setOwner(_owner);
        _mint(_owner, 10_000_000 * 10**18);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override transactionThrottler(sender, recipient, amount) {
        super._transfer(sender, recipient, amount);
    }    
}