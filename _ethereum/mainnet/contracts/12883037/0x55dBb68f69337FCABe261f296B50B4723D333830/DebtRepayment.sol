pragma solidity 0.5.15;
pragma experimental ABIEncoderV2;

library Types {
    enum AssetDenomination {
        Wei,
        Par
    }
    enum AssetReference {
        Delta,
        Target
    }
    struct AssetAmount {
        bool sign;
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }
}

library Account {
    struct Info {
        address owner;
        uint256 number;
    }
}

library Actions {
    enum ActionType {
        Deposit,
        Withdraw,
        Transfer,
        Buy,
        Sell,
        Trade,
        Liquidate,
        Vaporize,
        Call
    }
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }
}

interface ISoloMargin {
    function operate(
        Account.Info[] calldata accounts,
        Actions.ActionArgs[] calldata actions
    ) external;
}

// The interface for a contract to be callable after receiving a flash loan
interface ICallee {
    function callFunction(
        address sender,
        Account.Info calldata accountInfo,
        bytes calldata data
    ) external;
}

contract DebtRepayment is ICallee {
    /**
     * Debt repayment function
     * Called when c-ratio is below a certain point
     * And SNX collateral is locked
     * Takes flash loan from dydx in USDC
     * Calls callFunction in xSNXAdmin.sol
     */
    function repayDebt(uint256 loanAmount, uint256 snxAmount) public {
        ISoloMargin soloMargin = ISoloMargin(
            0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e
        );
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Withdraw,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: loanAmount // Amount to borrow
            }),
            primaryMarketId: 2, // USDC
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });

        operations[1] = Actions.ActionArgs({
            actionType: Actions.ActionType.Call,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: 0
            }),
            primaryMarketId: 2,
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: abi.encode(
                msg.sender,
                loanAmount,
                snxAmount // snx amount to swap to repay the loan
            )
        });

        operations[2] = Actions.ActionArgs({
            actionType: Actions.ActionType.Deposit,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: true,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: loanAmount + 2 // Repayment amount with 2 wei fee
            }),
            primaryMarketId: 2, // USDC
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = Account.Info({owner: address(this), number: 1});

        soloMargin.operate(accountInfos, operations);
    }

    function() external payable {}
}
