pragma solidity =0.6.6;

import "./Vester.sol";

contract VesterSale is Vester {

	constructor(
		address imx_,
		address recipient_,
		uint vestingAmount_,
		uint vestingBegin_,
		uint vestingEnd_
	) public Vester(imx_, recipient_, vestingAmount_, vestingBegin_, vestingEnd_) {}
	
	function getUnlockedAmount() internal virtual override returns (uint amount) {
		uint blockTimestamp = getBlockTimestamp();
		uint currentPoint = vestingCurve( (blockTimestamp - vestingBegin).mul(1e18).div(vestingEnd - vestingBegin) );
		amount = vestingAmount.mul(currentPoint.sub(previousPoint)).div(finalPoint).mul(8).div(10);
		if (previousPoint == 0 && currentPoint > 0) {
			// distribute 20% on TGE
			amount = amount.add(vestingAmount.div(5));
		}
		previousPoint = currentPoint;
	}

}