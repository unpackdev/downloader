// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./AccessOperatable.sol";

abstract contract Withdrawable is AccessOperatable {

    function withdrawEther() public onlyOperator() payable {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawERC20(
        address _contract
    ) public onlyOperator() {
        require(_contract !=  address(0), "Withdrawable: contract address is zero");

        IERC20 erc20 = IERC20(_contract);
        erc20.transfer(msg.sender, erc20.balanceOf(address(this)));
    }
}
