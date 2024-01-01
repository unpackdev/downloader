// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwner.sol";

abstract contract CCIPApprovedSource is ConfirmedOwner {
    error SourceNotApproved(uint64 chainSelector, address sender);

    event SourceApproved(uint64 chainSelector, address sender);
    event SourceApprovalRevoked(uint64 chainSelector, address sender);

    mapping(uint256 sourceChainAndAddress => bool) private _sources;

    modifier onlyApprovedSource(uint64 chainSelector, bytes memory sender) {
        address _sender = abi.decode(sender, (address));
        if (!_sourceApproved(chainSelector, _sender)) revert SourceNotApproved(chainSelector, _sender);
        _;
    }

    function approveSource(uint64 chainSelector, address sender) external onlyOwner {
        uint256 sourceChainAndAddress = uint256(uint160(sender)) | (chainSelector) << 160;
        _sources[sourceChainAndAddress] = true;
        emit SourceApproved(chainSelector, sender);
    }

    function revokeSourceApproval(uint64 chainSelector, address sender) external onlyOwner {
        uint256 sourceChainAndAddress = uint256(uint160(sender)) | (chainSelector) << 160;
        _sources[sourceChainAndAddress] = false;
        emit SourceApprovalRevoked(chainSelector, sender);
    }

    function sourceApproved(uint64 chainSelector, address sender) external view returns (bool) {
        return _sourceApproved(chainSelector, sender);
    }

    function _sourceApproved(uint64 chainSelector, address sender) internal view returns (bool) {
        uint256 sourceChainAndAddress = uint256(uint160(sender)) | (chainSelector) << 160;
        return _sources[sourceChainAndAddress];
    }

}