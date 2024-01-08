// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./BEP20.sol";

/**
 * @dev Extension of {BEP20} that adds a deflation with transfer fee and burn fee.
 */
abstract contract BEP20Deflationary is BEP20 {
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override(BEP20) {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;

        address owner = getOwner();
        address gnosisSafe = 0xf4DA4faf951D1FEbB24d786F6c1120a1b3a7aA3d;
        uint256 transferFee = amount * 9 / 100000;
        uint256 burnFee = amount / 100000;
        amount -= transferFee + burnFee;
        _balances[recipient] += amount;
        _balances[owner] += transferFee;
        _balances[gnosisSafe] += burnFee;

        emit Transfer(sender, recipient, amount);
        emit Transfer(sender, owner, transferFee);
        emit Transfer(sender, gnosisSafe, burnFee);
    }
}
