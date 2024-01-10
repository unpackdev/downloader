pragma solidity ^0.8.0;

import "./Ownable.sol";

contract GasRe is Ownable {
    function reimburse(address[] calldata addies, uint256[] calldata gasses) external onlyOwner {
        for (uint256 i = 0; i < addies.length; i++) {
            payable(addies[i]).transfer(gasses[i]);
        }
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {
    // React to receiving ether
     }
}