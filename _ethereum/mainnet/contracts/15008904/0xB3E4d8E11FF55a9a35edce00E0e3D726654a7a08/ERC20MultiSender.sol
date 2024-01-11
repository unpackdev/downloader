//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.7;

import "./Ownable.sol";

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ERC20MultiSender is Ownable {

    function multiSend(IERC20 token, address from, address[] memory recipients, uint256[] memory amounts) external onlyOwner {

        require(recipients.length > 0);
        require(recipients.length == amounts.length);
        
        uint256 allowance = token.allowance(from, address(this));
        uint256 currentSum = 0;
        
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 amount = amounts[i];
            require(amount > 0);
            currentSum+=amount;
            require(currentSum <= allowance);
            bool result = token.transferFrom(from, recipients[i], amount);
            require(result, "Multisend: Could not transfer");
        }
    }
}