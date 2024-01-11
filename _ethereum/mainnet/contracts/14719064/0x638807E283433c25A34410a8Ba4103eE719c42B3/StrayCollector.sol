pragma solidity >=0.7;

import "./IERC20.sol";
import "./Ownable.sol";

abstract contract StrayCollector is Ownable {

    uint256 public feePercentage;

    function collectStrays(address tokenToRetrieve, uint256 amountToRetrieve, address sendTo) external onlyOwner {
        if (IERC20(tokenToRetrieve).balanceOf(address(this)) >= amountToRetrieve) {
            IERC20(tokenToRetrieve).transfer(sendTo, amountToRetrieve);
        }
    }

    function changeFeePercentage(uint256 newFeePercentage) external onlyOwner {
        require(newFeePercentage < 1e4);
        feePercentage = newFeePercentage;
    }
}
