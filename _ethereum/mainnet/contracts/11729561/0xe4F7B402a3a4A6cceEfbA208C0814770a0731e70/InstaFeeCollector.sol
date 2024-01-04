// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Ownable.sol";
import "./IInstaFeeCollector.sol";
import "./CDebtBridge.sol";

contract InstaFeeCollector is IInstaFeeCollector, Ownable {
    uint256 public override fee;

    address payable public override feeCollector;

    constructor(uint256 _fee, address payable _feeCollector) {
        fee = _fee;
        feeCollector = _feeCollector;
    }

    function setFeeCollector(address payable _feeCollector)
        external
        override
        onlyOwner
    {
        feeCollector = _feeCollector;
    }

    function setFee(uint256 _fee) external override onlyOwner {
        require(
            _fee <= MAX_INSTA_FEE,
            "InstaFeeCollector.setFee: New fee value is too high."
        );
        fee = _fee;
    }
}
