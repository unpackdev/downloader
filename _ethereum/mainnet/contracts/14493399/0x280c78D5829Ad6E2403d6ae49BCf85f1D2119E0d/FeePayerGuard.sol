//SPDX-License-Identifier: BUSL
pragma solidity 0.8.10;

import "./Ownable.sol";

abstract contract FeePayerGuard {

    event FeePayerAdded(address payer);
    event FeePayerRemoved(address payer);

    mapping(address => bool) private feePayers;

    modifier onlyFeePayer() {
        require(feePayers[msg.sender], "Unknown fee payer address");
        require(msg.sender == tx.origin, "Fee payer must be sender of transaction");
        _;
    }

    function hasFeePayer(address _feePayer) external view returns (bool) {
        return feePayers[_feePayer];
    }

    function _addFeePayer(address _feePayer) internal {
        require(_feePayer != address(0), "Invalid fee payer address");
        require(!feePayers[_feePayer], "Already fee payer");
        feePayers[_feePayer] = true;
        emit FeePayerAdded(_feePayer);
    }

    function _removeFeePayer(address _feePayer) internal {
        require(feePayers[_feePayer], "Not fee payer");
        feePayers[_feePayer] = false;
        emit FeePayerRemoved(_feePayer);
    }
}
