// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ISdFraxVault.sol";
import "./Ownable.sol";

interface IBalancerVault {
	enum SwapKind { GIVEN_IN, GIVEN_OUT }
	struct FundManagement {
    	address sender;
    	bool fromInternalBalance;
    	address payable recipient;
    	bool toInternalBalance;
	}
	struct BatchSwapStep {
		bytes32 poolId;
    	uint256 assetInIndex;
    	uint256 assetOutIndex;
    	uint256 amount;
    	bytes userData;
	}
	function batchSwap(
		SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
	) external;
}

interface IAsset {
	// solhint-disable-previous-line no-empty-blocks
}

interface I3PoolZap {
	function add_liquidity(
		address _pool,
		uint[4] calldata _deposit_amounts,
		uint256 _min_mint_amount
	) external;
}

contract VeSDTFeeBalancerProxy is Ownable {
	using SafeERC20 for IERC20;
	address public constant SD_FRAX_3CRV = 0x5af15DA84A4a6EDf2d9FA6720De921E1026E37b7;
	address public constant FRAX_3CRV = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
	address public constant POOL3_DEPOSIT_ZAP = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;
	address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
	address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address public constant FEE_D = 0x29f3dd38dB24d3935CF1bf841e6b2B461A3E5D92;
	address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
	address public constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
	uint256 public claimerFee = 100;
	uint256 public constant BASE_FEE = 10000;
	bytes32 public constant BAL_WETH_P_ID = 0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;
	bytes32 public constant USDC_WETH_P_ID = 0x96646936b91d6b9d7d0c47c496afbf3d6ec7b6f8000200000000000000000019;

	event RewardSent(uint256 claimerAmount, uint256 feeDAmount);

	constructor() {
		IERC20(BAL).safeApprove(BALANCER_VAULT, type(uint256).max);
		IERC20(USDC).approve(POOL3_DEPOSIT_ZAP, type(uint256).max);
		IERC20(FRAX_3CRV).approve(SD_FRAX_3CRV, type(uint256).max);
	}

    /// @notice function to send reward
	function sendRewards() external {
		uint256 balBalance = IERC20(BAL).balanceOf(address(this));
		// Calculate claimer fees in BAL
		uint256 claimerPart = (balBalance * claimerFee) / BASE_FEE;
		IERC20(BAL).transfer(msg.sender, claimerPart);

		// define balancer batch swap structures
		IBalancerVault.BatchSwapStep memory stepBalWeth = IBalancerVault.BatchSwapStep(BAL_WETH_P_ID, 0, 1, balBalance - claimerPart, "");
		IBalancerVault.BatchSwapStep memory stepWethUsdc = IBalancerVault.BatchSwapStep(USDC_WETH_P_ID, 1, 2, 0, "");
		IBalancerVault.BatchSwapStep[] memory steps = new IBalancerVault.BatchSwapStep[](2);
        steps[0] = stepBalWeth;
        steps[1] = stepWethUsdc;

		IBalancerVault.FundManagement memory fm = IBalancerVault.FundManagement(address(this), false, payable(address(this)), false);

		IAsset[] memory assets = new IAsset[](3);
        assets[0] = IAsset(BAL);
        assets[1] = IAsset(WETH);
		assets[2] = IAsset(USDC);

		int256[] memory limits = new int256[](3);
        limits[0] = int256(balBalance - claimerPart);
        limits[1] = 0;
		limits[2] = 0;

		// Swap BAL <-> USDC
		IBalancerVault(BALANCER_VAULT).batchSwap(
			IBalancerVault.SwapKind.GIVEN_IN,
			steps,
			assets,
			fm,
			limits,
			block.timestamp + 1800
		);
		
		uint256 usdcBalance = IERC20(USDC).balanceOf(address(this));
		
        // Add USDC liquidity to the FRAX3CRV pool on curve (using the zapper)
		I3PoolZap(POOL3_DEPOSIT_ZAP).add_liquidity(FRAX_3CRV, [0, 0, usdcBalance, 0], 0);
		uint256 frax3CrvBalance = IERC20(FRAX_3CRV).balanceOf(address(this));
        // Deposit FRAX3CRV LP to StakeDAO
		ISdFraxVault(SD_FRAX_3CRV).deposit(frax3CrvBalance);

		// emit the event before the sdFrax3Crv transfer
		// claimerPart in BAL, feeDistributor part in sdFrax3Crv
		emit RewardSent(claimerPart, IERC20(SD_FRAX_3CRV).balanceOf(address(this)));

        // Transfer SDFRAX3CRV to the veSDT Fee Distributor
		IERC20(SD_FRAX_3CRV).transfer(FEE_D, IERC20(SD_FRAX_3CRV).balanceOf(address(this)));
	}

    // @notice function to calculate the amount reserved for keepers 
	function claimableByKeeper() public view returns (uint256) {
		uint256 balBalance = IERC20(BAL).balanceOf(address(this));
		return (balBalance * claimerFee) / BASE_FEE;
	}

    /// @notice function to set a new claier fee 
	/// @param _newClaimerFee claimer fee
	function setClaimerFee(uint256 _newClaimerFee) external onlyOwner {
        require(_newClaimerFee <= BASE_FEE, ">100%");
		claimerFee = _newClaimerFee;
	}

    /// @notice function to recover any ERC20 and send them to the owner
	/// @param _token token address
	/// @param _amount amount to recover
	function recoverERC20(address _token, uint256 _amount) external onlyOwner {
		IERC20(_token).transfer(owner(), _amount);
	}
}
