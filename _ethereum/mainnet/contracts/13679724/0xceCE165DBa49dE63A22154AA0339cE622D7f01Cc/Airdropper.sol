pragma solidity 0.8.4;

import "./IERC20.sol";

contract BatchMessenger {
    function message(string calldata message, address token, uint256 amount, address[] calldata recipients) external {
        for(uint256 i = 0; i < recipients.length; i++){
            IERC20(token).transfer(recipients[i], amount);
        }
    }
}
