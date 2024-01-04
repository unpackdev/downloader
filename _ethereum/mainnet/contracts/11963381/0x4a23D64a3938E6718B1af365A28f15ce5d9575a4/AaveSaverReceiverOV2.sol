pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./TokenInterface.sol";
import "./DSProxy.sol";
import "./AaveHelperV2.sol";
import "./AdminAuth.sol";
import "./DFSExchangeCore.sol";

/// @title Import Aave position from account to wallet
contract AaveSaverReceiverOV2 is AaveHelperV2, AdminAuth, DFSExchangeCore {

    using SafeERC20 for ERC20;

    address public constant AAVE_BASIC_PROXY = 0xc17c8eB12Ba24D62E69fd57cbd504EEf418867f9;

    function boost(ExchangeData memory _exchangeData, address _market, uint256 _gasCost, address _proxy, address user) private {
        (, uint swappedAmount) = _sell(_exchangeData);

        swappedAmount -= getGasCost(ILendingPoolAddressesProviderV2(_market).getPriceOracle(), swappedAmount, user, _gasCost, _exchangeData.destAddr);
 
        // if its eth we need to send it to the basic proxy, if not, we need to approve basic proxy to pull tokens
        uint256 msgValue = 0;
        if (_exchangeData.destAddr == ETH_ADDR) {
            msgValue = swappedAmount;
        } else {
            ERC20(_exchangeData.destAddr).safeApprove(_proxy, swappedAmount);
        }
        // deposit collateral on behalf of user
        DSProxy(payable(_proxy)).execute{value: msgValue}(
            AAVE_BASIC_PROXY,
            abi.encodeWithSignature(
                "deposit(address,address,uint256)",
                _market,
                _exchangeData.destAddr,
                swappedAmount
                )
            );
    }

    function repay(ExchangeData memory _exchangeData, address _market, uint256 _gasCost, address _proxy, uint256 _rateMode, address user) private {
        (, uint swappedAmount) = _sell(_exchangeData);

        swappedAmount -= getGasCost(ILendingPoolAddressesProviderV2(_market).getPriceOracle(), swappedAmount, user, _gasCost, _exchangeData.destAddr);

        // if its eth we need to send it to the basic proxy, if not, we need to approve basic proxy to pull tokens
        uint256 msgValue = 0;
        if (_exchangeData.destAddr == ETH_ADDR) {
            msgValue = swappedAmount;
        } else {
            ERC20(_exchangeData.destAddr).safeApprove(_proxy, swappedAmount);
        }
        // first payback the loan with swapped amount
        DSProxy(payable(_proxy)).execute{value: msgValue}(
            AAVE_BASIC_PROXY,
            abi.encodeWithSignature(
                "payback(address,address,uint256,uint256)",
                _market,
                _exchangeData.destAddr,
                swappedAmount,
                _rateMode
                )
            );

        // pull the amount we flash loaned in collateral to be able to payback the debt
        DSProxy(payable(_proxy)).execute(AAVE_BASIC_PROXY, abi.encodeWithSignature("withdraw(address,address,uint256)", _market, _exchangeData.srcAddr, _exchangeData.srcAmount));

        // if its eth we need to send it to the basic proxy, if not, we need to approve basic proxy to pull tokens
        msgValue = 0;
        if (_exchangeData.srcAddr == ETH_ADDR) {
            msgValue = swappedAmount;
        } else {
            ERC20(_exchangeData.srcAddr).safeApprove(_proxy, _exchangeData.srcAmount);
        }

        // payback the borrowed collateral
        DSProxy(payable(_proxy)).execute{value: msgValue}(
            AAVE_BASIC_PROXY,
            abi.encodeWithSignature(
                "payback(address,address,uint256,uint256)",
                _market,
                _exchangeData.srcAddr,
                _exchangeData.srcAmount,
                _rateMode
                )
            );
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) public returns (bool) {
        (
            bytes memory exchangeDataBytes,
            address market,
            uint256 gasCost,
            uint256 rateMode,
            bool isRepay,
            address user,
            address proxy
        )
        = abi.decode(params, (bytes,address,uint256,uint256,bool,address,address));

        require(initiator == proxy, "initiator isn't proxy");

        ExchangeData memory exData = unpackExchangeData(exchangeDataBytes);
        exData.user = user;    
        exData.dfsFeeDivider = MANUAL_SERVICE_FEE;
        if (BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin)) {
            exData.dfsFeeDivider = AUTOMATIC_SERVICE_FEE;
        }

        if (isRepay) {
            repay(exData, market, gasCost, proxy, rateMode, user);
        } else {
            boost(exData, market, gasCost, proxy, user);
        }
        
        tx.origin.transfer(address(this).balance);

        return true;
    }

    /// @dev allow contract to receive eth from sell
    receive() external override payable {}
}
