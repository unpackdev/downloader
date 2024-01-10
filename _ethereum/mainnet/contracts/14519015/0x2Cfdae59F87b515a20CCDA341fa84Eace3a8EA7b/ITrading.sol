// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20.sol";

interface ITrading {
    /*///////////////////////////////////////////////////////////////
                            Enums
    //////////////////////////////////////////////////////////////*/
    enum ActionType {
        /// @notice supply tokens
        Deposit,
        /// @notice borrow tokens
        Withdraw,
        /// @notice transfer balance between accounts
        Transfer,
        /// @notice buy an amount of some token (externally)
        Buy,
        /// @notice sell an amount of some token (externally)
        Sell,
        /// @notice trade tokens against another account
        Trade,
        /// @notice liquidate an undercollateralized or expiring account
        Liquidate,
        /// @notice use excess tokens to zero-out a completely negative account
        Vaporize,
        /// @notice send arbitrary data to an address
        Call
    }

    enum AssetDenomination {
        Wei // the amount is denominated in wei
    }

    enum AssetReference {
        Delta // the amount is given as a delta from the current value
    }

    /*///////////////////////////////////////////////////////////////
                            Structs
    //////////////////////////////////////////////////////////////*/
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 guaranteedAmount;
        uint256 flags;
        address referrer;
        bytes permit;
    }

    struct Val {
        uint256 value;
    }
    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Info {
        address owner; // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/
    event StartBalance(uint256 balance);
    event EndBalance(uint256 balance);
    event ZRXBeforeDAIBalance(uint256 balance);
    event ZRXAfterDAIBalance(uint256 balance);
    event ZRXBeforeWETHBalance(uint256 balance);
    event ZRXAfterWETHBalance(uint256 balance);
    event OneInchBeforeDAIBalance(uint256 balance);
    event OneInchAfterDAIBalance(uint256 balance);
    event OneInchBeforeWETHBalance(uint256 balance);
    event OneInchAfterWETHBalance(uint256 balance);
    event FlashTokenBeforeBalance(uint256 balance);
    event FlashTokenAfterBalance(uint256 balance);
}
