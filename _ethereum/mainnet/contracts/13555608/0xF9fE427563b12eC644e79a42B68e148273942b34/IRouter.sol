// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./LibRouter.sol";

struct WrappedTokenParams {
    string name;
    string symbol;
    uint8 decimals;
}

interface IRouter {
    /// @notice An event emitted once a Lock transaction is executed
    event Lock(
        uint256 targetChain,
        address token,
        bytes receiver,
        uint256 amount,
        uint256 serviceFee
    );
    /// @notice An event emitted once a Burn transaction is executed
    event Burn(
        uint256 targetChain,
        address token,
        uint256 amount,
        bytes receiver
    );
    /// @notice An event emitted once an Unlock transaction is executed
    event Unlock(
        uint256 sourceChain,
        bytes transactionId,
        address token,
        uint256 amount,
        address receiver,
        uint256 serviceFee
    );
    /// @notice An even emitted once a Mint transaction is executed
    event Mint(
        uint256 sourceChain,
        bytes transactionId,
        address token,
        uint256 amount,
        address receiver
    );
    /// @notice An event emitted once a new wrapped token is deployed by the contract
    event WrappedTokenDeployed(
        uint256 sourceChain,
        bytes nativeToken,
        address wrappedToken
    );
    /// @notice An event emitted once a native token is updated
    event NativeTokenUpdated(address token, uint256 serviceFee, bool status);

    function initRouter() external;

    function hashesUsed(bytes32 _ethHash) external view returns (bool);

    function nativeTokensCount() external view returns (uint256);

    function nativeTokenAt(uint256 _index) external view returns (address);

    function lock(
        uint256 _targetChain,
        address _nativeToken,
        uint256 _amount,
        bytes memory _receiver
    ) external;

    function lockWithPermit(
        uint256 _targetChain,
        address _nativeToken,
        uint256 _amount,
        bytes memory _receiver,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function unlock(
        uint256 _sourceChain,
        bytes memory _transactionId,
        address _nativeToken,
        uint256 _amount,
        address _receiver,
        bytes[] calldata _signatures
    ) external;

    function burn(
        uint256 _targetChain,
        address _wrappedToken,
        uint256 _amount,
        bytes memory _receiver
    ) external;

    function burnWithPermit(
        uint256 _targetChain,
        address _wrappedToken,
        uint256 _amount,
        bytes memory _receiver,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function mint(
        uint256 _sourceChain,
        bytes memory _transactionId,
        address _wrappedToken,
        address _receiver,
        uint256 _amount,
        bytes[] calldata _signatures
    ) external;

    function deployWrappedToken(
        uint256 _sourceChain,
        bytes memory _nativeToken,
        WrappedTokenParams memory _tokenParams
    ) external;

    function updateNativeToken(
        address _nativeToken,
        uint256 _serviceFee,
        bool _status
    ) external;
}
