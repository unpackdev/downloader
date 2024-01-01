// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./IWrappedToken.sol";
import "./IMaxApyVault.sol";

import "./SafeTransferLib.sol";

/*KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
KKKKK0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KKKKKKK
KK0dcclllllllllllllllllllllllllllllccccccccccccccccccclx0KKK
KOc,dKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNNNNNNNNNXOl';xKK
Kd'oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX; ,kK
Ko'xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc .dK
Ko'dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc .oK
Kd'oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc .oK
KO:,xXWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc .oK
KKOl,',;;,,,,,,;;,,,,,,,;;cxXMMMMMMMMMMMMMMMMMMMMMMMMMNc .oK
KKKKOoc;;;;;;;;;;;;;;;;;;;,.cXMMMMMMMMMMMMMMMMMMMMMMMMNc .oK
KKKKKKKKKKKKKKKKKKKK00O00K0:,0MMMMMMMMMMMMMMMMMMMMMMMMNc .oK
KKKKKKKKKKKKKKKKKKklcccccld;,0MMMMMMMMMMMMMMMMMMMMMMMMNc .oK
KKKKKKKKKKKKKKKKkl;ckXNXOc. '0MMMMMMMMMMMMMMMMMMMMMMMMNc .oK
KKKKKKKKKKKKKKkc;l0WMMMMMX; .oKNMMMMMMMMMMMMMMMMMMMMMMNc .oK
KKKKKKKKKKKKkc;l0WMMMMMMMWd.  .,lddddddxONMMMMMMMMMMMMNc .oK
KKKKKKKKKKkc;l0WMMMMMMMMMMWOl::;'.  .....:0WMMMMMMMMMMNc .oK
KKKKKKK0xc;o0WMMMMMMMMMMMMMMMMMWNk'.;xkko'lNMMMMMMMMMMNc .oK
KKKKK0x:;oKWMMMMMMMMMMMMMMMMMMMMMWd..lKKk,lNMMMMMMMMMMNc .oK
KKK0x:;oKWMMMMMMMMMMMMMMMMMMMMMMWO,  c0Kk,lNMMMMMMMMMMNc .oK
KKx:;dKWMMMMMMMMMMMMMMMMMMMMMWN0c.  ;kKKk,lNMMMMMMMMMMNc .oK
Kx,:KWMMMMMMMMMMMMMMMMMMMMMW0c,.  'oOKKKk,lNMMMMMMMMMMNc .oK
Ko'xMMMMMMMMMMMMMMMMMMMMMW0c.   'oOKKKKKk,lNMMMMMMMMMMNc .oK
Ko'xMMMMMMMMMMMMMMMMMMMW0c.  ':oOKKKKKKKk,lNMMMMMMMMMMNc .oK
Ko'xMMMMMMMMMMMMMMMMMW0l.  'oOKKKKKKKKKKk,cNMMMMMMMMMMNc .oK
Ko'xMMMMMMMMMMMMMMMW0l.  'oOKKKKKKKKKKKKk,lNMMMMMMMMMMNc .oK
Ko'dWMMMMMMMMMMMMW0l.  'oOKKKKKKKKKKKKKKk,cNMMMMMMMMMMX: .oK
KO:,xXNWWWWWWWWNOl.  'oOKKKKKKKKKKKKKKKK0c,xNMMMMMMMMNd. .dK
KKOl''',,,,,,,,..  'oOKKKKKKKKKKKKKKKKKKKOl,,ccccccc:'  .c0K
KKKKOoc:;;;;;;;;:ldOKKKKKKKKKKKKKKKKKKKKKKKkl;'......',cx0KK
KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0OOOOOOO0KKK*/

