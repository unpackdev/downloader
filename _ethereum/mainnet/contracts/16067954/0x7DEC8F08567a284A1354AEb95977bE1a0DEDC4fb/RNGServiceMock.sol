// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./RNGInterface.sol";

contract RNGServiceMock is RNGInterface {
    uint256 internal random;
    address internal feeToken;
    uint256 internal requestFee;
    uint32 internal _lastRequestId = 0;

    function getLastRequestId() external view override returns (uint32 requestId) {
        return _lastRequestId;
    }

    function setRequestFee(address _feeToken, uint256 _requestFee) external {
        feeToken = _feeToken;
        requestFee = _requestFee;
    }

    /// @return _feeToken
    /// @return _requestFee
    function getRequestFee()
        external
        view
        override
        returns (address _feeToken, uint256 _requestFee)
    {
        return (feeToken, requestFee);
    }

    function setRandomNumber(uint256 _random) external {
        random = _random;
    }

    function requestRandomNumber() external override returns (uint32, uint32) {
        ++_lastRequestId;
        return (_lastRequestId, 1);
    }

    function isRequestComplete(uint32) external pure override returns (bool) {
        return true;
    }

    function randomNumber(uint32) external view override returns (uint256) {
        return random;
    }
}
