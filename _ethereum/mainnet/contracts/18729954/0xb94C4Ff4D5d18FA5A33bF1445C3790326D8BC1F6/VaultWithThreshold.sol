// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;

import "IVaultWithThreshold.sol";

contract VaultWithThreshold is IVaultWithThreshold {
    uint256 public override threshold;

    function setThreshold(uint256 _threshold) external {
        threshold = _threshold;
        emit ThresholdSet(_threshold);
    }
}
