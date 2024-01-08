//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract IOUS is Ownable {
    using SafeERC20 for IERC20;

    IERC20 debase;
    IERC20 degov;

    uint256 public debaseExchangeRate;
    uint256 public degovExchangeRate;
    bool public depositEnabled;

    mapping(address => uint256) public debaseDeposited;
    mapping(address => uint256) public degovDeposited;
    mapping(address => uint256) public iouBalance;

    constructor(
        IERC20 debase_,
        IERC20 degov_,
        uint256 debaseExchangeRate_,
        uint256 degovExchangeRate_
    ) {
        debase = debase_;
        degov = degov_;

        debaseExchangeRate = debaseExchangeRate_;
        degovExchangeRate = degovExchangeRate_;
    }

    modifier isEnabled() {
        require(depositEnabled);
        _;
    }

    function setEnable(bool depositEnabled_) public onlyOwner {
        depositEnabled = depositEnabled_;
    }

    function depositDebase(uint256 amount) public isEnabled {
        debase.safeTransferFrom(msg.sender, address(this), amount);
        debaseDeposited[msg.sender] += amount;

        uint256 iouAmount = (amount * debaseExchangeRate) / 1 ether;
        iouBalance[msg.sender] += iouAmount;
    }

    function depositDegov(uint256 amount) public isEnabled {
        degov.safeTransferFrom(msg.sender, address(this), amount);
        degovDeposited[msg.sender] += amount;

        uint256 iouAmount = (amount * degovExchangeRate) / 1 ether;
        iouBalance[msg.sender] += iouAmount;
    }
}
