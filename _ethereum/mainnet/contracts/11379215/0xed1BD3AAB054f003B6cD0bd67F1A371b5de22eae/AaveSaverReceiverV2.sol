pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ISoloMargin.sol";
import "./SafeERC20.sol";
import "./TokenInterface.sol";
import "./DSProxy.sol";
import "./AaveHelperV2.sol";
import "./AdminAuth.sol";
import "./DFSExchangeData.sol";

/// @title Import Aave position from account to wallet
contract AaveSaverReceiverV2 is AaveHelperV2, AdminAuth, DFSExchangeData {

    using SafeERC20 for ERC20;

    address public constant AAVE_SAVER_PROXY = 0x16519620A911f5A540cb446b30e020B007A54DB5;
    address public constant AAVE_BASIC_PROXY = 0xc17c8eB12Ba24D62E69fd57cbd504EEf418867f9;
    address public constant AETH_ADDRESS = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {
        (
            bytes memory exchangeDataBytes,
            address market,
            uint256 rateMode,
            uint256 gasCost,
            bool isRepay,
            uint256 ethAmount,
            uint256 txValue,
            address user,
            address proxy
        )
        = abi.decode(data, (bytes,address,uint256,uint256,bool,uint256,uint256,address,address));

        // withdraw eth
        TokenInterface(WETH_ADDRESS).withdraw(ethAmount);

        // deposit eth on behalf of proxy
        DSProxy(payable(proxy)).execute{value: ethAmount}(AAVE_BASIC_PROXY, abi.encodeWithSignature("deposit(address,address,uint256)", market, ETH_ADDR, ethAmount));

        bytes memory functionData = packFunctionCall(market, exchangeDataBytes, rateMode, gasCost, isRepay);
        DSProxy(payable(proxy)).execute{value: txValue}(AAVE_SAVER_PROXY, functionData);

        // withdraw deposited eth
        DSProxy(payable(proxy)).execute(AAVE_BASIC_PROXY, abi.encodeWithSignature("withdraw(address,address,uint256)", market, ETH_ADDR, ethAmount));

        // deposit eth, get weth and return to sender
        TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        ERC20(WETH_ADDRESS).safeTransfer(proxy, ethAmount+2);
    }

    function packFunctionCall(address _market, bytes memory _exchangeDataBytes, uint256 _rateMode, uint256 _gasCost, bool _isRepay) internal returns (bytes memory) {
        ExchangeData memory exData = unpackExchangeData(_exchangeDataBytes);

        bytes memory functionData;

        if (_isRepay) {
            functionData = abi.encodeWithSignature("repay(address,(address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256,uint256)", _market, exData, _rateMode, _gasCost);
        } else {
            functionData = abi.encodeWithSignature("boost(address,(address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256,uint256)", _market, exData, _rateMode, _gasCost);
        }

        return functionData;
    }

    /// @dev if contract receive eth, convert it to WETH
    receive() external payable {
        // deposit eth and get weth
        if (msg.sender == owner) {
            TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        }
    }
}
