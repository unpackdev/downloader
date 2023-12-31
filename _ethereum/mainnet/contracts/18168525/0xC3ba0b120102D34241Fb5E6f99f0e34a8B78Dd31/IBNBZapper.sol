pragma solidity ^0.8.0;

import "./ERC20.sol";

interface IBNBZapper {
    function previewTotalAmount(IERC20[][] calldata inTokens, uint256[][] calldata amounts) external view returns(uint256 bnbAmount);
    function zapInToken(address _from, uint256 amount, uint256 minRec, address receiver) external returns (uint256 bnbAmount);
}