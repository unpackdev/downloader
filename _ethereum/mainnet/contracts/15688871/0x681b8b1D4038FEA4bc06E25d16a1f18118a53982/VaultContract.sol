// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "./FlashLoanReceiverBase.sol";
import "./Interfaces.sol";
import "./Libraries.sol";
import "./Interfaces.sol";
import "./console.sol";
import "./ISwapRouter.sol";

contract VaultContract is FlashLoanReceiverBase {
    using SafeMath for uint256;
    address public Owner;
    address public GasWallet;
    address constant swapRouterAddress =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant swapRouterAddressV2 =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    ILendingPool LendingPoolContract =
        ILendingPool(address(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9));
    IERC20 token = IERC20(usdc);

    address _ColletralToken;
    address _BorrowToken;
    address _Borrower;
    uint24 _poolfee;
    uint256 _amountIn;
    bool _recieveAToken;

    constructor(ILendingPoolAddressesProvider _addressProvider)
        public
        FlashLoanReceiverBase(_addressProvider)
    {
        Owner = 0x793457308e1Cb6436AeEeFA09B19822AFB50Bcd1;
        GasWallet = 0xb8da1e0a8CCEa338A331e3ed8853194d166eaA00;
    }

    function swapExactInputSingle(
        address Token_In,
        address Token_Out,
        uint24 Pool_Fee,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public returns (uint256 amountOut) {
        ISwapRouter swapRouter = ISwapRouter(swapRouterAddress);
        TransferHelper.safeApprove(Token_In, swapRouterAddress, amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: Token_In,
                tokenOut: Token_Out,
                fee: Pool_Fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap
        amountOut = swapRouter.exactInputSingle(params);
    }

    function FlashLoanCall(address asset, uint256 amount) public {
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = asset;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;
        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    function LiquidateAcount(
        uint256 amountIn, // Amount to Pay For Liquidation
        uint24 Pool_Fee,
        address ColletralToken,
        address BorrowToken,
        address Borrower,
        bool recieveAToken
    ) external {
        _ColletralToken = ColletralToken;
        _BorrowToken = BorrowToken;
        _Borrower = Borrower;
        _amountIn = amountIn;
        _recieveAToken = recieveAToken;
        _poolfee = Pool_Fee;
        FlashLoanCall(BorrowToken, amountIn);
    }

    function changeGasWallet(address new_gas_wallet) public {
        require(msg.sender == Owner, "Invalid Owner");
        GasWallet = new_gas_wallet;
    }

    function transferOwnership(address new_owner_wallet) public {
        require(msg.sender == Owner, "Invalid Owner");
        Owner = new_owner_wallet;
    }

    function emergencyWithdraw(address token_address) external {
        require(msg.sender == Owner, "Invalid Owner");

        IERC20 tokenContract = IERC20(token_address);

        TransferHelper.safeTransfer(
            token_address,
            Owner,
            tokenContract.balanceOf(address(this))
        );
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // Loan agya
        // Liquidation k borrow asset pay krna hai
        // Colletral asset ko swap krna hai borrow asset/ flash k liya
        if (
            IERC20(_BorrowToken).allowance(
                address(this),
                address(LendingPoolContract)
            ) < _amountIn
        ) {
            TransferHelper.safeApprove(
                _BorrowToken,
                address(LendingPoolContract),
                _amountIn
            );
        }


        LendingPoolContract.liquidationCall(
            _ColletralToken,
            _BorrowToken,
            _Borrower,
            _amountIn,
            _recieveAToken
        );
        uint256 balanceColletral = IERC20(_ColletralToken).balanceOf(
            address(this)
        );

        console.log('Collertral Balance', balanceColletral);
        uint256 SwapResult = swapExactInputSingle(
            _ColletralToken,
            _BorrowToken,
            _poolfee,
            balanceColletral,
            0
        );

        console.log("Borrow Amount With Fee: ", amounts[0], " fee: " , premiums[0]);
        console.log("Borrow Amount After Swap: ", SwapResult);

        require(
            amounts[0].add(premiums[0]) < SwapResult,
            "Trade Not Profitable"
        );
        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(
                address(LendingPoolContract),
                amountOwing
            );
        }

        return true;
    }
}
