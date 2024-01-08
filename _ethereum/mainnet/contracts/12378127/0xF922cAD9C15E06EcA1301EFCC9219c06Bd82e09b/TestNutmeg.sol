// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;
import "./Nutmeg.sol";

// @notice This contract is a version of Nutmeg that contains additional
// interfaces for testing

contract TestNutmeg is Nutmeg {
    function _testSetBaseAmt (
	uint posId, uint baseAmt
    ) external {
	positionMap[posId].baseAmt = baseAmt;
    }

    function _forceAccrueInterest(
        address token
    ) external {
        accrueInterest(token);
    }
}

