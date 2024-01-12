// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "./AdapterBase.sol";
import "./IProtocolDataProvider.sol";
import "./IIncentivesController.sol";
import "./ILendingPool.sol";
import "./IWETHGateway.sol";
import "./IAToken.sol";
import "./IVariableDebtToken.sol";
import "./IOracle.sol";
import "./IVault.sol";
import "./IFlashLoanRecipient.sol";
import "./IAccount.sol";

contract AaveAdapter is AdapterBase, IFlashLoanRecipient {
    using SafeERC20 for IERC20;

    mapping(address => address) public trustATokenAddr;
    IVault public constant flashLoanVault =
        IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    event AaveDeposit(address token, uint256 amount, address account);
    event AaveWithdraw(address token, uint256 amount, address account);
    event AaveBorrow(
        address token,
        uint256 amount,
        address account,
        uint256 rateMode
    );
    event AaveRepay(
        address token,
        uint256 amount,
        address account,
        uint256 rateMode
    );
    event AaveClaim(address target, uint256 amount);

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "AaveV2Adapter")
    {}

    function initialize(
        address[] calldata tokenAddr,
        address[] calldata aTokenAddr
    ) external onlyTimelock {
        require(
            tokenAddr.length > 0 && tokenAddr.length == aTokenAddr.length,
            "Set length mismatch."
        );
        for (uint256 i = 0; i < tokenAddr.length; i++) {
            if (tokenAddr[i] == ethAddr) {
                require(
                    IAToken(aTokenAddr[i]).UNDERLYING_ASSET_ADDRESS() ==
                        wethAddr,
                    "Address mismatch."
                );
            } else {
                require(
                    IAToken(aTokenAddr[i]).UNDERLYING_ASSET_ADDRESS() ==
                        tokenAddr[i],
                    "Address mismatch."
                );
            }
            trustATokenAddr[tokenAddr[i]] = aTokenAddr[i];
        }
    }

    address public constant wethVtokenAddr =
        0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;

    address public constant stethTokenAddr =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    address public constant aaveProviderAddr =
        0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;

    address public constant aaveDataAddr =
        0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;

    address public constant wethGatewayAddr =
        0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04;

    address public constant aaveOracleAddr =
        0xA50ba011c48153De246E5192C8f9258A2ba79Ca9;

    address public constant aaveLendingPoolAddr =
        0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    address public constant incentivesController =
        0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;

    address public executor; //for flashloan

    /// @dev Aave Referral Code
    uint16 internal constant referralCode = 0;

    function deposit(address account, bytes calldata encodedData)
        external
        payable
        onlyAdapterManager
    {
        (address token, uint256 amount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        require(trustATokenAddr[token] != address(0), "token error");
        IAaveLendingPool aave = IAaveLendingPool(aaveLendingPoolAddr);

        if (token == ethAddr) {
            IWETHGateway wethGateway = IWETHGateway(wethGatewayAddr);
            wethGateway.depositETH{value: msg.value}(
                aaveLendingPoolAddr,
                account,
                referralCode
            );
            emit AaveDeposit(token, msg.value, account);
        } else {
            pullAndApprove(token, account, aaveLendingPoolAddr, amount);
            aave.deposit(token, amount, account, referralCode);
            emit AaveDeposit(token, amount, account);
        }
    }

    function setCollateral(address token, bool isCollateral)
        external
        onlyDelegation
    {
        IAaveLendingPool aave = IAaveLendingPool(aaveLendingPoolAddr);
        aave.setUserUseReserveAsCollateral(token, isCollateral);
    }

    function withdraw(address tokenAddr, uint256 amount)
        external
        onlyDelegation
    {
        IAaveLendingPool aave = IAaveLendingPool(aaveLendingPoolAddr);
        if (tokenAddr == ethAddr) {
            IWETHGateway wethGateway = IWETHGateway(wethGatewayAddr);
            wethGateway.withdrawETH(aaveLendingPoolAddr, amount, address(this));
        } else {
            aave.withdraw(tokenAddr, amount, address(this));
        }
        emit AaveWithdraw(tokenAddr, amount, address(this));
    }

    function borrow(
        address token,
        uint256 amount,
        uint256 rateMode
    ) external onlyDelegation {
        if (token == ethAddr) {
            IWETHGateway wethGateway = IWETHGateway(wethGatewayAddr);
            wethGateway.borrowETH(
                aaveLendingPoolAddr,
                amount,
                rateMode,
                referralCode
            );
        } else {
            IAaveLendingPool aave = IAaveLendingPool(aaveLendingPoolAddr);
            aave.borrow(token, amount, rateMode, referralCode, address(this));
        }
        emit AaveBorrow(token, amount, address(this), rateMode);
    }

    function approveDelegation(uint256 amount) external onlyDelegation {
        IVariableDebtToken(wethVtokenAddr).approveDelegation(
            wethGatewayAddr,
            amount
        );
    }

    function payback(
        address tokenAddr,
        uint256 amount,
        uint256 rateMode
    ) external onlyDelegation {
        if (tokenAddr == ethAddr) {
            IWETHGateway wethGateway = IWETHGateway(wethGatewayAddr);
            if (amount == type(uint256).max) {
                uint256 repayValue = IERC20(wethVtokenAddr).balanceOf(
                    address(this)
                );
                wethGateway.repayETH{value: repayValue}(
                    aaveLendingPoolAddr,
                    repayValue,
                    rateMode,
                    address(this)
                );
            } else {
                wethGateway.repayETH{value: amount}(
                    aaveLendingPoolAddr,
                    amount,
                    rateMode,
                    address(this)
                );
            }
        } else {
            IAaveLendingPool(aaveLendingPoolAddr).repay(
                tokenAddr,
                amount,
                rateMode,
                address(this)
            );
        }
        emit AaveRepay(tokenAddr, amount, address(this), rateMode);
    }

    function getReward(address[] memory assertAddress, uint256 amount)
        external
        onlyDelegation
    {
        IAaveIncentivesController(incentivesController).claimRewards(
            assertAddress,
            amount,
            address(this)
        );
        emit AaveClaim(incentivesController, amount);
    }

    function positionTransfer(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (address tempCollateralToken, uint256 loanAmount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        bytes memory callbackData = abi.encode(
            tempCollateralToken,
            loanAmount,
            IAccount(account).owner(),
            account
        );
        executeFlashLoan(tempCollateralToken, loanAmount, callbackData);
    }

    function executeFlashLoan(
        address _token,
        uint256 _amount,
        bytes memory _callbackData
    ) internal {
        executor = msg.sender;
        IERC20[] memory tokens = new IERC20[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = IERC20(_token);
        amounts[0] = _amount;
        flashLoanVault.flashLoan(this, tokens, amounts, _callbackData);
    }

    function receiveFlashLoan(
        IERC20[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _feeAmounts,
        bytes memory _callbackData
    ) external override {
        require(msg.sender == address(flashLoanVault), "Invalid call!");
        require(executor != address(0), "Reentrant call!");
        (, , , address account) = abi.decode(
            _callbackData,
            (address, uint256, address, address)
        );
        uint256 tokenBefore = _tokens[0].balanceOf(ADAPTER_ADDRESS);
        approveToken(address(_tokens[0]), aaveLendingPoolAddr, _amounts[0]);
        IAaveLendingPool(aaveLendingPoolAddr).deposit(
            address(_tokens[0]),
            _amounts[0],
            account,
            referralCode
        );
        toCallback(account, AaveAdapter.exchangeDebt.selector, _callbackData);
        uint256 tokenAfter = _tokens[0].balanceOf(ADAPTER_ADDRESS);
        require(tokenBefore == tokenAfter, "Unbalanced assets!");

        for (uint256 i = 0; i < _tokens.length; i++) {
            _tokens[i].safeTransfer(address(flashLoanVault), _amounts[i]);
        }
        executor = address(0);
    }

    function exchangeDebt(
        address loanToken,
        uint256 loanAmount,
        address user,
        address account
    ) external onlyDelegation {
        require(account == address(this) && tx.origin == user, "Invalid call!");
        IAaveProtocolDataProvider aaveDataProvider = IAaveProtocolDataProvider(
            aaveDataAddr
        );
        IAaveLendingPool aave = IAaveLendingPool(aaveLendingPoolAddr);
        address[] memory tokens = aave.getReservesList();
        for (uint256 i = 0; i < tokens.length; i++) {
            (, , address variableDebtTokenAddress) = aaveDataProvider
                .getReserveTokensAddresses(tokens[i]);
            uint256 debtAmount = IERC20(variableDebtTokenAddress).balanceOf(
                user
            );
            if (debtAmount != 0) {
                uint256 rateMode = 2;
                aave.borrow(
                    tokens[i],
                    debtAmount,
                    rateMode,
                    referralCode,
                    account
                );
                IERC20(tokens[i]).safeApprove(aaveLendingPoolAddr, 0);
                IERC20(tokens[i]).safeApprove(aaveLendingPoolAddr, debtAmount);
                aave.repay(tokens[i], debtAmount, rateMode, user);
            }
        }
        for (uint256 i = 0; i < tokens.length; i++) {
            (address aTokenAddress, , ) = aaveDataProvider
                .getReserveTokensAddresses(tokens[i]);
            uint256 aTokenAmount = IAToken(aTokenAddress).balanceOf(user);
            if (aTokenAmount != 0) {
                IAToken(aTokenAddress).transferFrom(
                    user,
                    account,
                    aTokenAmount
                );
            }
        }
        (address loanAToken, , ) = aaveDataProvider.getReserveTokensAddresses(
            loanToken
        );
        IERC20(loanAToken).safeApprove(aaveLendingPoolAddr, 0);
        IERC20(loanAToken).safeApprove(aaveLendingPoolAddr, loanAmount);
        aave.withdraw(loanToken, loanAmount, ADAPTER_ADDRESS);
    }
}
