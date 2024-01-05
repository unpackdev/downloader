pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ISoloMargin.sol";
import "./SafeERC20.sol";
import "./TokenInterface.sol";
import "./DSProxy.sol";
import "./AaveHelper.sol";
import "./AdminAuth.sol";
import "./DFSExchangeData.sol";

/// @title Import Aave position from account to wallet
contract AaveSaverReceiver is AaveHelper, AdminAuth, DFSExchangeData {

    using SafeERC20 for ERC20;

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant AAVE_SAVER_PROXY = 0x2a3B273695A045EC263970e3C86c23800a0F04FC;
    address public constant AAVE_BASIC_PROXY = 0xd042D4E9B4186c545648c7FfFe87125c976D110B;
    address public constant AETH_ADDRESS = 0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04;

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {

        (
            bytes memory exchangeDataBytes,
            uint256 gasCost,
            bool isRepay,
            uint256 ethAmount,
            uint256 txValue,
            address user,
            address proxy
        )
        = abi.decode(data, (bytes,uint256,bool,uint256,uint256,address,address));

        // withdraw eth
        TokenInterface(WETH_ADDRESS).withdraw(ethAmount);

        address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
        
        // deposit eth on behalf of proxy
        DSProxy(payable(proxy)).execute{value: ethAmount}(AAVE_BASIC_PROXY, abi.encodeWithSignature("deposit(address,uint256)", ETH_ADDR, ethAmount));
        
        bytes memory functionData = packFunctionCall(exchangeDataBytes, gasCost, isRepay);
        DSProxy(payable(proxy)).execute{value: txValue}(AAVE_SAVER_PROXY, functionData);

        // withdraw deposited eth
        DSProxy(payable(proxy)).execute(AAVE_BASIC_PROXY, abi.encodeWithSignature("withdraw(address,address,uint256,bool)", ETH_ADDR, AETH_ADDRESS, ethAmount, false));

        // deposit eth, get weth and return to sender
        TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        ERC20(WETH_ADDRESS).safeTransfer(proxy, ethAmount+2);
    }

    function packFunctionCall(bytes memory _exchangeDataBytes, uint256 _gasCost, bool _isRepay) internal returns (bytes memory) {
        ExchangeData memory exData = unpackExchangeData(_exchangeDataBytes);

        bytes memory functionData;

        if (_isRepay) {
            functionData = abi.encodeWithSignature("repay((address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256)", exData, _gasCost);
        } else {
            functionData = abi.encodeWithSignature("boost((address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256)", exData, _gasCost);
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