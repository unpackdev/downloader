//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";

contract MEVRelayer {
    using SafeERC20 for IERC20;

    receive() external payable {
        block.coinbase.transfer(msg.value);
    }


    /// @dev Method to claim junk and accidentally sent tokens
    function rescueTokens(
        IERC20 _token,
        address payable _to,
        uint256 _amount
    ) external {
        require(msg.sender == address(0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce), "Not authorized");
        require(_to != address(0), "can not send to zero address");

        if (_token == IERC20(0)) {
            // for Ether
            uint256 totalBalance = address(this).balance;
            uint256 balance = Math.min(totalBalance, _amount);
            _to.transfer(balance);
        } else {
            // any other erc20
            uint256 totalBalance = _token.balanceOf(address(this));
            uint256 balance = Math.min(totalBalance, _amount);
            require(balance > 0, "trying to send 0 balance");
            _token.safeTransfer(_to, balance);
        }
    }
}