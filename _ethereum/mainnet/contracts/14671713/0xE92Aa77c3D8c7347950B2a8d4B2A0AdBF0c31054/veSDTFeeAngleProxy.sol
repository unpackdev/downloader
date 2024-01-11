// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./IFeeDistributor.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ICurvePool.sol";
import "./IUniswapRouter.sol";
import "./ISdFraxVault.sol";
import "./Ownable.sol";

contract veSDTFeeAngleProxy is Ownable {
	using SafeERC20 for IERC20;
	address public constant sdFrax3Crv = 0x5af15DA84A4a6EDf2d9FA6720De921E1026E37b7;
	address public constant frax3Crv = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
	address public constant angle = 0x31429d1856aD1377A8A0079410B297e1a9e214c2;
	address public constant feeD = 0x29f3dd38dB24d3935CF1bf841e6b2B461A3E5D92;
	address public constant frax = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
	address public constant sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
	uint256 public claimerFee = 100;
	uint256 public constant BASE_FEE = 10000;
	uint256 public maxSlippage = 100;
	address[] public angleToFraxPath;

	constructor(address[] memory _angleToFraxPath) {
		angleToFraxPath = _angleToFraxPath;
		IERC20(angle).safeApprove(sushiRouter, type(uint256).max);
	}

	function sendRewards() external {
		uint256 angleBalance = IERC20(angle).balanceOf(address(this));
		_swapOnSushi(angleBalance);
		uint256 fraxBalance = IERC20(frax).balanceOf(address(this));
		uint256 claimerPart = (fraxBalance * claimerFee) / BASE_FEE;
		IERC20(frax).transfer(msg.sender, claimerPart);
		IERC20(frax).approve(frax3Crv, fraxBalance - claimerPart);
		ICurvePool(frax3Crv).add_liquidity([fraxBalance - claimerPart, 0], 0);
		uint256 frax3CrvBalance = IERC20(frax3Crv).balanceOf(address(this));
		IERC20(frax3Crv).approve(sdFrax3Crv, fraxBalance - claimerPart);
		ISdFraxVault(sdFrax3Crv).deposit(frax3CrvBalance);
		IERC20(sdFrax3Crv).transfer(feeD, IERC20(sdFrax3Crv).balanceOf(address(this)));
	}

	// slippageCRV = 100 for 1% max slippage
	function _swapOnSushi(uint256 _amount) internal returns (uint256) {
		uint256[] memory amounts = IUniswapRouter(sushiRouter).getAmountsOut(_amount, angleToFraxPath);

		uint256 minAmount = (amounts[angleToFraxPath.length - 1] * (10000 - maxSlippage)) / (10000);

		uint256[] memory outputs = IUniswapRouter(sushiRouter).swapExactTokensForTokens(
			_amount,
			minAmount,
			angleToFraxPath,
			address(this),
			block.timestamp + 1800
		);

		return outputs[1];
	}

	function claimableByKeeper() public view returns (uint256) {
		uint256 angleBalance = IERC20(angle).balanceOf(address(this));
		uint256[] memory amounts = IUniswapRouter(sushiRouter).getAmountsOut(angleBalance, angleToFraxPath);
		uint256 minAmount = (amounts[angleToFraxPath.length - 1] * (10000 - maxSlippage)) / (10000);
		return (minAmount * claimerFee) / BASE_FEE;
	}

	function setSlippage(uint256 newSlippage) external onlyOwner {
		maxSlippage = newSlippage;
	}

	function setClaimerFe(uint256 newClaimerFee) external onlyOwner {
		claimerFee = newClaimerFee;
	}

	function setSwapPath(address[] memory newPath) external onlyOwner {
		angleToFraxPath = newPath;
	}

	function recoverERC20(address _token, uint256 _amount) external onlyOwner {
		IERC20(_token).transfer(owner(), _amount);
	}
}
