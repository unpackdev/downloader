// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

// imports
import "./SafeMath.sol";
import "./NonblockingLzApp.sol";

// interfaces
import "./ILucksExecutor.sol";
import "./ILucksBridge.sol";

contract LucksBridge is NonblockingLzApp, ILucksBridge {
    using SafeMath for uint256;
    //---------------------------------------------------------------------------
    // CONSTANTS
    uint8 internal constant TYPE_CREATE_TASK = 1;
    uint8 internal constant TYPE_WITHDRAW_NFT = 2;

    //---------------------------------------------------------------------------
    // VARIABLES
    mapping(uint16 => mapping(uint8 => uint256)) public gasLookup;
    ILucksExecutor public EXECUTOR;
    bool public useLayerZeroToken;

    //---------------------------------------------------------------------------
    // MODIFIERS
    modifier onlyExecutor() {
        require(msg.sender == address(EXECUTOR), "Lucks: caller must be LucksExecutor");
        _;
    }

    constructor(address _lzEndpoint, address _executor) NonblockingLzApp(_lzEndpoint) {
        require(_executor != address(0x0), "Lucks: _executor cannot be 0x0");
        EXECUTOR = ILucksExecutor(_executor);
    }

    // main method
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        uint8 functionType;
        assembly {
            functionType := mload(add(_payload, 32))
        }
        // try-catch all errors/exceptions
        try EXECUTOR.onLzReceive(functionType, _payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    // ============ EXTERNAL functions ============
    // estimateSendFee

    function quoteLayerZeroFee(uint16 _dstChainId, uint8 _functionType, string memory _note, lzTxObj memory _lzTxParams) 
        external view override returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory payload = "";
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10000;
        amounts[1] = 10000;

        if (_functionType == TYPE_CREATE_TASK) {
            TaskItem memory item = TaskItem(
                address(0),
                0,
                address(0),
                amounts,
                amounts,
                address(0),
                TaskStatus.Open,
                block.timestamp,
                block.timestamp,
                1000e18,
                1e18,
                1,
                ExclusiveToken(address(0), 1e18),
                0,
                10000
            );
            TaskExt memory ext = TaskExt(1, "nft collection item title", _note);

            payload = abi.encode(TYPE_CREATE_TASK, item, ext);

        } else if (_functionType == TYPE_WITHDRAW_NFT) {

            payload = abi.encode(TYPE_WITHDRAW_NFT, address(0), 10000);

        } else {
            revert("Lucks: unsupported function type");
        }

        bytes memory lzTxParamBuilt = _txParamBuilder( _dstChainId, _functionType, _lzTxParams);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, useLayerZeroToken, lzTxParamBuilt);
    }

    function estimateCreateTaskFee(uint16 _dstChainId, TaskItem memory item, TaskExt memory ext, lzTxObj memory _lzTxParams) 
        external view override returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory payload = abi.encode(TYPE_CREATE_TASK, item, ext);
        bytes memory lzTxParamBuilt = _txParamBuilder(_dstChainId, TYPE_CREATE_TASK, _lzTxParams);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, useLayerZeroToken, lzTxParamBuilt);
    }

    function estimateWithdrawNFTsFee(uint16 _dstChainId, address payable _user, address nftContract, uint256 depositId, lzTxObj memory _lzTxParams) 
        external view override returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory payload = abi.encode(TYPE_WITHDRAW_NFT, _user, nftContract, depositId);
        bytes memory lzTxParamBuilt = _txParamBuilder(_dstChainId, TYPE_WITHDRAW_NFT, _lzTxParams);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, useLayerZeroToken,lzTxParamBuilt);
    }

    function renounceOwnership() public override onlyOwner {}

    // ============  LOCAL CHAIN (send out message to destination chain)============

    function sendCreateTask(
        uint16 _dstChainId,
        address payable _refundAddress,
        TaskItem memory item,
        TaskExt memory ext,
        lzTxObj memory _lzTxParams
    ) external payable override onlyExecutor {
        bytes memory payload = abi.encode(TYPE_CREATE_TASK, item, ext);
        _call(_dstChainId, TYPE_CREATE_TASK, _refundAddress, _lzTxParams, payload);
    }

    function sendWithdrawNFTs(
        uint16 _dstChainId,        
        address payable _refundAddress,
        address payable _user,
        address nftContract,
        uint256 depositId,
        lzTxObj memory _lzTxParams
    ) external payable override onlyExecutor {
        bytes memory payload = abi.encode(TYPE_WITHDRAW_NFT, _user, nftContract, depositId);
        _call(_dstChainId, TYPE_WITHDRAW_NFT, _refundAddress, _lzTxParams, payload);
    }

    // ============ onlyOwner functions ============

    function setGasAmount(uint16 _dstChainId, uint8 _functionType, uint256 _gasAmount) external onlyOwner {
        require(
            _functionType >= 1 && _functionType <= 4,
            "Lucks: invalid _functionType"
        );
        gasLookup[_dstChainId][_functionType] = _gasAmount;
    }

    // ============ INTERNAL functions ============

    function txParamBuilderType1(uint256 _gasAmount) internal pure returns (bytes memory) {
        uint16 txType = 1;
        return abi.encodePacked(txType, _gasAmount);
    }

    function txParamBuilderType2(uint256 _gasAmount, uint256 _dstNativeAmount, bytes memory _dstNativeAddr) internal pure returns (bytes memory) {
        uint16 txType = 2;
        return abi.encodePacked(txType, _gasAmount, _dstNativeAmount,_dstNativeAddr);
    }

    function _txParamBuilder(
        uint16 _dstChainId,
        uint8 _type,
        lzTxObj memory _lzTxParams
    ) internal view returns (bytes memory) {
        bytes memory lzTxParam;
        address dstNativeAddr;
        {
            bytes memory dstNativeAddrBytes = _lzTxParams.dstNativeAddr;
            assembly {
                dstNativeAddr := mload(add(dstNativeAddrBytes, 20))
            }
        }

        uint256 totalGas = gasLookup[_dstChainId][_type].add(_lzTxParams.dstGasForCall);
        if (_lzTxParams.dstNativeAmount > 0 && dstNativeAddr != address(0x0)) {
            lzTxParam = txParamBuilderType2(totalGas, _lzTxParams.dstNativeAmount, _lzTxParams.dstNativeAddr);
        } else {
            lzTxParam = txParamBuilderType1(totalGas);
        }

        return lzTxParam;
    }

    function _call(
        uint16 _dstChainId, // dst chainId
        uint8 _type, // function type
        address payable _refundAddress, // _user refundAddress
        lzTxObj memory _lzTxParams,
        bytes memory _payload
    ) internal {
        bytes memory _adapterParams = _txParamBuilder(_dstChainId, _type, _lzTxParams);
        address zroPaymentAddr;
        {
            bytes memory zroPaymentAddrBytes = _lzTxParams.zroPaymentAddr;
            assembly {
                zroPaymentAddr := mload(add(zroPaymentAddrBytes, 20))
            }
        }
        _lzSend(_dstChainId, _payload, _refundAddress, zroPaymentAddr, _adapterParams);

        uint64 nextNonce = lzEndpoint.getOutboundNonce(_dstChainId, address(this));
        emit SendMsg(_type, nextNonce);
    }

    function setExecutor(ILucksExecutor _executor) external onlyOwner {
        EXECUTOR = _executor;
    }

    function setUseLayerZeroToken(bool enable) external onlyOwner {
        useLayerZeroToken = enable;
    }

}
