pragma solidity =0.6.6;

import "./Vester.sol";

contract VesterStepped is Vester {

	constructor(
		address imx_,
		address recipient_,
		uint vestingAmount_,
		uint vestingBegin_,
		uint vestingEnd_
	) public Vester(imx_, recipient_, vestingAmount_, vestingBegin_, vestingEnd_) {}
	
	function vestingCurve(uint x) public virtual override pure returns (uint y) {
		uint speed = 1e18;
		for (uint i = 0; i < 100e16; i += 1e16) {
			if (x < i) return y;
			y += speed;
			speed = speed * 976 / 1000;
		}
	}

}