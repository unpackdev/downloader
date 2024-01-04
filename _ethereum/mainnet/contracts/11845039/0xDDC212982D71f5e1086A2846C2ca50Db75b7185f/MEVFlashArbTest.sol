pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "./console.sol";
import "./Ownable.sol";
import "./Constants.sol";
import "./IUniswapV2Router02.sol";
import "./DydxDependencies.sol";

contract MEVFlashArbTest is ICallee {
    // The WETH token contract, since we're assuming we want a loan in WETH
    IWETH private WETH = IWETH(Constants.WETH_MAINNET);
    // The dydx Solo Margin contract, as can be found here:
    // https://github.com/dydxprotocol/solo/blob/master/migrations/deployed.json
    ISoloMargin private soloMargin =
        ISoloMargin(Constants.DYDX_SOLOMARGIN_MAINNET);

    constructor() public {
        // Give infinite approval to dydx to withdraw WETH on contract deployment,
        // so we don't have to approve the loan repayment amount (+2 wei) on each call.
        // The approval is used by the dydx contract to pay the loan back to itself.
        WETH.approve(address(soloMargin), uint256(-1));
    }

    // DyDx flash loan entry point for NodeJS bot
    function executeMEVArb(uint256 loanAmount) external {
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
            primaryMarketId: 0, // WETH
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
            primaryMarketId: 0,
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: abi.encode(
                // Replace or add any additional variables that you want
                // to be available to the receiver function
                msg.sender,
                loanAmount
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
            primaryMarketId: 0, // WETH
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = Account.Info({owner: address(this), number: 1});

        soloMargin.operate(accountInfos, operations);
    }

    // This is the function called by dydx after giving us the loan
    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data
    ) external override {
        // Decode the passed variables from the data object
        (
            // This must match the variables defined in the Call object above
            address payable actualSender,
            uint256 loanAmount
        ) = abi.decode(data, (address, uint256));

        // We now have a WETH balance of loanAmount. The logic for what we
        // want to do with it goes here. The code below is just there in case
        // it's useful.
        // TODO: add uniswap (WETH to DAI) and sushiswap (DAI TO WETH) logic here

        // It can be useful for debugging to have a verbose error message when
        // the loan can't be paid, since dydx doesn't provide one
        require(
            WETH.balanceOf(address(this)) > loanAmount + 2,
            "CANNOT REPAY LOAN"
        );
    }

    // manual withdraw of all ETH from contract
    // Security note: This contract should only contain funds during use, all other times keep balance to nil
    function withdrawAllETH() public payable {
        // withdraw all ETH
        msg.sender.call{value: address(this).balance}("");
    }

    // manual withdraw of all of the specified ERC20 from contract
    function withdrawERC20(address _erc20Asset) public payable {
        // withdraw all x ERC20 tokens
        IERC20(_erc20Asset).transfer(
            msg.sender,
            IERC20(_erc20Asset).balanceOf(address(this))
        );
    }

    // payable for the contract to receive ETH / WETH
    receive() external payable {}
}
