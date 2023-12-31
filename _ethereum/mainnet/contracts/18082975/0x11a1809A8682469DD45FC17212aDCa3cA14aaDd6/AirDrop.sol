// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract AirDrop {

    struct Param {
        address account;
        uint amount;
    }

    function airDropERC20(IERC20 erc20, Param[] calldata param) external{
        for (uint i; i < param.length; i++) {
            SafeERC20.safeTransferFrom(erc20, msg.sender, param[i].account, param[i].amount);
        }
    }

    function airDropETH(Param[] calldata param) external payable{
        uint total;
        for (uint i; i < param.length; i++) {
            payable(param[i].account).transfer(param[i].amount);
            total += param[i].amount;
        }
        if (msg.value > total) {
            payable(msg.sender).transfer(msg.value - total);
        }
    }

}