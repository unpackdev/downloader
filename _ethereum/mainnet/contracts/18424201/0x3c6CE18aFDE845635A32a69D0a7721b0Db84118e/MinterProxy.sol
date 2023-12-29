// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity 0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

import "./IMinterProxy.sol";
import "./IToSTBTLp.sol";
import "./IMinter.sol";
import "./IUSDV.sol";

/// @dev assume that any from/to tokens do not have transfer fee
contract MinterProxy is IMinterProxy, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    address public immutable usdv;

    EnumerableSet.UintSet private minterCodeHashes;
    mapping(uint32 color => address minter) public colorToMinter;
    mapping(address minter => uint32 color) public minterToColor;

    address public toSTBTLp;

    constructor(address _usdv) {
        usdv = _usdv;
    }

    // ------------------ onlyOwner ------------------
    function addMinterCodeHash(uint _hash) external onlyOwner {
        if (minterCodeHashes.contains(_hash)) revert HashExists();
        minterCodeHashes.add(_hash);
        emit AddedMinterCodeHash(_hash);
    }

    function removeMinterCodeHash(uint _hash) external onlyOwner {
        if (!minterCodeHashes.contains(_hash)) revert HashNotExists();
        minterCodeHashes.remove(_hash);
        emit RemovedMinterCodeHash(_hash);
    }

    function registerMinter(address _minter) external onlyOwner {
        _validateMinterCode(_minter);

        IMinter minter = IMinter(_minter);
        if (minter.minterProxy() != address(this)) revert InvalidMinter();
        uint32 color = minter.color();

        if (minterToColor[_minter] != 0 || colorToMinter[color] != address(0)) revert MinterAlreadyRegistered();
        minterToColor[_minter] = color;
        colorToMinter[color] = _minter;

        emit RegisteredMinter(_minter, color);
    }

    function unregisterMinter(address _minter) external onlyOwner {
        uint32 color = minterToColor[_minter];
        if (color == 0) revert MinterNotRegistered(color);

        colorToMinter[color] = address(0);

        minterToColor[_minter] = 0;

        emit UnregisteredMinter(_minter, color);
    }

    function setToSTBTLp(address _toSTBTLp) external onlyOwner {
        toSTBTLp = _toSTBTLp;
        emit SetToSTBTLp(_toSTBTLp);
    }

    // ------------------ external ------------------
    function swapToUSDV(
        IMinter.SwapParam calldata _param,
        address _usdvReceiver,
        uint32 _mintColor
    ) external returns (uint usdvOut) {
        address minter = _getMinterFromColor(_mintColor);
        IERC20(_param.fromToken).safeTransferFrom(msg.sender, minter, _param.fromTokenAmount);
        usdvOut = IMinter(minter).swapToUSDV(msg.sender, toSTBTLp, _param, _usdvReceiver);
    }

    function swapToUSDVAndSend(
        IMinter.SwapParam calldata _param,
        bytes32 _usdvReceiver,
        uint32 _dstEid,
        bytes calldata _extraOptions,
        MessagingFee calldata _msgFee,
        address payable _refundAddress,
        uint32 _mintColor
    ) external payable returns (uint usdvOut) {
        address minter = _getMinterFromColor(_mintColor);

        IERC20(_param.fromToken).safeTransferFrom(msg.sender, minter, _param.fromTokenAmount);
        usdvOut = IMinter(minter).swapToUSDVAndSend{value: msg.value}(
            msg.sender,
            toSTBTLp,
            _param,
            _usdvReceiver,
            _dstEid,
            _extraOptions,
            _msgFee,
            _refundAddress
        );
    }

    function isRegistered(address _addr) external view returns (bool) {
        return minterToColor[_addr] != 0;
    }

    // ------------------ view ------------------
    function getSupportedFromTokens(uint32 _color) external view returns (address[] memory tokens) {
        address minter = _getMinterFromColor(_color);
        return IMinter(minter).getSupportedFromTokens(toSTBTLp);
    }

    function getSwapToUSDVAmountOut(
        address _fromToken,
        uint _fromTokenAmount,
        uint32 _mintColor
    ) external view returns (uint usdvOut) {
        address minter = _getMinterFromColor(_mintColor);
        return IMinter(minter).getSwapToUSDVAmountOut(toSTBTLp, _fromToken, _fromTokenAmount);
    }

    function getSwapToUSDVAmountOutVerbose(
        address _fromToken,
        uint _fromTokenAmount,
        uint32 _mintColor
    ) external view returns (uint usdvOut, uint fee, uint reward) {
        address minter = _getMinterFromColor(_mintColor);
        return IMinter(minter).getSwapToUSDVAmountOutVerbose(toSTBTLp, _fromToken, _fromTokenAmount);
    }

    function getMinterCodeHashes() external view returns (uint[] memory) {
        return minterCodeHashes.values();
    }

    // ------------------ internal ------------------
    function _getMinterFromColor(uint32 _color) internal view returns (address minter) {
        minter = colorToMinter[_color];
        if (minter == address(0)) revert MinterNotRegistered(_color);
        _validateMinterCode(minter);
    }

    // verify that the minter's CodeHash (using extcodehash) was added to whitelist
    function _validateMinterCode(address _addr) internal view {
        uint hash;
        assembly {
            hash := extcodehash(_addr)
        }
        if (!minterCodeHashes.contains(hash)) revert InvalidMinter();
    }
}
