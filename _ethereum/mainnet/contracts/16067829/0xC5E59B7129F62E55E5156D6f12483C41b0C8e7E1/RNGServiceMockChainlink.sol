// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// import "./RNGServiceMock.sol";
import "./RNGChainlinkV2Interface.sol";
import "./VRFCoordinatorV2Interface.sol";

contract RNGServiceMockChainlink is RNGChainlinkV2Interface {
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

    function getKeyHash() external view override returns (bytes32) {
        return bytes32(0);
    }

    function getSubscriptionId() external view override returns (uint64) {
        return 0;
    }

    function getVrfCoordinator()
        external
        view
        override
        returns (VRFCoordinatorV2Interface)
    {
        return VRFCoordinatorV2Interface(address(0));
    }

    function setKeyhash(bytes32 keyHash) external override {
    }

    function setSubscriptionId(uint64 subscriptionId) external override {}

    function setAllowedCaller(address allowed) external override {}
}