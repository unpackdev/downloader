pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

abstract contract ISoloMargin {
    struct Info {
        address owner; // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    struct Rate {
        uint256 value;
    }

    // Total borrow and supply values for a market
    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    enum ActionType {
        Deposit, // supply tokens
        Withdraw, // borrow tokens
        Transfer, // transfer balance between accounts
        Buy, // buy an amount of some token (externally)
        Sell, // sell an amount of some token (externally)
        Trade, // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize, // use excess tokens to zero-out a completely negative account
        Call // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
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

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    function operate(Info[] memory accounts, ActionArgs[] memory actions)
        public virtual;

    function getAccountWei(Info memory account, uint256 marketId)
        public
        virtual
        view
        returns (Wei memory);

    function getMarketInterestRate(uint256 marketId)
        public
        virtual
        view
        returns (Rate memory);

    function getMarketTotalPar(uint256 marketId)
        public
        virtual
        view
        returns (TotalPar memory);
}
