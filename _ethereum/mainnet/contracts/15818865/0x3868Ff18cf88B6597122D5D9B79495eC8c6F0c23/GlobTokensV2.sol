//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GlobTokens.sol";

contract GlobTokensV2 is GlobTokens {
    function withdrawFundsV2() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "zero balance.");
        payable(0xd3b0c0d84489e2ecB654B964a09634Fb826E8cDE).transfer(
            (balance * 75) / 100
        );
        payable(0x7fF7AB7315Bd2fFD0FA15342eBf8F0Dd2fAbE48a).transfer(
            (balance * 25) / 100
        );
    }
}
