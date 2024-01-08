//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./LibRouter.sol";

struct WrappedTokenParams {
    string name;
    string symbol;
    uint8 decimals;
}

interface IRouter {
    /// @notice An event emitted once a Lock transaction is executed
    event Lock(uint8 targetChain, address token, bytes receiver, uint256 amount, uint256 serviceFee);
    /// @notice An event emitted once a Burn transaction is executed
    event Burn(address token, uint256 amount, bytes receiver);
    /// @notice An event emitted once a BurnAndTransfer transaction is executed
    event BurnAndTransfer(uint8 targetChain, address token, uint256 amount, bytes receiver);
    /// @notice An event emitted once an Unlock transaction is executed
    event Unlock(address token, uint256 amount, address receiver);
    /// @notice An even emitted once a Mint transaction is executed
    event Mint(address token, uint256 amount, address receiver);
    /// @notice An event emitted once a new wrapped token is deployed by the contract
    event WrappedTokenDeployed(uint8 sourceChain, bytes nativeToken, address wrappedToken);

    function initRouter(uint8 _chainId, address _albtToken) external;
    function nativeToWrappedToken(uint8 _chainId, bytes memory _nativeToken) external view returns (address);
    function wrappedToNativeToken(address _wrappedToken) external view returns (LibRouter.NativeTokenWithChainId memory);
    function hashesUsed(uint8 _chainId, bytes32 _ethHash) external view returns (bool);
    function albtToken() external view returns (address);
    function lock(uint8 _targetChain, address _nativeToken, uint256 _amount, bytes memory _receiver) external;

    function lockWithPermit(
        uint8 _targetChain,
        address _nativeToken,
        uint256 _amount,
        bytes memory _receiver,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function unlock(
        uint8 _sourceChain,
        bytes memory _transactionId,
        address _nativeToken,
        uint256 _amount,
        address _receiver,
        bytes[] calldata _signatures
    ) external;

    function burn(address _wrappedToken, uint256 _amount, bytes memory _receiver) external;

    function burnWithPermit(
        address _wrappedToken,
        uint256 _amount,
        bytes memory _receiver,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function burnAndTransfer(uint8 _targetChain, address _wrappedToken, uint256 _amount, bytes memory _receiver) external;

    function burnAndTransferWithPermit(
        uint8 _targetChain,
        address _wrappedToken,
        uint256 _amount,
        bytes memory _receiver,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function mint(
        uint8 _nativeChain,
        bytes memory _nativeToken,
        bytes memory _transactionId,
        uint256 _amount,
        address _receiver,
        bytes[] calldata _signatures,
        WrappedTokenParams memory _tokenParams
    ) external;
}