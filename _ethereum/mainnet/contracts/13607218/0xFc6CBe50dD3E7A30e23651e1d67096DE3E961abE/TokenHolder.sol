// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Ownable.sol";

abstract contract TokenHolder is Ownable {
    event WithdrawalApproved(address erc20TokenAddress, address to, uint256 amount);

    function approveWithdraw(address erc20Token, address payable to, uint256 amount) external onlyOwner {
        require(erc20Token != address(0), "AD3");
        require(to != address(0), "AD4");
        require(to != address(this), "OT16");
        uint codeLength;
        assembly {
            codeLength := extcodesize(erc20Token)
        }
        require(codeLength > 0, "AD5");

        IERC20 tokenContract = IERC20(erc20Token);
        assert(tokenContract.approve(to, amount));
        emit WithdrawalApproved(erc20Token, to, amount);
    }
}
