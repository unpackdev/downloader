// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";

contract GasZipLZ is LzApp {

    constructor(address _lzEndpoint) LzApp(_lzEndpoint) {
        _initializeOwner(msg.sender);
    }

    function estimateFees(uint16[] calldata _dstChainIds, bytes[] calldata _adapterParams) external view returns (uint256[] memory nativeFees) {
        nativeFees = new uint256[](_dstChainIds.length);
        for (uint i; i < _dstChainIds.length; i++) {
            nativeFees[i] = estimateFees(_dstChainIds[i], _adapterParams[i]);
        }
    }

    function estimateFees(uint16 _dstChainId, bytes memory _adapterParams) public view returns (uint256 nativeFee) {
        (nativeFee,) = lzEndpoint.estimateFees(_dstChainId, address(this), "", false, _adapterParams);
    }

    function _blockingLzReceive(uint16, bytes memory, uint64, bytes memory) internal virtual override {}

    // optimized deposit - adapterParams is packed gasLimit and nativeAmount, to is appended
    function deposit(
        uint16[] calldata _dstChainIds,
        uint256[] calldata _adapterParams,
        address to
    ) external payable {
        require(_dstChainIds.length == _adapterParams.length, "Length Mismatch");
        uint256 fee;
        for (uint i; i < _dstChainIds.length; i++) {
            fee += deposit(_dstChainIds[i], createAdapterParams(uint128(_adapterParams[i] >> 128), uint128(_adapterParams[i]), to));
        }
        require(msg.value >= fee, "Fee Not Met");
    }

    function deposit(uint16 _dstChainId, bytes memory _adapterParams) public payable returns (uint256 fee) {
        fee = estimateFees(_dstChainId, _adapterParams);
        require(msg.value >= fee, "Fee Not Met");
        _lzSend(_dstChainId, "", payable(this), address(0), _adapterParams, fee);
    }

    function createAdapterParams(uint256 gasLimit, uint256 nativeAmount, address to) public pure returns (bytes memory) {
        return abi.encodePacked(uint16(2), gasLimit, nativeAmount, to);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        bool s;
        if (token == address(0)) {
            (s,) = payable(owner()).call{value: address(this).balance}("");
        } else {
            (s,) = token.call(abi.encodeWithSignature("transfer(address,uint256)", owner(), amount));
        }
        require(s, "Withdraw Failed");
    }

    function setTrusted(uint16[] calldata _remoteChainIds, address[] calldata _remoteAddresses) external onlyOwner {
        require(_remoteChainIds.length == _remoteAddresses.length);

        for (uint i; i < _remoteChainIds.length; i++) {
            trustedRemoteLookup[_remoteChainIds[i]] = abi.encodePacked(_remoteAddresses[i], address(this));
        }
    }

    receive() external payable {}
}

