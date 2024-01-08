// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ReceiptToken.sol";
import "./IUniswapRouter.sol";

contract Storage{
    address public weth;
    address payable public treasuryAddress;
    address payable public feeAddress;
    address public token;
    IUniswapRouter public sushiswapRouter;
    ReceiptToken public receiptToken;

    uint256 internal _minSlippage;
    uint256 public lockTime;
    uint256 public fee;
    uint256 constant feeFactor = uint256(10000);
    uint256 public cap;

}
