pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";

import "./FundsManager.sol";
import "./Adminable.sol";

import "./ConstantAddressesMainnet.sol";

import "./DSMath.sol";
import "./SafeMath.sol";

import "./FlashLoanReceiverBase.sol";
import "./FlashloanDyDx.sol";

// **INTERFACES**
import "./ICToken.sol";
import "./ILendingPool.sol";
import "./IDfWalletFactory.sol";
import "./IDfWallet.sol";
import "./IToken.sol";
import "./IComptrollerLensInterface.sol";
import "./IComptroller.sol";
import "./IWeth.sol";
import "./IDfProxy.sol";


contract DfFinanceDeposits is
    Initializable,
    DSMath,
    ConstantAddresses,
    FundsManager,
    Adminable,
    FlashLoanReceiverBase,
    FlashloanDyDx
{
    using UniversalERC20 for IToken;
    using SafeMath for uint256;


    // ** STRUCTS **

    struct FeeScheme {
        address[] partners;
        uint32[] percents;
        uint32 fee;
        bool isEnabled;
    }

    struct UserData {
        address owner;
        uint256 deposit; // in dai
        uint64 compClaimed;
        uint64 compClaimedinUSD; // 6 decimals
        uint64 activeFeeScheme; // 0 - fee scheme is disabled
        uint64 depositUSDC;
        // next pack
        uint96 depositETH;
        uint64 depositWBTC;
        uint96 gap;
    }

    struct FlashloanData {
        address dfWallet;
        address token;
        address cToken;
        uint256 deposit;
        uint256 amountFlashLoan;
    }

    struct FlashloanDataDyDxEth {
        address dfWallet;
        address token;
        address cToken;
        uint256 deposit;
        uint256 debt;
        uint256 ethAmountFlashLoan;
    }

    // ** ENUMS **

    enum OP {
        UNKNOWN,
        DEPOSIT,
        WITHDRAW,
        DEPOSIT_USING_DYDX_ETH,
        WITHDRAW_USING_DYDX_ETH
    }

    enum FlashloanProvider {
        DYDX,
        AAVE,
        ADDRESS
    }


    // ** PUBLIC STATES **

    IDfWalletFactory public dfWalletFactory;

    uint256 private DELETED_fee; // DELETED state

    mapping(address => UserData) public wallets;


    // ** PRIVATE STATES **

    // partner => token => balance
    mapping(address => mapping(address => uint256)) private DELETED_partnerBalances;    // DELETED state

    FeeScheme[] private DELETED_feeSchemes; // DELETED state

    OP private state;


    // ** ADDED STATES **

    // withdraw min ratio from cToken to Token conversion
    uint256 public withdrawMinRatio;


    // ** EVENTS **

    event DfOpenDeposit(address indexed dfWallet, uint256 amount);
    event DfAddDeposit(address indexed dfWallet, uint256 amount);
    event DfCloseDeposit(address indexed dfWallet, uint256 amount, address token);
    event DfPartiallyCloseDeposit(
        address indexed dfWallet, address indexed tokenReceiver, uint256 amountDAI, uint256 tokensSent,  uint256 deposit
    );


    // ** INITIALIZER – Constructor for Upgradable contracts **

    function initialize() public initializer {
        Adminable.initialize();  // Initialize Parent Contract
        // FundsManager.initialize();  // Init in Adminable

        withdrawMinRatio = 0.995 * 1e18;

        // dfWalletFactory = IDfWalletFactory(0);
    }


    // ** ONLY_OWNER functions **

    function setDfWalletFactory(address _dfWalletFactory) public onlyOwner {
        require(_dfWalletFactory != address(0));
        dfWalletFactory = IDfWalletFactory(_dfWalletFactory);
    }

    function setWithdrawMinRatio(uint256 _withdrawMinRatio) public onlyOwner {
        require(_withdrawMinRatio >= 0.9 * 1e18 && _withdrawMinRatio <= 1e18);
        withdrawMinRatio = _withdrawMinRatio;
    }


    // ** PUBLIC functions **

    function getCompBalanceMetadataExt(address account) external returns (uint256 balance, uint256 allocated) {
        IComptrollerLensInterface comptroller = IComptrollerLensInterface(COMPTROLLER);
        balance = IToken(COMP_ADDRESS).balanceOf(account);
        comptroller.claimComp(account);
        uint256 newBalance = IToken(COMP_ADDRESS).balanceOf(account);
        uint256 accrued = comptroller.compAccrued(account);
        uint256 total = add(accrued, newBalance);
        allocated = sub(total, balance);
    }


    // DEPOSIT function

    function deposit(
        address dfWallet,
        uint256 amountDAI,
        uint256 amountUSDC,
        uint256 amountWBTC,
        uint256 flashloanDAI,
        uint256 flashloanUSDC,
        FlashloanProvider flashloanType,
        address flashloanFromAddress
    ) public payable onlyOwnerOrAdmin returns (address) {
        if (dfWallet == address(0)) {
            dfWallet = dfWalletFactory.createDfWallet();
            wallets[dfWallet] = UserData(msg.sender, 0, 0, 0, 0, 0, 0, 0, 0);
        }

        require(wallets[dfWallet].owner == msg.sender);

        uint amountETH = msg.value;

        // Update states
        wallets[dfWallet].deposit = add(wallets[dfWallet].deposit, amountDAI);
        wallets[dfWallet].depositUSDC = uint64(add(wallets[dfWallet].depositUSDC, amountUSDC));
        wallets[dfWallet].depositETH = uint96(add(wallets[dfWallet].depositETH, amountETH));
        wallets[dfWallet].depositWBTC = uint64(add(wallets[dfWallet].depositWBTC, amountWBTC));

        // Deposit ETH without boosting
        if (amountETH > 0) {
            IDfWallet(dfWallet).deposit.value(amountETH)(ETH_ADDRESS, CETH_ADDRESS, amountETH, address(0), address(0), 0);
        }

        // Deposit WBTC without boosting
        if (amountWBTC > 0) {
            IDfWallet(dfWallet).deposit(WBTC_ADDRESS, CWBTC_ADDRESS, amountWBTC, address(0), address(0), 0);
        }

        // Boost USDC deposit
        if (amountUSDC > 0 || flashloanUSDC > 0) {
            if (flashloanType == FlashloanProvider.DYDX
                && flashloanUSDC > IToken(USDC_ADDRESS).balanceOf(SOLO_MARGIN_ADDRESS)
            ) {
                // if dYdX lacks liquidity in USDC use ETH
                _depositBoostUsingDyDxEth(
                    dfWallet, USDC_ADDRESS, CUSDC_ADDRESS, amountUSDC, flashloanUSDC
                );
            } else {
                _depositBoost(
                    dfWallet, USDC_ADDRESS, CUSDC_ADDRESS, amountUSDC, flashloanUSDC, flashloanType, flashloanFromAddress
                );
            }
        }

        // Boost DAI deposit
        if (amountDAI > 0 || flashloanDAI > 0) {
            if (flashloanType == FlashloanProvider.DYDX
                && flashloanDAI > IToken(DAI_ADDRESS).balanceOf(SOLO_MARGIN_ADDRESS)
            ) {
                // if dYdX lacks liquidity in DAI use ETH
                _depositBoostUsingDyDxEth(
                    dfWallet, DAI_ADDRESS, CDAI_ADDRESS, amountDAI, flashloanDAI
                );
            } else {
                _depositBoost(
                    dfWallet, DAI_ADDRESS, CDAI_ADDRESS, amountDAI, flashloanDAI, flashloanType, flashloanFromAddress
                );
            }
        }

        return dfWallet;
    }


    // CLAIM function

    function claimComps(address dfWallet, address[] memory cTokens) public returns(uint256) {
        require(wallets[dfWallet].owner == msg.sender);

        IDfWallet(dfWallet).claimComp(cTokens);

        uint compTokenBalance = IToken(COMP_ADDRESS).balanceOf(address(this));
        IToken(COMP_ADDRESS).transfer(msg.sender, compTokenBalance);

        wallets[dfWallet].compClaimed += uint64(compTokenBalance / 1e12); // 6 decemals
        return compTokenBalance;
    }


    // WITHDRAW function

    function withdraw(
        address dfWallet,
        uint256 amountDAI,
        uint256 amountUSDC,
        uint256 amountETH,
        uint256 amountWBTC,
        address receiver,
        uint256 flashloanDAI,
        uint256 flashloanUSDC,
        FlashloanProvider flashloanType,
        address flashloanFromAddress
    ) public onlyOwnerOrAdmin {
        require(wallets[dfWallet].owner == msg.sender);
        require(receiver != address(0));

        // Update states
        wallets[dfWallet].deposit     = (amountDAI < wallets[dfWallet].deposit) ? sub(wallets[dfWallet].deposit, amountDAI) : 0;
        wallets[dfWallet].depositUSDC = (amountUSDC < wallets[dfWallet].depositUSDC) ? uint64(sub(wallets[dfWallet].depositUSDC, amountUSDC)) : 0;
        wallets[dfWallet].depositETH  = (amountETH < wallets[dfWallet].depositETH) ? uint96(sub(wallets[dfWallet].depositETH, amountETH)) : 0;
        wallets[dfWallet].depositWBTC = (amountWBTC < wallets[dfWallet].depositWBTC) ? uint64(sub(wallets[dfWallet].depositWBTC, amountWBTC)) : 0;

        // Withdraw assets
        _withdrawBoostedAsset(
            dfWallet, USDC_ADDRESS, CUSDC_ADDRESS, amountUSDC, receiver, flashloanUSDC, flashloanType, flashloanFromAddress
        );

        _withdrawBoostedAsset(
            dfWallet, DAI_ADDRESS, CDAI_ADDRESS, amountDAI, receiver, flashloanDAI, flashloanType, flashloanFromAddress
        );

        _withdrawAsset(
            dfWallet, ETH_ADDRESS, CETH_ADDRESS, amountETH, receiver
        );

        _withdrawAsset(
            dfWallet, WBTC_ADDRESS, CWBTC_ADDRESS, amountWBTC, receiver
        );
    }


    // ** FLASHLOAN CALLBACK functions **

    // Aave flashloan callback
    function executeOperation(
        address _reserve,
        uint256 _amountFlashLoan,
        uint256 _fee,
        bytes memory _data
    ) public {
        _flashloanHandler(_data, _fee);

        // Time to transfer the funds back
        transferFundsBackToPoolInternal(_reserve, add(_amountFlashLoan, _fee));
    }

    // dYdX flashloan callback
    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {
        _flashloanHandler(data, 0);
    }


    // ** PRIVATE & INTERNAL functions **

    function _bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    function _depositBoost(
        address dfWallet,
        address token,
        address cToken,
        uint256 deposit,
        uint256 flashloanAmount,
        FlashloanProvider flashloanType,
        address flashloanFromAddress
    ) internal {
        // FLASHLOAN LOGIC
        state = OP.DEPOSIT;

        if (flashloanType == FlashloanProvider.DYDX) {
            _initFlashloanDyDx(
                token,
                flashloanAmount,
                // Encode FlashloanData for callFunction
                abi.encode(FlashloanData({dfWallet: dfWallet, token: token, cToken: cToken, deposit: deposit, amountFlashLoan: flashloanAmount}))
            );
        } else if (flashloanType == FlashloanProvider.AAVE) {
            ILendingPool lendingPool = ILendingPool(ILendingPoolAddressesProvider(AAVE_ADDRESSES_PROVIDER).getLendingPool());
            lendingPool.flashLoan(
                address(this),
                token,
                flashloanAmount,
                // Encode FlashloanData for executeOperation
                abi.encode(FlashloanData({dfWallet: dfWallet, token: token, cToken: cToken, deposit: deposit, amountFlashLoan: flashloanAmount}))
            );
        } else if (flashloanType == FlashloanProvider.ADDRESS) {
            IToken(token).universalTransferFrom(flashloanFromAddress, dfWallet, flashloanAmount);

            IDfWallet(dfWallet).deposit(token, cToken, add(deposit, flashloanAmount), token, cToken, flashloanAmount);
            IDfWallet(dfWallet).withdrawToken(token, flashloanFromAddress, flashloanAmount);
        }

        state = OP.UNKNOWN;
        // END FLASHLOAN LOGIC
    }

    function _depositBoostUsingDyDxEth(
        address dfWallet,
        address token,
        address cToken,
        uint256 deposit,
        uint256 flashloanInTokens
    ) internal {
        // FLASHLOAN LOGIC
        state = OP.DEPOSIT_USING_DYDX_ETH;

        IPriceOracle compOracle = IComptroller(COMPTROLLER).oracle();
        uint256 ethPrice = compOracle.price("ETH").mul(1e12); // with 1e18 (1e6 * 1e12)

        uint256 ethDecimals = 18;
        uint256 decimalsMultiplier = 10 ** ethDecimals.sub(IToken(token).decimals());

        // IMPORTANT: token price is equal to 1 USD
        uint256 flashloanEthAmount = wdiv(flashloanInTokens * decimalsMultiplier, ethPrice).mul(2); // use x2 coef for eth as collateral

        _initFlashloanDyDx(
            WETH_ADDRESS,
            flashloanEthAmount,
            // Encode FlashloanDataDyDxEth for callFunction
            abi.encode(FlashloanDataDyDxEth({
                dfWallet: dfWallet, token: token, cToken: cToken, deposit: deposit, debt: flashloanInTokens, ethAmountFlashLoan: flashloanEthAmount
            }))
        );

        state = OP.UNKNOWN;
        // END FLASHLOAN LOGIC
    }

    function _withdrawBoostedAsset(
        address dfWallet,
        address token,
        address cToken,
        uint256 amountToken,
        address receiver,
        uint256 flashloanAmount,
        FlashloanProvider flashloanType,
        address flashloanFromAddress
    ) internal {
        if (amountToken == 0 && flashloanAmount == 0) {
            return;
        }

        if (IToken(token).allowance(address(this), dfWallet) != uint(-1)) {
            IToken(token).approve(dfWallet, uint(-1));
        }

        uint startBalance = IToken(token).universalBalanceOf(address(this));

        if (flashloanType == FlashloanProvider.DYDX
            && flashloanAmount > IToken(token).balanceOf(SOLO_MARGIN_ADDRESS)
        ) {
            // if dYdX lacks liquidity in token (DAI or USDC) use ETH
            _withdrawBoostUsingDyDxEth(
                dfWallet, token, cToken, amountToken, flashloanAmount
            );
        } else {
            _withdrawBoost(
                dfWallet, token, cToken, amountToken, flashloanAmount, flashloanType, flashloanFromAddress
            );
        }

        uint curBalance = IToken(token).universalBalanceOf(address(this));

        // rounding in token to cToken conversion
        if (curBalance <= startBalance) {
            require(wdiv(curBalance, startBalance) >= withdrawMinRatio);
            return;
        }

        uint tokensToUser = sub(curBalance, startBalance);
        if (token == ETH_ADDRESS) {
            _transferEth(receiver, tokensToUser);
        } else {
            IToken(token).universalTransfer(receiver, tokensToUser);
        }
    }

    function _withdrawAsset(
        address dfWallet,
        address token,
        address cToken,
        uint256 amountToken,
        address receiver
    ) internal {
        if (amountToken == 0) {
            return;
        }

        uint startBalance = IToken(token).universalBalanceOf(address(this));

        // Compound Quick Maths – redeemAmountIn * 1e18 * 1e18 / exchangeRateCurrent / 1e18
        uint cTokenToExtract =  (amountToken != uint(-1)) ? amountToken.mul(1e36).div(ICToken(cToken).exchangeRateCurrent()).div(1e18) : uint(-1);
        IDfWallet(dfWallet).withdraw(token, cToken, cTokenToExtract, ETH_ADDRESS, CETH_ADDRESS, 0);

        uint tokensToUser = sub(IToken(token).universalBalanceOf(address(this)), startBalance);
        if (token == ETH_ADDRESS) {
            _transferEth(receiver, tokensToUser);
        } else {
            IToken(token).universalTransfer(receiver, tokensToUser);
        }
    }

    function _withdrawBoost(
        address dfWallet,
        address token,
        address cToken,
        uint256 deposit,
        uint256 flashloanAmount,
        FlashloanProvider flashloanType,
        address flashloanFromAddress
    ) internal {
        // FLASHLOAN LOGIC
        state = OP.WITHDRAW;

        if (flashloanType == FlashloanProvider.DYDX) {
            _initFlashloanDyDx(
                token,
                flashloanAmount,
                // Encode FlashloanData for callFunction
                abi.encode(FlashloanData({dfWallet: dfWallet, token: token, cToken: cToken, deposit: deposit, amountFlashLoan: flashloanAmount}))
            );
        } else if (flashloanType == FlashloanProvider.AAVE) {
            ILendingPool lendingPool = ILendingPool(ILendingPoolAddressesProvider(AAVE_ADDRESSES_PROVIDER).getLendingPool());
            lendingPool.flashLoan(
                address(this),
                token,
                flashloanAmount,
                // Encode FlashloanData for executeOperation
                abi.encode(FlashloanData({dfWallet: dfWallet, token: token, cToken: cToken, deposit: deposit, amountFlashLoan: flashloanAmount}))
            );
        } else if (flashloanType == FlashloanProvider.ADDRESS) {
            IToken(token).universalTransferFrom(flashloanFromAddress, dfWallet, flashloanAmount);

            // Compound Quick Maths – redeemAmountIn * 1e18 * 1e18 / exchangeRateCurrent / 1e18
            uint cTokenToExtract = (deposit != uint(-1)) ? deposit.add(flashloanAmount).mul(1e36).div(ICToken(cToken).exchangeRateCurrent()).div(1e18) : uint(-1);
            IDfWallet(dfWallet).withdraw(token, cToken, cTokenToExtract, token, cToken, flashloanAmount);

            IToken(token).universalTransfer(flashloanFromAddress, flashloanAmount);
        }

        state = OP.UNKNOWN;
        // END FLASHLOAN LOGIC
    }

    function _withdrawBoostUsingDyDxEth(
        address dfWallet,
        address token,
        address cToken,
        uint256 deposit,
        uint256 flashloanInTokens
    ) internal {
        // FLASHLOAN LOGIC
        state = OP.WITHDRAW_USING_DYDX_ETH;

        IPriceOracle compOracle = IComptroller(COMPTROLLER).oracle();
        uint256 ethPrice = compOracle.price("ETH").mul(1e12); // with 1e18 (1e6 * 1e12)

        uint256 ethDecimals = 18;
        uint256 decimalsMultiplier = 10 ** ethDecimals.sub(IToken(token).decimals());

        // IMPORTANT: token price is equal to 1 USD
        uint256 flashloanEthAmount = wdiv(flashloanInTokens * decimalsMultiplier, ethPrice).mul(2); // use x2 coef for eth as collateral

        _initFlashloanDyDx(
            WETH_ADDRESS,
            flashloanEthAmount,
            // Encode FlashloanDataDyDxEth for callFunction
            abi.encode(FlashloanDataDyDxEth({
                dfWallet: dfWallet, token: token, cToken: cToken, deposit: deposit, debt: flashloanInTokens, ethAmountFlashLoan: flashloanEthAmount
            }))
        );

        state = OP.UNKNOWN;
        // END FLASHLOAN LOGIC
    }

    function _flashloanHandler(
        bytes memory data,
        uint fee
    ) internal {
        require(state != OP.UNKNOWN);

        if (state == OP.DEPOSIT) {
            FlashloanData memory flashloanData = abi.decode(data, (FlashloanData));

            // Calculate repay amount
            uint totalDebt = add(flashloanData.amountFlashLoan, fee);

            IToken(flashloanData.token).transfer(flashloanData.dfWallet, flashloanData.amountFlashLoan);

            IDfWallet(flashloanData.dfWallet).deposit(
                flashloanData.token, flashloanData.cToken, add(flashloanData.deposit, flashloanData.amountFlashLoan), flashloanData.token, flashloanData.cToken, totalDebt
            );

            IDfWallet(flashloanData.dfWallet).withdrawToken(flashloanData.token, address(this), totalDebt);
        } else if (state == OP.WITHDRAW) {
            FlashloanData memory flashloanData = abi.decode(data, (FlashloanData));

            // _withdrawBoost() subtracts flashloan fee
            // Compound Quick Maths – redeemAmountIn * 1e18 * 1e18 / exchangeRateCurrent / 1e18
            uint cTokenToExtract = (flashloanData.deposit != uint(-1)) ? flashloanData.deposit.add(flashloanData.amountFlashLoan).mul(1e36).div(ICToken(flashloanData.cToken).exchangeRateCurrent()).div(1e18) : uint(-1);

            IDfWallet(flashloanData.dfWallet).withdraw(flashloanData.token, flashloanData.cToken, cTokenToExtract, flashloanData.token, flashloanData.cToken, flashloanData.amountFlashLoan);
            // require(flashloanData.amountFlashLoan.div(3) >= sub(receivedAmount, _fee), "Fee greater then user amount"); // user pay fee for flash loan
        } else if (state == OP.DEPOSIT_USING_DYDX_ETH) {
            // use dYdX flashloans without fee
            FlashloanDataDyDxEth memory flashloanData = abi.decode(data, (FlashloanDataDyDxEth));
            uint256 loanEth = flashloanData.ethAmountFlashLoan;

            // WETH to ETH for loan using proxy (eth transfer gas limit)
            IDfProxy dfProxy = IDfProxy(DF_PROXY_ADDRESS);
            IERC20(WETH_ADDRESS).transfer(address(dfProxy), loanEth);
            dfProxy.cast(address(uint160(WETH_ADDRESS)), abi.encodeWithSelector(IWeth(WETH_ADDRESS).withdraw.selector, loanEth));
            dfProxy.withdrawEth(address(this));

            // deposit eth loan and borrow debt tokens
            IDfWallet(flashloanData.dfWallet).deposit.value(loanEth)(
                ETH_ADDRESS, CETH_ADDRESS, loanEth, flashloanData.token, flashloanData.cToken, flashloanData.debt
            );

            // deposit user deposit + debt tokens (are already on the dfWallet)
            IDfWallet(flashloanData.dfWallet).deposit(
                flashloanData.token, flashloanData.cToken, add(flashloanData.deposit, flashloanData.debt), address(0), address(0), 0
            );

            // redeem eth loan (using withdraw function)
            // Compound Quick Maths – redeemAmountIn * 1e18 * 1e18 / exchangeRateCurrent / 1e18
            uint cEthToExtract = loanEth.mul(1e36).div(ICToken(CETH_ADDRESS).exchangeRateCurrent()).div(1e18);
            IDfWallet(flashloanData.dfWallet).withdraw(
                ETH_ADDRESS, CETH_ADDRESS, cEthToExtract, ETH_ADDRESS, CETH_ADDRESS, 0
            );

            // ETH to WETH for loan
            IWeth(WETH_ADDRESS).deposit.value(loanEth)();
        } else if (state == OP.WITHDRAW_USING_DYDX_ETH) {
            // use dYdX flashloans without fee
            FlashloanDataDyDxEth memory flashloanData = abi.decode(data, (FlashloanDataDyDxEth));
            uint256 loanEth = flashloanData.ethAmountFlashLoan;

            // WETH to ETH for loan using proxy (eth transfer gas limit)
            IDfProxy dfProxy = IDfProxy(DF_PROXY_ADDRESS);
            IERC20(WETH_ADDRESS).transfer(address(dfProxy), loanEth);
            dfProxy.cast(address(uint160(WETH_ADDRESS)), abi.encodeWithSelector(IWeth(WETH_ADDRESS).withdraw.selector, loanEth));
            dfProxy.withdrawEth(address(this));

            // deposit eth loan and borrow debt tokens
            IDfWallet(flashloanData.dfWallet).deposit.value(loanEth)(
                ETH_ADDRESS, CETH_ADDRESS, loanEth, flashloanData.token, flashloanData.cToken, flashloanData.debt
            );
            IDfWallet(flashloanData.dfWallet).withdrawToken(flashloanData.token, address(this), flashloanData.debt);

            // repay debt tokens and redeem deposit + debt tokens
            // Compound Quick Maths – redeemAmountIn * 1e18 * 1e18 / exchangeRateCurrent / 1e18
            uint cTokenToExtract = (flashloanData.deposit != uint(-1)) ? flashloanData.deposit.add(flashloanData.debt).mul(1e36).div(ICToken(flashloanData.cToken).exchangeRateCurrent()).div(1e18) : uint(-1);
            IDfWallet(flashloanData.dfWallet).withdraw(
                flashloanData.token, flashloanData.cToken, cTokenToExtract, flashloanData.token, flashloanData.cToken, flashloanData.debt
            );

            // repay debt tokens and redeem eth loan
            // Compound Quick Maths – redeemAmountIn * 1e18 * 1e18 / exchangeRateCurrent / 1e18
            uint cEthToExtract = loanEth.mul(1e36).div(ICToken(CETH_ADDRESS).exchangeRateCurrent()).div(1e18);
            IDfWallet(flashloanData.dfWallet).withdraw(
                ETH_ADDRESS, CETH_ADDRESS, cEthToExtract, flashloanData.token, flashloanData.cToken, flashloanData.debt
            );

            // ETH to WETH for loan
            IWeth(WETH_ADDRESS).deposit.value(loanEth)();
        }
    }

    function _transferEth(address _receiver, uint _amount) internal {
        address payable receiverPayable = address(uint160(_receiver));
        (bool result, ) = receiverPayable.call.value(_amount)("");
        require(result, "Transfer of ETH failed");
    }


    // **FALLBACK functions**
    function() external payable {}

}