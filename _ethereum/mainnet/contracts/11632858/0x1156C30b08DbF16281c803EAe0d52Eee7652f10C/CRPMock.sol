// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "./ConfigurableRightsPool.sol";

contract CRPMock is ConfigurableRightsPool {
    uint256 public value;

    function setValue(uint256 newValue) external {
        value = newValue;
    }
}
