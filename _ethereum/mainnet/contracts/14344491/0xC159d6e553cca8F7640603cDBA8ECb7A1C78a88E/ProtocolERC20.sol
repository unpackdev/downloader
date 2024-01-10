// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";

contract ProtocolERC20 {

    using SafeERC20 for IERC20;

    address internal constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function push(address token, uint256 amt)
        public
        payable
        returns (uint256 _amt)
    {
        _amt = amt;

        if (token != ethAddr) {
            IERC20 tokenContract = IERC20(token);
            _amt = _amt == type(uint256).max
                ? tokenContract.balanceOf(msg.sender)
                : _amt;
            tokenContract.safeTransferFrom(msg.sender, address(this), _amt);
        } else {
            require(
                msg.value == _amt || _amt == type(uint256).max,
                "CHFRY: Invalid Ether Amount"
            );
            _amt = msg.value;
        }
    }

    function pull(
        address token,
        uint256 amt,
        address to
    ) public payable returns (uint256 _amt) {
        _amt = amt;
        bool retCall;
        bytes memory retData;
        if (token == ethAddr) {
            _amt = _amt == type(uint256).max ? address(this).balance : _amt;
            (retCall, retData) = to.call{value: _amt}("");
            require(retCall != false, "CHFRY: withdraw ETH fail");
        } else {
            IERC20 tokenContract = IERC20(token);
            _amt = _amt == type(uint256).max
                ? tokenContract.balanceOf(address(this))
                : _amt;
            tokenContract.safeTransfer(to, _amt);
        }
    }
}
