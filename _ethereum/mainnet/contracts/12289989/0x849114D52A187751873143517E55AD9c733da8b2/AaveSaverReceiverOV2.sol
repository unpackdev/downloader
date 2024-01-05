pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./TokenInterface.sol";
import "./DSProxy.sol";
import "./AaveHelperV2.sol";
import "./AdminAuth.sol";
import "./DFSExchangeCore.sol";
import "./DefisaverLogger.sol";

/// @title Import Aave position from account to wallet
contract AaveSaverReceiverOV2 is AaveHelperV2, AdminAuth, DFSExchangeCore {
    using SafeERC20 for ERC20;

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    address public constant AAVE_BASIC_PROXY = 0x234e8219f25F6AF4bE90d40C79DEdE31B1f21d4f;

    function boost(
        ExchangeData memory _exchangeData,
        address _market,
        uint256 _gasCost,
        address _proxy
    ) internal {
        (, uint256 swappedAmount) = _sell(_exchangeData);

        address user = DSAuth(_proxy).owner();
        swappedAmount -= getGasCost(
            ILendingPoolAddressesProviderV2(_market).getPriceOracle(),
            swappedAmount,
            user,
            _gasCost,
            _exchangeData.destAddr
        );

        // if its eth we need to send it to the basic proxy, if not, we need to approve users proxy to pull tokens
        uint256 msgValue = 0;
        address token = _exchangeData.destAddr;
        // sell always return eth, but deposit differentiate eth vs weth, so we change weth address to eth when we are depoisting
        if (_exchangeData.destAddr == ETH_ADDR || _exchangeData.destAddr == WETH_ADDRESS) {
            msgValue = swappedAmount;
            token = ETH_ADDR;
        } else {
            ERC20(_exchangeData.destAddr).safeApprove(_proxy, swappedAmount);
        }
        // deposit collateral on behalf of user
        DSProxy(payable(_proxy)).execute{value: msgValue}(
            AAVE_BASIC_PROXY,
            abi.encodeWithSignature(
                "deposit(address,address,uint256)",
                _market,
                token,
                swappedAmount
            )
        );

        logEvent("AaveV2Boost", _exchangeData, swappedAmount);
    }

    function repay(
        ExchangeData memory _exchangeData,
        address _market,
        uint256 _gasCost,
        address _proxy,
        uint256 _rateMode,
        uint256 _aaveFlashlLoanFee
    ) internal {
        // we will withdraw exactly the srcAmount, as fee we keep before selling
        uint256 valueToWithdraw = _exchangeData.srcAmount;
        // take out the fee wee need to pay and sell the rest
        _exchangeData.srcAmount = _exchangeData.srcAmount - _aaveFlashlLoanFee;

        (, uint256 swappedAmount) = _sell(_exchangeData);

        address user = DSAuth(_proxy).owner();
        swappedAmount -= getGasCost(
            ILendingPoolAddressesProviderV2(_market).getPriceOracle(),
            swappedAmount,
            user,
            _gasCost,
            _exchangeData.destAddr
        );

        // set protocol fee left to eth balance of this address
        // but if destAddr is eth or weth, this also includes that value so we need to substract it
        // doing this after taking gas cost so it doesn't take it into account
        uint256 protocolFeeLeft = address(this).balance;

        // if its eth we need to send it to the basic proxy, if not, we need to approve basic proxy to pull tokens
        uint256 msgValue = 0;
        if (_exchangeData.destAddr == ETH_ADDR || _exchangeData.destAddr == WETH_ADDRESS) {
            protocolFeeLeft -= swappedAmount;
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

        // if some tokens left after payback (full repay) we need to return it back to the proxy owner
        require(user != address(0)); // be sure that we fetched the user correctly
        if (_exchangeData.destAddr == ETH_ADDR || _exchangeData.destAddr == WETH_ADDRESS) {
            // keep protocol fee for tx.origin, but the rest of the balance return to the user
            payable(user).transfer(address(this).balance - protocolFeeLeft);
        } else {
            // in case its a token, just return whole value back to the user, as protocol fee is always in eth
            uint256 amount = ERC20(_exchangeData.destAddr).balanceOf(address(this));
            ERC20(_exchangeData.destAddr).safeTransfer(user, amount);
        }

        // pull the amount we flash loaned in collateral to be able to payback the debt
        DSProxy(payable(_proxy)).execute(
            AAVE_BASIC_PROXY,
            abi.encodeWithSignature(
                "withdraw(address,address,uint256)",
                _market,
                _exchangeData.srcAddr,
                valueToWithdraw
            )
        );

        logEvent("AaveV2Repay", _exchangeData, swappedAmount);
    }

    function executeOperation(
        address[] calldata,
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
            address proxy
        ) = abi.decode(params, (bytes, address, uint256, uint256, bool, address));

        address lendingPool = ILendingPoolAddressesProviderV2(market).getLendingPool();

        require(msg.sender == lendingPool, "Callbacks only allowed from Aave");
        require(initiator == proxy, "initiator isn't proxy");

        ExchangeData memory exData = unpackExchangeData(exchangeDataBytes);
        exData.user = DSAuth(proxy).owner();
        exData.dfsFeeDivider = MANUAL_SERVICE_FEE;
        if (BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin)) {
            exData.dfsFeeDivider = AUTOMATIC_SERVICE_FEE;
        }

        // this is to avoid stack too deep
        uint256 fee = premiums[0];
        uint256 totalValueToReturn = exData.srcAmount + fee;

        // if its repay, we are using regular flash loan and payback the premiums
        if (isRepay) {
            repay(exData, market, gasCost, proxy, rateMode, fee);

            address token = exData.srcAddr;
            if (token == ETH_ADDR || token == WETH_ADDRESS) {
                // deposit eth, get weth and return to sender
                TokenInterface(WETH_ADDRESS).deposit.value(totalValueToReturn)();
                token = WETH_ADDRESS;
            }

            ERC20(token).safeApprove(lendingPool, totalValueToReturn);
        } else {
            boost(exData, market, gasCost, proxy);
        }

        tx.origin.transfer(address(this).balance);

        return true;
    }

    function logEvent(string memory _name, ExchangeData memory _exchangeData, uint _swappedAmount) internal {
        DefisaverLogger(DEFISAVER_LOGGER).Log(
            address(this),
            msg.sender,
            _name,
            abi.encode(_exchangeData.srcAddr, _exchangeData.destAddr, _exchangeData.srcAmount, _swappedAmount)
        );
    }

    /// @dev allow contract to receive eth from sell
    receive() external payable override {}
}
