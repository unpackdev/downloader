pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ISoloMargin.sol";
import "./SafeERC20.sol";
import "./TokenInterface.sol";
import "./DSProxy.sol";
import "./AaveHelperV2.sol";
import "./AdminAuth.sol";

// weth->eth 
// deposit eth for users proxy
// borrow users token from proxy
// repay on behalf of user
// pull user supply
// take eth amount from supply (if needed more, borrow it?)
// return eth to sender

/// @title Import Aave position from account to wallet
contract AaveImportV2 is AaveHelperV2, AdminAuth {

    using SafeERC20 for ERC20;

    address public constant BASIC_PROXY = 0xc17c8eB12Ba24D62E69fd57cbd504EEf418867f9;

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {

        (
            address market,
            address collateralToken,
            address borrowToken,
            uint256 ethAmount,
            address user,
            address proxy
        )
        = abi.decode(data, (address,address,address,uint256,address,address));

        // withdraw eth
        TokenInterface(WETH_ADDRESS).withdraw(ethAmount);

        address lendingPool = ILendingPoolAddressesProviderV2(market).getLendingPool();
        IAaveProtocolDataProviderV2 dataProvider = getDataProvider(market);

        uint256 globalBorrowAmountStable = 0;
        uint256 globalBorrowAmountVariable = 0;

        { // avoid stack too deep
            // deposit eth on behalf of proxy
            DSProxy(payable(proxy)).execute{value: ethAmount}(BASIC_PROXY, abi.encodeWithSignature("deposit(address,address,uint256)", market, ETH_ADDR, ethAmount));
            // borrow needed amount to repay users borrow
            (, uint256 borrowsStable, uint256 borrowsVariable,,,,,,) = dataProvider.getUserReserveData(borrowToken, user);
            
            if (borrowsStable > 0) {
                DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("borrow(address,address,uint256,uint256)", market, borrowToken, borrowsStable, 2));
                globalBorrowAmountStable = borrowsStable;
            }

            if (borrowsVariable > 0) {
                DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("borrow(address,address,uint256,uint256)", market, borrowToken, borrowsVariable, 1));
                globalBorrowAmountVariable = borrowsVariable;
            }
        }

        if (globalBorrowAmountVariable > 0) {
            paybackOnBehalf(market, proxy, globalBorrowAmountVariable, borrowToken, user, 1);
        }
        
        if (globalBorrowAmountStable > 0) {
            paybackOnBehalf(market, proxy, globalBorrowAmountStable, borrowToken, user, 2);
        }

        (address aToken,,) = dataProvider.getReserveTokensAddresses(collateralToken);
        // pull tokens from user to proxy
        ERC20(aToken).safeTransferFrom(user, proxy, ERC20(aToken).balanceOf(user));

        // enable as collateral
        DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("setUserUseReserveAsCollateralIfNeeded(address,address)", market, collateralToken));

        // withdraw deposited eth
        DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("withdraw(address,address,uint256)", market, ETH_ADDR, ethAmount));
        

        // deposit eth, get weth and return to sender
        TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        ERC20(WETH_ADDRESS).safeTransfer(proxy, ethAmount+2);
    }

    function paybackOnBehalf(address _market, address _proxy, uint _amount, address _token, address _onBehalf, uint _rateMode) internal {
        // payback on behalf of user
        if (_token != ETH_ADDR) {
            ERC20(_token).safeApprove(_proxy, _amount);
            DSProxy(payable(_proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("paybackOnBehalf(address,address,uint256,uint256,address)", _market, _token, uint(-1), _rateMode, _onBehalf));
        } else {
            DSProxy(payable(_proxy)).execute{value: _amount}(BASIC_PROXY, abi.encodeWithSignature("paybackOnBehalf(address,address,uint256,uint256,address)", _market, _token, uint(-1), _rateMode, _onBehalf));
        }
    }

    /// @dev if contract receive eth, convert it to WETH
    receive() external payable {
        // deposit eth and get weth 
        if (msg.sender == owner) {
            TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        }
    }
}