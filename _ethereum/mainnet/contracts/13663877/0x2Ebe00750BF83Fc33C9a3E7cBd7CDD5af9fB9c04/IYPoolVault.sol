pragma solidity ^0.8.0;

import {IERC20} from "ERC20.sol";

interface IYPoolVault {
    function transferToSwapper(IERC20 token, uint256 amount) external;
    function receiveAssetFromSwapper(IERC20 token, uint256 amount, uint256 xyFeeAmount, uint256 gasFeeAmount) external payable;
}
