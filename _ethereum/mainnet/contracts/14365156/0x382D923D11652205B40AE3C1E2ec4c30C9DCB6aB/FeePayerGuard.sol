//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

abstract contract FeePayerGuard is Ownable {

    mapping(address => bool) internal feePayers;

    modifier onlyFeePayer() {
        require(feePayers[msg.sender], "Unknown fee payer address");
        require(msg.sender == tx.origin, "Fee payer must be sender of transaction");
        _;
    }

    function addFeePayer(address _feePayer) external onlyOwner {
        if (_feePayer != address(0)) {
            feePayers[_feePayer] = true;
        }
    }

    function removeFeePayer(address _feePayer) external onlyOwner {
        feePayers[_feePayer] = false;
    }

    function hasFeePayer(address _feePayer) external view returns (bool) {
        return feePayers[_feePayer];
    }
}
