pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ISoloMargin.sol";
import "./SafeERC20.sol";
import "./TokenInterface.sol";
import "./DSProxy.sol";
import "./AaveHelper.sol";

// weth->eth 
// deposit eth for users proxy
// borrow users token from proxy
// repay on behalf of user
// pull user supply
// take eth amount from supply (if needed more, borrow it?)
// return eth to sender

/// @title Import Aave position from account to wallet
contract AaveImport is AaveHelper {

    using SafeERC20 for ERC20;

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant BASIC_PROXY = 0x2B816BFeD57bD7f36280CAaD292220dCA5004a6a;
    address public constant AETH_ADDRESS = 0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04;

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {

        (
            address collateralToken,
            address borrowToken,
            uint256 ethAmount,
            address user,
            address proxy
        )
        = abi.decode(data, (address,address,uint256,address,address));

        address payable payableProxy = payable(proxy);

        // withdraw eth
        TokenInterface(WETH_ADDRESS).withdraw(ethAmount);

        address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
        address aCollateralToken = ILendingPool(lendingPoolCoreAddress).getReserveATokenAddress(collateralToken);
        address aBorrowToken = ILendingPool(lendingPoolCoreAddress).getReserveATokenAddress(borrowToken);

        // deposit eth on behalf of proxy
        DSProxy(payableProxy).execute{value: ethAmount}(BASIC_PROXY, abi.encodeWithSignature("deposit(address,uint256)", ETH_ADDR, ethAmount));
        // borrow needed amount to repay users borrow
        (,uint256 borrowAmount,,,,,,,,) = ILendingPool(lendingPool).getUserReserveData(borrowToken, user);
        DSProxy(payableProxy).execute(BASIC_PROXY, abi.encodeWithSignature("borrow(address,uint256,uint256)", borrowToken, borrowAmount, 1));
        // payback on behalf of user
        ERC20(borrowToken).safeApprove(proxy, borrowAmount);
        DSProxy(payableProxy).execute(BASIC_PROXY, abi.encodeWithSignature("paybackOnBehlaf(address,address,uint256,bool,address)", borrowToken, aBorrowToken, 0, true, user));
        // pull tokens from user to proxy
        uint256 collateralAmount = ERC20(aCollateralToken).balanceOf(user);
        ERC20(aCollateralToken).safeTransferFrom(user, address(this), collateralAmount);
        // withdraw deposited eth
        DSProxy(payableProxy).execute(BASIC_PROXY, abi.encodeWithSignature("withdraw(address,address,uint256,bool)", ETH_ADDR, AETH_ADDRESS, ethAmount, false));

        // deposit eth, get weth and return to sender
        TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        ERC20(WETH_ADDRESS).safeTransfer(proxy, ethAmount+2);
    }

    /// @dev if contract receive eth, convert it to WETH
    receive() external payable {
        // deposit eth and get weth 
        TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
    }
}