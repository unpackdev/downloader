// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OptimizedLzApp.sol";

contract GasZipLZ is OptimizedLzApp {

    constructor(address _lzEndpoint) OptimizedLzApp(_lzEndpoint) {
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

    function deposit(
        uint256[] calldata _depositParams,
        address to
    ) external payable {
        uint256 fee;
        for (uint i; i < _depositParams.length; i++) {
            fee += _deposit(_depositParams[i], to);
        }
        require(msg.value >= fee, "Fee Not Met");
    }

    function _deposit(uint256 _depositParam, address _to) internal returns (uint256 fee) {
        (uint16 _dstChainId, bytes memory _adapterParams) = _decodeDeposit(_depositParam, _to);
        fee = estimateFees(_dstChainId, _adapterParams);
        _lzSend(_dstChainId, "", payable(this), _adapterParams, fee);
    }

    function _decodeDeposit(uint256 _depositParam, address _to) internal view returns (uint16 _dstChainId, bytes memory _adapterParams) {
        _dstChainId = uint16(_depositParam >> 240);
        _adapterParams = createAdapterParams(_dstChainId, uint256(uint240(_depositParam)), _to);
    }

    function createAdapterParams(uint16 dstChainId, uint256 nativeAmount, address to) public view returns (bytes memory) {
        return abi.encodePacked(uint16(2), getGasLimit(dstChainId), nativeAmount, to);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        bool s;
        if (token == address(0)) {
            (s,) = msg.sender.call{value: address(this).balance}("");
        } else {
            (s,) = token.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount));
        }
        require(s, "Withdraw Failed");
    }

    receive() external payable {}
}

