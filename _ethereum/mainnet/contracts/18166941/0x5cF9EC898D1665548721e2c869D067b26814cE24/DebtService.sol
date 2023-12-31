// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./IERC20.sol";
import "./Arrays.sol";
import "./SafeCast.sol";
import "./IGToken.sol";
import "./ISToken.sol";
import "./IDToken.sol";
import "./Types.sol";
import "./ExchequerService.sol";
import "./StrategusService.sol";

library DebtService {
	using ExchequerService for Types.Exchequer;
	using SafeCast for uint256; 

	event CreateLineOfCredit(
		uint128 indexed id,
		uint128 rate,
		address indexed borrower,
		address indexed exchequer,
		uint256 borrowMax,
		uint40 expirationTimestamp
	);

	event OriginationFee(
		uint128 indexed id,
		address indexed borrower,
		address indexed exchequer,
		uint256 borrowMax,
		uint256 feeAmount
	);

	event Borrow(
		uint128 indexed lineOfCreditId,
		uint128 rate,
		address indexed borrower,
		address indexed exchequer,
		uint256 amount
	);

	event Repay(
		uint128 indexed lineOfCreditId,
		address indexed borrower,
		address indexed exchequer,
		uint256 amount
	);

	event Delinquent(
		uint128 indexed lineOfCreditId,
		address indexed borrower,
		address indexed exchequer,
		uint256 remainingBalance,
		uint40 expirationTimestamp
	);

	event CloseLineOfCredit(
		uint128 indexed lineOfCreditId,
		address indexed borrower,
		address indexed exchequer,
		uint40 expirationTimestamp
	);

	function createLineOfCredit(
		mapping(address => Types.Exchequer) storage exchequers,
		mapping(address => Types.LineOfCredit) storage linesOfCredit,
		uint256 linesOfCreditCount,
		address borrower,
		address underlyingAsset,
		uint256 borrowMax,
		uint128 rate,
		uint40 termDays
	) internal {
		Types.Exchequer storage exchequer = exchequers[underlyingAsset];
		uint256 protocolBorrowFee = exchequer.calculateProtocolFee(borrowMax);
		StrategusService.guardCreateLineOfCredit(
			exchequer,
			linesOfCredit,
			underlyingAsset,
			borrower,
			borrowMax,
			protocolBorrowFee
		);
		linesOfCredit[borrower].underlyingAsset = underlyingAsset;
		IDToken(exchequer.dTokenAddress).updateRate(borrower, rate);
		linesOfCredit[borrower].creationTimestamp = uint40(block.timestamp);
		linesOfCredit[borrower].expirationTimestamp = uint40(block.timestamp + termDays * 1 days);
		linesOfCredit[borrower].id = uint128(linesOfCreditCount + 1);
		linesOfCredit[borrower].deliquent = false;		
		linesOfCredit[borrower].borrowMax = borrowMax;
		exchequer.totalDebt += linesOfCredit[borrower].borrowMax;
		ISToken(exchequer.sTokenAddress).transferOnOrigination(borrower, protocolBorrowFee);
		emit OriginationFee(
			linesOfCredit[borrower].id,
			borrower,
			underlyingAsset,
			borrowMax,
			protocolBorrowFee
		);

		emit CreateLineOfCredit(
			linesOfCredit[borrower].id,
			rate,
			borrower,
			underlyingAsset,
			borrowMax,
			linesOfCredit[borrower].expirationTimestamp
		);
	}

	function borrow(
		mapping(address => Types.Exchequer) storage exchequers,
		mapping(address => Types.LineOfCredit) storage linesOfCredit,
		address underlyingAsset,
		uint256 amount
	) internal {
		Types.Exchequer storage exchequer = exchequers[underlyingAsset];
		uint128 rate = IDToken(exchequer.dTokenAddress).userRate(msg.sender);
		exchequer.update();
		StrategusService.guardBorrow(
			exchequer,
			linesOfCredit,
			msg.sender,
			amount
		);
		IDToken(exchequer.dTokenAddress).mint(
			msg.sender,
			amount
		);
		exchequer.updateSupplyRate();
		ISToken(exchequer.sTokenAddress).transferUnderlying(msg.sender, amount);
		emit Borrow(
			linesOfCredit[msg.sender].id,
			rate,
			msg.sender,
			underlyingAsset,
			amount
		);
	}

	function repay(
		mapping(address => Types.Exchequer) storage exchequers,
		mapping(address => Types.LineOfCredit) storage linesOfCredit,
		address underlyingAsset,
		uint256 amount
	) internal {
		Types.Exchequer storage exchequer = exchequers[underlyingAsset];
		exchequer.update();
		
		StrategusService.guardRepay(
			exchequer,
			linesOfCredit,
			msg.sender,
			amount
		);
		IDToken(exchequer.dTokenAddress).burn(
			msg.sender,
			amount
		);
		IERC20(underlyingAsset).transferFrom(msg.sender, exchequer.sTokenAddress, amount);
		exchequer.updateSupplyRate();
		linesOfCredit[msg.sender].lastRepaymentTimestamp = uint40(block.timestamp);
		emit Repay(
			linesOfCredit[msg.sender].id,
			msg.sender,
			underlyingAsset,
			amount
		);
	}

	function markDelinquent(
		mapping(address => Types.Exchequer) storage exchequers,
		mapping(address => Types.LineOfCredit) storage linesOfCredit,
		address borrower,
		address underlyingAsset
	) internal {
		Types.Exchequer storage exchequer = exchequers[underlyingAsset];
		StrategusService.guardDelinquency(
			exchequer,
			linesOfCredit,
			borrower
		);
		uint256 remainingBalance = IDToken(exchequer.dTokenAddress).balanceOf(borrower);
		// uint256 userBalance = ISToken(exchequer.sTokenAddress).balanceOf(borrower);
		linesOfCredit[borrower].deliquent = true;
		// handle liquidation here
		// address exchequerSafe = ISToken(exchequer.sTokenAddress).getExchequerSafe();
		// if (remainingBalance > userBalance) {
		// 	ISToken(exchequer.sTokenAddress).transferOnLiquidation(
		// 		borrower,
		// 		exchequerSafe,
		// 		userBalance
		// 	);
		// 	ISToken(exchequer.sTokenAddress).transferUnderlying(
		// 		exchequer.sTokenAddress, 
		// 		userBalance
		// 	);
		// 	IDToken(exchequer.dTokenAddress).burn(
		// 		borrower,
		// 		userBalance
		// 	);
		// } else {
		// 	ISToken(exchequer.sTokenAddress).transferOnLiquidation(
		// 		borrower,
		// 		exchequerSafe,
		// 		remainingBalance
		// 	);
		// 	ISToken(exchequer.sTokenAddress).transferUnderlying(
		// 		exchequer.sTokenAddress, 
		// 		remainingBalance
		// 	);
		// 	IDToken(exchequer.dTokenAddress).burn(
		// 		borrower,
		// 		remainingBalance
		// 	);
		// }

		// uint256 postRemainingBalance = IDToken(exchequer.dTokenAddress).balanceOf(borrower);
		// uint256 grantCollateralBalance = IERC20(underlyingAsset).balanceOf(exchequer.gTokenAddress);

		// if (postRemainingBalance > grantCollateralBalance) {
		// 	IERC20(underlyingAsset).transferFrom(
		// 		exchequer.gTokenAddress, 
		// 		exchequer.sTokenAddress, 
		// 		grantCollateralBalance
		// 	);
		// } else {
		// 	IERC20(underlyingAsset).transferFrom(
		// 		exchequer.gTokenAddress, 
		// 		exchequer.sTokenAddress, 
		// 		postRemainingBalance
		// 	);
		// }

		emit Delinquent(
			linesOfCredit[borrower].id,
			borrower,
			underlyingAsset,
			remainingBalance,
			linesOfCredit[borrower].expirationTimestamp
		);
	}

	function closeLineOfCredit(
		mapping(address => Types.Exchequer) storage exchequers,
		mapping(address => Types.LineOfCredit) storage linesOfCredit,
		address borrower,
		address underlyingAsset
	) internal {
		Types.Exchequer storage exchequer = exchequers[underlyingAsset];
		if (exchequer.totalDebt <= linesOfCredit[borrower].borrowMax) {
			exchequer.totalDebt = 0;
		} else {
			exchequer.totalDebt -= linesOfCredit[borrower].borrowMax;
		}
		
		uint128 logId = linesOfCredit[borrower].id;
		uint40 logExpirationTimestamp = linesOfCredit[borrower].expirationTimestamp;
		delete linesOfCredit[borrower];
		emit CloseLineOfCredit(
			logId,
			borrower,
			underlyingAsset,
			logExpirationTimestamp
		);
	}
}