/// @notice Helper contract to interact with a MaxApy Vault utilizing the chain's native token the protocol
/// has been deployed to
/// @author MaxApy
contract WrappedTokenGateway {
    using SafeTransferLib for address;

    ////////////////////////////////////////////////////////////////
    ///                       CONSTANTS                          ///
    ////////////////////////////////////////////////////////////////

    /// @notice The chain's wrapped native token
    IWrappedToken public immutable wrappedToken;
    /// @notice The MaxApy vault linked to this Gateway contract
    IMaxApyVault public immutable vault;

    ////////////////////////////////////////////////////////////////
    ///                        ERRORS                            ///
    ////////////////////////////////////////////////////////////////
    error InvalidZeroValue();
    error FailedNativeTransfer();
    error ReceiveNotAllowed();

    ////////////////////////////////////////////////////////////////
    ///                        EVENTS                            ///
    ////////////////////////////////////////////////////////////////

    /// @notice Emitted on native vault deposits
    event DepositNative(address indexed recipient, uint256 shares, uint256 amount);

    /// @notice Emitted on native vault withdrawals
    event WithdrawNative(address indexed recipient, uint256 shares, uint256 amount);

    /// @dev `keccak256(bytes("DepositNative(address,uint256,uint256)"))`.
    uint256 internal constant _DEPOSIT_NATIVE_EVENT_SIGNATURE =
        0x6bb902f8baf2580ae3dae24e58f4b874ecca85152076af921bfd172dce1c7e28;

    /// @dev `keccak256(bytes("WithdrawNative(address,uint256,uint256)"))`.
    uint256 internal constant _WITHDRAW_NATIVE_EVENT_SIGNATURE =
        0x5cb35f4e7dbc40dd34f0d58cec4f5548fc47638cb46d7964e4f07c48e97e4c7d;

    ////////////////////////////////////////////////////////////////
    ///                      CONSTRUCTOR                         ///
    ////////////////////////////////////////////////////////////////

    /// @notice Create the WrappedToken Gateway
    /// @param _wrappedToken The wrapped token of the chain the contract will be deployed to
    /// @param _vault The MaxApy vault linked to this Gateway contract
    constructor(IWrappedToken _wrappedToken, IMaxApyVault _vault) {
        wrappedToken = _wrappedToken;
        vault = _vault;
        address(_wrappedToken).safeApprove(address(_vault), type(uint256).max);
    }

    ////////////////////////////////////////////////////////////////
    ///                 GATEWAY CORE LOGIC                       ///
    ////////////////////////////////////////////////////////////////

    /// @notice  Deposits `msg.value` of `_wrappedToken`, issuing shares to `recipient`
    /// @param recipient The address to issue the shares from MaxApy's Vault to
    function depositNative(address recipient) external payable returns (uint256) {
        // Cache `wrappedToken` and `vault` due to assembly's immutable access restrictions
        address cachedWrappedToken = address(wrappedToken);
        address cachedVault = address(vault);

        assembly ("memory-safe") {
            // Check if `msg.value` is 0
            if iszero(callvalue()) {
                // Throw the `InvalidZeroValue()` error
                mstore(0x00, 0xef7a63d0)
                revert(0x1c, 0x04)
            }

            // Cache the free memory pointer
            let m := mload(0x40)

            // Store Wrapped Token's `deposit()` function selector:
            // `bytes4(keccak256("deposit()"))`
            mstore(0x00, 0xd0e30db0)

            // Deposit native token in exchange for wrapped native token
            // Note: using some wrapped tokens' fallback function for deposit allows saving the previous
            // selector loading into memory to call wrappedToken's `deposit()`.
            // This is avoided due to some chain's wrapped native versions not allowing such behaviour
            if iszero(
                call(
                    gas(), // Remaining amount of gas
                    cachedWrappedToken, // Address of `wrappedToken`
                    callvalue(), // `msg.value`
                    0x1c, // byte offset in memory where calldata starts
                    0x24, // size of the calldata to copy
                    0x00, // byte offset in memory to store the return data
                    0x00 // size of the return data
                )
            ) {
                // Throw the `WrappedTokenDepositFailed()` error
                mstore(0x00, 0x22cd2378)
                revert(0x1c, 0x04)
            }

            // Store MaxApy vault's `deposit()` function selector:
            // `bytes4(keccak256("deposit(uint256,address)"))`
            mstore(0x00, 0x6e553f65)
            mstore(0x20, callvalue()) // Append the `amount` argument
            mstore(0x40, recipient) // Append the `recipient` argument

            // Deposit into MaxApy vault
            if iszero(
                call(
                    gas(), // Remaining amount of gas
                    cachedVault, // Address of `vault`
                    0, // `msg.value`
                    0x1c, // byte offset in memory where calldata starts
                    0x44, // size of the calldata to copy
                    0x00, // byte offset in memory to store the return data
                    0x20 // size of the return data
                )
            ) {
                // If call failed, throw the error thrown in the previous `call`
                revert(0x00, 0x04)
            }

            // Emit the `DepositNative` event
            mstore(0x20, callvalue())
            log2(0x00, 0x40, _DEPOSIT_NATIVE_EVENT_SIGNATURE, recipient)

            mstore(0x40, m) // Restore the free memory pointer

            return(0x00, 0x20) // Return `shares` value stored in 0x00 from previous from call's
        }
    }

    /// @notice Withdraws the calling account's tokens from MaxApy's Vault, redeeming
    /// amount `shares` for the corresponding amount of tokens, which will be transferred to
    /// `recipient` in the form of the chain's native token
    /// @param shares How many shares to try and redeem for tokens
    /// @param recipient The address to issue the shares from MaxApy's Vault to
    /// @param maxLoss The maximum acceptable loss to sustain on withdrawal. Up to loss specified amount of shares may be
    /// burnt to cover losses on withdrawal
    function withdrawNative(uint256 shares, address recipient, uint256 maxLoss) external returns (uint256) {
        // Cache `wrappedToken` and `vault` due to assembly's immutable access restrictions
        address cachedWrappedToken = address(wrappedToken);
        address cachedVault = address(vault);

        assembly ("memory-safe") {
            // Check if `shares` passed by user is `type(uint256).max`
            if eq(shares, not(0)) {
                // Store `vault`'s `balanceOf()` function selector:
                // `bytes4(keccak256("balanceOf(address)"))`
                mstore(0x00, 0x70a08231)
                mstore(0x20, caller()) // append the `owner` argument as `msg.sender`

                // query `vault`'s `msg.sender` `balanceOf()`
                if iszero(
                    staticcall(
                        gas(), // Remaining amount of gas
                        cachedVault, // Address of `vault`
                        0x1c, // byte offset in memory where calldata starts
                        0x24, // size of the calldata to copy
                        0x00, // byte offset in memory to store the return data
                        0x20 // size of the return data
                    )
                ) {
                    // Revert if balance query fails
                    revert(0x00, 0x04)
                }

                // Store `msg.sender`'s balance returned by staticcall into `shares`
                shares := mload(0x00)
            }
        }

        // Transfer caller shares
        address(vault).safeTransferFrom(msg.sender, address(this), shares);

        uint256 amountWithdrawn;

        assembly ("memory-safe") {
            // Cache the free memory pointer
            let m := mload(0x40)

            // Store `vault`'s `withdraw()` function selector:
            // `bytes4(keccak256("withdraw(address)"))`
            mstore(0x00, 0xe63697c8)
            mstore(0x20, shares) // append the `shares` argument
            mstore(0x40, address()) // append the `address(this)` argument
            mstore(0x60, maxLoss) // append the `maxLoss` argument

            // Withdraw from MaxApy vault
            if iszero(
                call(
                    gas(), // Remaining amount of gas
                    cachedVault, // Address of `vault`
                    0, // `msg.value`
                    0x1c, // byte offset in memory where calldata starts
                    0x64, // size of the calldata to copy
                    0x00, // byte offset in memory to store the return data
                    0x20 // size of the return data
                )
            ) {
                // If call failed, throw the error thrown in the previous `call`
                revert(0x00, 0x04)
            }

            // Store `amountWithdrawn` returned by the previous call to `withdraw()`
            amountWithdrawn := mload(0x00)

            // Store `wrappedToken`'s `withdraw()` function selector:
            // `bytes4(keccak256("withdraw(uint256)"))`
            mstore(0x00, 0x2e1a7d4d)
            mstore(0x20, amountWithdrawn) // append the `amountWithdrawn` argument

            // Withdraw from wrapped token
            if iszero(
                call(
                    gas(), // Remaining amount of gas
                    cachedWrappedToken, // Address of `vault`
                    0, // `msg.value`
                    0x1c, // byte offset in memory where calldata starts
                    0x24, // size of the calldata to copy
                    0x00, // byte offset in memory to store the return data
                    0x20 // size of the return data
                )
            ) {
                // If call failed, throw the error thrown in the previous `call`
                revert(0x00, 0x04)
            }

            // Transfer native token back to user
            if iszero(call(gas(), recipient, amountWithdrawn, 0x00, 0x00, 0x00, 0x00)) {
                // If call failed, throw the `FailedNativeTransfer()` error
                mstore(0x00, 0x3c3f4130)
                revert(0x1c, 0x04)
            }

            // Emit the `WithdrawNative` event
            mstore(0x00, shares)
            mstore(0x20, amountWithdrawn)
            log2(0x00, 0x40, _WITHDRAW_NATIVE_EVENT_SIGNATURE, recipient)

            mstore(0x60, 0) // Restore the zero slot
            mstore(0x40, m) // Restore the free memory pointer

            return(0x20, 0x20) // Return `amountWithdrawn` value stored in 0x00 from previous from call's
        }
    }

    ////////////////////////////////////////////////////////////////
    ///                 RECEIVE()  function                      ///
    ////////////////////////////////////////////////////////////////

    /// @notice Receive function to accept native transfers
    /// @dev Note only the chain's wrapped token will be able to perform native token transfers
    /// to this contract
    receive() external payable {
        // Cache `wrappedToken` due to assembly immutable access restrictions
        address cachedWrappedToken = address(wrappedToken);

        assembly {
            // Check if caller is not the `wrappedToken`
            if iszero(eq(caller(), cachedWrappedToken)) {
                // Throw the `ReceiveNotAllowed()` error
                mstore(0x00, 0xcb263c3f)
                revert(0x1c, 0x04)
            }
        }
    }
}
