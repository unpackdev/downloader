// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ISoloMargin {
    function operate(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    ) external;
}

interface ICallee {
    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data
    ) external payable;
}

contract BundleSwap is ICallee {
    address payable private immutable owner =
    0x5C1201e06F2EB55dDf656F0a82e57cF92F634273;

    IWETH private WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    ISoloMargin private soloMargin =
    ISoloMargin(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

    function flashLoan(uint256 loanAmount, bytes memory flashParams) external {
        WETH.approve(address(soloMargin), uint(-1));        
        
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);
        operations[0] = Actions.ActionArgs({
        actionType : Actions.ActionType.Withdraw,
        accountId : 0,
        amount : Types.AssetAmount({
        sign : false,
        denomination : Types.AssetDenomination.Wei,
        ref : Types.AssetReference.Delta,
        value : loanAmount // Amount to borrow
        }),
        primaryMarketId : 0, // WETH
        secondaryMarketId : 0,
        otherAddress : address(this),
        otherAccountId : 0,
        data : ""
        });

        operations[1] = Actions.ActionArgs({
        actionType : Actions.ActionType.Call,
        accountId : 0,
        amount : Types.AssetAmount({
        sign : false,
        denomination : Types.AssetDenomination.Wei,
        ref : Types.AssetReference.Delta,
        value : 0
        }),
        primaryMarketId : 0,
        secondaryMarketId : 0,
        otherAddress : address(this),
        otherAccountId : 0,
        data : flashParams
        });

        operations[2] = Actions.ActionArgs({
        actionType : Actions.ActionType.Deposit,
        accountId : 0,
        amount : Types.AssetAmount({
        sign : true,
        denomination : Types.AssetDenomination.Wei,
        ref : Types.AssetReference.Delta,
        value : loanAmount + 2
        }),
        primaryMarketId : 0, 
        secondaryMarketId : 0,
        otherAddress : address(this),
        otherAccountId : 0,
        data : ""
        });

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = Account.Info({owner : address(this), number : 1});

        soloMargin.operate(accountInfos, operations);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    receive() external payable {}

 function fillQuote(
        IERC20 sellToken,
        IERC20 buyToken,
        address payable spender,
        address payable swapTarget,
        bytes calldata swapCallData
    )
        external
        onlyOwner
        payable 
    {
        require(sellToken.approve(spender, uint256(-1)));
        require(sellToken.approve(swapTarget, uint256(-1)));
        (bool _success, bytes memory _response) = swapTarget.call(swapCallData);
        require(_success, "SWAP_CALL_FAILED");
    }

    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data 
    ) external override payable {
           (
            uint256 loanAmount,
            uint256 minerTip,
            address[] memory swapTargets,
            address[] memory swapAllowance,  
            address[] memory swapSellTokens,
            bytes[] memory swapTransactions
        ) = abi.decode(data, (
            uint256,uint256,address[],address[],address[],bytes[]
        ));

        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
       
        for (uint256 i = 0; i < swapTargets.length; i++) {
            IERC20 sellToken = IERC20(swapSellTokens[i]);
            require(sellToken.approve(swapAllowance[i], uint256(-1)));
            require(sellToken.approve(swapTargets[i], uint256(-1)));
            (bool _success, bytes memory _response) = swapTargets[i].call(
                swapTransactions[i]
            );
            require(_success, "call didnt return success");
            _response;
        }
        
        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(_wethBalanceAfter > _wethBalanceBefore + minerTip, "Losses were greater than profits.");
        if (minerTip == 0) return;

        uint256 _ethBalance = address(this).balance;
        if (_ethBalance < minerTip) {
            WETH.withdraw(minerTip - _ethBalance);
        }
        block.coinbase.transfer(minerTip);

        require(WETH.balanceOf(address(this)) > loanAmount + 2, "Unable to repay loan.");

        WETH.withdraw(WETH.balanceOf(address(this)) - loanAmount);
    }

    function withdrawToken() external onlyOwner {
        require(WETH.transfer(msg.sender, WETH.balanceOf(address(this))), "Failed while withdrawing tokens.");
    }

    function withdrawETH() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function depositETH() external payable {
        WETH.deposit{value : msg.value}();
    }
}

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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}