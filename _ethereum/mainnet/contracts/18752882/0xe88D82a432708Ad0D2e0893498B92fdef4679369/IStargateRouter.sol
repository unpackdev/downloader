// SPDX-License-Identifier: BUSL-1.1
// Ref'd from: https://stargateprotocol.gitbook.io/stargate/interfaces/evm-solidity-interfaces/istargaterouter.sol

// solhint-disable func-name-mixedcase,contract-name-camelcase,max-line-length

pragma solidity 0.8.19;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    /// @param _dstChainId the destination chain id
    /// @param _srcPoolId the source Stargate poolId
    /// @param _dstPoolId the destination Stargate poolId
    /// @param _refundAddress refund address. if msg.sender pays too much gas, return extra eth
    /// @param _amountLD total tokens to send to destination chain
    /// @param _minAmountLD min amount allowed out
    /// @param _lzTxParams default lzTxObj
    /// @param _to destination address, the sgReceive() implementer
    /// @param _payload bytes payload
    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}
