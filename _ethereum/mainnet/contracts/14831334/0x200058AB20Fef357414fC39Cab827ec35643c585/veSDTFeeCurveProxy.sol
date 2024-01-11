// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./IFeeDistributor.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ICurvePool.sol";
import "./IUniswapRouter.sol";
import "./ISdFraxVault.sol";
import "./Ownable.sol";

contract veSDTFeeCurveProxy is Ownable {
	using SafeERC20 for IERC20;
	address public constant SD_FRAX_3CRV = 0x5af15DA84A4a6EDf2d9FA6720De921E1026E37b7;
	address public constant FRAX_3CRV = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
	address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
	address public constant FEE_D = 0x29f3dd38dB24d3935CF1bf841e6b2B461A3E5D92;
	address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
	address public constant SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
	uint256 public claimerFee = 100;
	uint256 public constant BASE_FEE = 10000;
	uint256 public maxSlippage = 100;
	address[] public crvToFraxPath;

	event RewardSent(uint256 claimerAmount, uint256 feeDAmount);

	constructor(address[] memory _crvToFraxPath) {
		crvToFraxPath = _crvToFraxPath;
		IERC20(CRV).safeApprove(SUSHI_ROUTER, type(uint256).max);
	}

    /// @notice function to send reward
	function sendRewards() external {
        // Swap CRV <-> FRAX
		uint256 crvBalance = IERC20(CRV).balanceOf(address(this));
		_swapOnSushi(crvBalance);

		uint256 fraxBalance = IERC20(FRAX).balanceOf(address(this));
		uint256 claimerPart = (fraxBalance * claimerFee) / BASE_FEE;
        // Send FRAX to keeper claimer 
		IERC20(FRAX).transfer(msg.sender, claimerPart);
        // Add FRAX liquidity to the FRAX3CRV pool on curve
		IERC20(FRAX).approve(FRAX_3CRV, fraxBalance - claimerPart);
		ICurvePool(FRAX_3CRV).add_liquidity([fraxBalance - claimerPart, 0], 0);
		uint256 frax3CrvBalance = IERC20(FRAX_3CRV).balanceOf(address(this));
		IERC20(FRAX_3CRV).approve(SD_FRAX_3CRV, fraxBalance - claimerPart);
        // Deposit FRAX3CRV LP to StakeDAO
		ISdFraxVault(SD_FRAX_3CRV).deposit(frax3CrvBalance);

		// emit the event before the sdFrax3Crv transfer
		// claimerPart in FRAX, feeDistributor part in sdFrax3Crv
		emit RewardSent(claimerPart, IERC20(SD_FRAX_3CRV).balanceOf(address(this)));

        // Transfer SDFRAX3CRV to the veSDT Fee Distributor
		IERC20(SD_FRAX_3CRV).transfer(FEE_D, IERC20(SD_FRAX_3CRV).balanceOf(address(this)));
	}

    /// @notice internal function to swap CRV to FRAX
    /// @dev slippageCRV = 100 for 1% max slippage
	/// @param _amount amount to swap
	function _swapOnSushi(uint256 _amount) internal returns (uint256) {
		uint256[] memory amounts = IUniswapRouter(SUSHI_ROUTER).getAmountsOut(_amount, crvToFraxPath);

		uint256 minAmount = (amounts[crvToFraxPath.length - 1] * (10000 - maxSlippage)) / (10000);

		uint256[] memory outputs = IUniswapRouter(SUSHI_ROUTER).swapExactTokensForTokens(
			_amount,
			minAmount,
			crvToFraxPath,
			address(this),
			block.timestamp + 1800
		);
		return outputs[1];
	}

    /// @notice function to calculate the amount reserved for keepers 
	function claimableByKeeper() public view returns (uint256) {
		uint256 crvBalance = IERC20(CRV).balanceOf(address(this));
		uint256[] memory amounts = IUniswapRouter(SUSHI_ROUTER).getAmountsOut(crvBalance, crvToFraxPath);
		uint256 minAmount = (amounts[crvToFraxPath.length - 1] * (10000 - maxSlippage)) / (10000);
		return (minAmount * claimerFee) / BASE_FEE;
	}

    /// @notice function to set a new max slippage
	/// @param _newSlippage new slippage to set
	function setSlippage(uint256 _newSlippage) external onlyOwner {
        require(_newSlippage <= BASE_FEE, ">100%");
		maxSlippage = _newSlippage;
	}

    /// @notice function to set a new claier fee 
	/// @param _newClaimerFee claimer fee
	function setClaimerFe(uint256 _newClaimerFee) external onlyOwner {
        require(_newClaimerFee <= BASE_FEE, ">100%");
		claimerFee = _newClaimerFee;
	}

    /// @notice function to set the sushiswap swap path  (CRV <-> .. <-> FRAX)
	/// @param _newPath swap path
	function setSwapPath(address[] memory _newPath) external onlyOwner {
        require(_newPath[0] == CRV, "wrong from token");
        require(_newPath[_newPath.length - 1] == FRAX, "wrong to token");
		crvToFraxPath = _newPath;
	}

    /// @notice function to recover any ERC20 and send them to the owner
	/// @param _token token address
	/// @param _amount amount to recover
	function recoverERC20(address _token, uint256 _amount) external onlyOwner {
		IERC20(_token).transfer(owner(), _amount);
	}
}
