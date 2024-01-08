//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

interface IRouterProxy {

    /// @notice An event emitted when setting the fee amount for a token
    event FeeSet(address token_, uint256 oldFee_, uint256 newFee_);
    /// @notice An event emitted when setting a new Router address
    event RouterAddressSet(address oldRouter_, address newRouter_);
    /// @notice An event emitted when setting a new ALBT address
    event AlbtAddressSet(address oldAlbt_, address newAlbt_);
    /// @notice An event emitted once a Lock transaction is proxied
    event ProxyLock(address feeToken_, uint8 targetChain_, address nativeToken_, uint256 amount_, bytes receiver_);
    /// @notice An event emitted once a Burn transaction is proxied
    event ProxyBurn(address feeToken_, address wrappedToken_, uint256 amount_, bytes receiver_);
    /// @notice An event emitted once a BurnAndTransfer transaction is proxied
    event ProxyBurnAndTransfer(address feeToken_, uint8 targetChain_, address wrappedToken_, uint256 amount_, bytes receiver_);
    /// @notice An event emitted when the proxy collects a fee
    event FeeCollected(address token_, uint256 amount_);
    /// @notice An event emitted when contract's tokens are sent to the owner
    event TokensClaimed(address token_, uint256 amount_);
    /// @notice An event emitted when the contract's currency is sent to the owner
    event CurrencyClaimed(uint256 amount);
    /// @notice An event emitted when currency is manually sent to the bridge
    event BridgeAirdrop(uint256 amount_);

    function setFee(address tokenAddress_, uint256 fee_) external;

    function setRouterAddress(address routerAddress_) external;

    function setAlbtToken(address albtToken_) external;

    function lock(address feeToken_, uint8 targetChain_, address nativeToken_, uint256 amount_, bytes calldata receiver_) external payable;

    function lockWithPermit(
        address feeToken_,
        uint8 targetChain_,
        address nativeToken_,
        uint256 amount_,
        bytes calldata receiver_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external payable;

    function burn(address feeToken_, address wrappedToken_, uint256 amount_, bytes calldata receiver_) external payable;

    function burnWithPermit(
        address feeToken_,
        address wrappedToken_,
        uint256 amount_,
        bytes calldata receiver_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external payable;

    function burnAndTransfer(address feeToken_, uint8 targetChain_, address wrappedToken_, uint256 amount_, bytes calldata receiver_)
        external payable;

    function burnAndTransferWithPermit(
        address feeToken_,
        uint8 targetChain_,
        address wrappedToken_,
        uint256 amount_,
        bytes calldata receiver_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external payable;

    function claimTokens(address tokenAddress_) external;
    function claimCurrency() external;

    function bridgeAirdrop() external payable;

}
