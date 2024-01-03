pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./AaveHelperV2.sol";
import "./DFSExchangeCore.sol";
import "./IAToken.sol";
import "./TokenInterface.sol";
import "./DefisaverLogger.sol";
import "./GasBurner.sol";

contract AaveSaverProxyV2 is DFSExchangeCore, AaveHelperV2, GasBurner {

	address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

	function repay(address _market, ExchangeData memory _data, uint _rateMode, uint _gasCost) public payable burnGas(20) {
		address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
		IAaveProtocolDataProviderV2 dataProvider = getDataProvider(_market);
		address payable user = payable(getUserAddress());

		ILendingPoolV2(lendingPool).withdraw(_data.srcAddr, _data.srcAmount, address(this));

		uint256 destAmount = _data.srcAmount;
		if (_data.srcAddr != _data.destAddr) {
			_data.user = user;
			
			_data.dfsFeeDivider = MANUAL_SERVICE_FEE;
			if (BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin)) {
            	_data.dfsFeeDivider = AUTOMATIC_SERVICE_FEE;
        	}
			
			// swap
			(, destAmount) = _sell(_data);
		}

		// take gas cost at the end
		destAmount -= getGasCost(ILendingPoolAddressesProviderV2(_market).getPriceOracle(), destAmount, user, _gasCost, _data.destAddr);

		// payback
		if (_data.destAddr == WETH_ADDRESS) {
			TokenInterface(WETH_ADDRESS).deposit.value(destAmount)();
		}

		approveToken(_data.destAddr, lendingPool);

		// if destAmount higher than borrow repay whole debt
		uint borrow;
		if (_rateMode == STABLE_ID) {
			(,borrow,,,,,,,) = dataProvider.getUserReserveData(_data.destAddr, address(this));	
		} else {
			(,,borrow,,,,,,) = dataProvider.getUserReserveData(_data.destAddr, address(this));
		}
		ILendingPoolV2(lendingPool).repay(_data.destAddr, destAmount > borrow ? borrow : destAmount, _rateMode, payable(address(this)));

		// first return 0x fee to tx.origin as it is the address that actually sent 0x fee
		sendContractBalance(ETH_ADDR, tx.origin, min(address(this).balance, msg.value));
		// send all leftovers from dest addr to proxy owner
		sendFullContractBalance(_data.destAddr, user);

		DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "AaveV2Repay", abi.encode(_data.srcAddr, _data.destAddr, _data.srcAmount, destAmount));
	}

	function boost(address _market, ExchangeData memory _data, uint _rateMode, uint _gasCost) public payable burnGas(20) {
		address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
		IAaveProtocolDataProviderV2 dataProvider = getDataProvider(_market);
		address payable user = payable(getUserAddress());

		// borrow amount
		ILendingPoolV2(lendingPool).borrow(_data.srcAddr, _data.srcAmount, _rateMode, AAVE_REFERRAL_CODE, address(this));

		// take gas cost at the beginning
		_data.srcAmount -= getGasCost(ILendingPoolAddressesProviderV2(_market).getPriceOracle(), _data.srcAmount, user, _gasCost, _data.srcAddr);

		uint256 destAmount;
		if (_data.destAddr != _data.srcAddr) {
			_data.user = user;
			
			_data.dfsFeeDivider = MANUAL_SERVICE_FEE;
			if (BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin)) {
            	_data.dfsFeeDivider = AUTOMATIC_SERVICE_FEE;
        	}
        	
			(, destAmount) = _sell(_data);
		} else {
			destAmount = _data.srcAmount;
		}

		if (_data.destAddr == WETH_ADDRESS) {
			TokenInterface(WETH_ADDRESS).deposit.value(destAmount)();
		}

		approveToken(_data.destAddr, lendingPool);
		ILendingPoolV2(lendingPool).deposit(_data.destAddr, destAmount, address(this), AAVE_REFERRAL_CODE);


		(,,,,,,,,bool collateralEnabled) = dataProvider.getUserReserveData(_data.destAddr, address(this));
		if (!collateralEnabled) {
            ILendingPoolV2(lendingPool).setUserUseReserveAsCollateral(_data.destAddr, true);
        }

		// returning to msg.sender as it is the address that actually sent 0x fee
		sendContractBalance(ETH_ADDR, tx.origin, min(address(this).balance, msg.value));
		// send all leftovers from dest addr to proxy owner
		sendFullContractBalance(_data.destAddr, user);

		DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "AaveV2Boost", abi.encode(_data.srcAddr, _data.destAddr, _data.srcAmount, destAmount));
	}
}
