// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma abicoder v2;


import "./AccessControl.sol";
import "./IERC20.sol";

interface IDEIPool {
    function mintFractionalDEI(
		uint256 collateral_amount,
		uint256 deus_amount,
		uint256 collateral_price,
		uint256 deus_current_price,
		uint256 expireBlock,
		bytes[] calldata sigs
	) external;
}

interface IDEIStablecoin {
    function global_collateral_ratio() external view returns (uint256);
}

interface IUniswapV2Router02 {
	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
	function getAmountsOut(
		uint amountIn, 
		address[] memory path
	) external view returns (uint[] memory amounts);
}


contract SSP is AccessControl {
	bytes32 public constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");
	bytes32 public constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
	bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
	bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
	
    struct ProxyInput {
		uint256 collateral_price;
		uint256 deus_price;
		uint256 expire_block;
        uint min_amount_out;
		bytes[] sigs;
    }
    
    /* ========== STATE VARIABLES ========== */

	address public dei_address;
	address public usdc_address;
	address public deus_address;
	address public dei_pool;
	address public uniswap_router;
	address[] public usdc2deus_path;
	address[] public dei2deus_path;
	address[] public dei2usdc_path;
	address[] public usdc2dei_path;
    uint public while_times;
	uint public usdc_scale = 1e6;
	uint public ratio;
	uint public error_rate= 1e14;
    uint public fee = 1e16;
    uint public fee_scale = 1e18;
	uint public scale = 1e6; // scale for price
	uint public usdc_missing_decimals_d18 = 1e12; // missing decimal of collateral token
	uint public deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;


	/* ========== CONSTRUCTOR ========== */

	constructor(
		address _dei_address, 
		address _usdc_address,
		address _deus_address, 
		address _dei_pool, 
		address _uniswap_router,
		address[] memory _usdc2deus_path,
		address[] memory _dei2usdc_path, 
		address[] memory _usdc2dei_path, 
		address[] memory _dei2deus_path,
		address swapper_address,
		address trusty_address
	) {
		dei_address = _dei_address;
		usdc_address = _usdc_address;
		deus_address = _deus_address;
		dei_pool = _dei_pool;
		uniswap_router = _uniswap_router;
		usdc2deus_path = _usdc2deus_path;
		dei2usdc_path = _dei2usdc_path;
		usdc2dei_path = _usdc2dei_path;
		dei2deus_path = _dei2deus_path;
		while_times = 2;
		IERC20(usdc_address).approve(_uniswap_router, type(uint256).max);
		IERC20(dei_address).approve(_uniswap_router, type(uint256).max);
		IERC20(usdc_address).approve(_dei_pool, type(uint256).max);
		IERC20(deus_address).approve(_dei_pool, type(uint256).max);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		grantRole(SWAPPER_ROLE, swapper_address);
		grantRole(TRUSTY_ROLE, trusty_address);

	}
	///////////////////////////////////////////////////////////////////////////////////////////////////////////
	function swapUsdcForExactDei(uint deiNeededAmount) external {
		require(hasRole(SWAPPER_ROLE, msg.sender), "Caller is not a swapper");
		uint usdcAmount = getAmountIn(deiNeededAmount);
		IERC20(usdc_address).transferFrom(msg.sender, address(this), usdcAmount);
		IERC20(dei_address).transfer(msg.sender, deiNeededAmount);
	}

	function getAmountIn(uint deiNeededAmount) public view returns (uint usdcAmount) {
        uint usdc_amount = deiNeededAmount * fee_scale / ((fee_scale - fee) * usdc_missing_decimals_d18);
        return usdc_amount;
	}
	///////////////////////////////////////////////////////////////////////////////////////////////////////////
	function usdcToDeus(uint usdc_amount) internal returns(uint) {
		uint min_amount_deus = calcUsdcToDeus(usdc_amount);
		uint dei_amount = usdc_amount * ratio / (usdc_scale - ratio);
        uint[] memory deus_arr = IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(dei_amount, min_amount_deus, dei2deus_path, msg.sender, deadline);
        return deus_arr[deus_arr.length - 1];
	}

	function calcUsdcToDeus(uint usdc_amount) public view returns(uint){
		uint dei_amount = usdc_amount * ratio / (usdc_scale - ratio);
		uint[] memory amount_out =IUniswapV2Router02(uniswap_router).getAmountsOut(dei_amount, dei2deus_path);
		return amount_out[amount_out.length -1];
	}

	function setwhileTimes(uint _while_times) external {
	    require(hasRole(SETTER_ROLE, msg.sender), "Caller is not a setter");
		while_times = _while_times;
	}

	function setScale(uint _scale) external {
	    require(hasRole(SETTER_ROLE, msg.sender), "Caller is not a setter");
		scale = _scale;
	}
	
	function setFee(uint _fee) external {
	    require(hasRole(SETTER_ROLE, msg.sender), "Caller is not a setter");
		fee = _fee;
	}
	
	function setFeeScale(uint _fee_scale) external {
	    require(hasRole(SETTER_ROLE, msg.sender), "Caller is not a setter");
		fee_scale = _fee_scale;
	}


	function setRatio(uint _ratio) external {
	    require(hasRole(SETTER_ROLE, msg.sender), "Caller is not a setter");
		ratio = _ratio;
	}

	function setErrorRate(uint _error_rate) external {
	    require(hasRole(SETTER_ROLE, msg.sender), "Caller is not a setter");
		error_rate = _error_rate;
	}
	
	function refill(ProxyInput memory proxy_input, uint usdc_amount, uint excess_deus) public {
	    require(hasRole(OPERATOR_ROLE, msg.sender), "Caller is not a operator");
	    
		uint collateral_ratio = IDEIStablecoin(dei_address).global_collateral_ratio();
    
        require(collateral_ratio > 0 && collateral_ratio < scale, "collateral ratio is not valid");
        
        uint usdc_to_dei = getAmountsInUsdcToDei(collateral_ratio, usdc_amount, proxy_input.deus_price);
        uint usdc_to_deus = (usdc_to_dei * (scale - collateral_ratio) / collateral_ratio) + excess_deus;
        
        // usdc to deus
        uint min_amount_deus = getAmountsOutUsdcToDeus(usdc_to_deus);
        uint[] memory deus_arr = IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(usdc_to_deus, min_amount_deus, usdc2deus_path, address(this), deadline);
        uint deus = deus_arr[deus_arr.length - 1];

        // usdc , deus to dei
        IDEIPool(dei_pool).mintFractionalDEI(
				usdc_to_dei,
				deus,
				proxy_input.collateral_price,
				proxy_input.deus_price,
				proxy_input.expire_block,
				proxy_input.sigs
			);

        // fix arbitrage
        uint[] memory usdc_arr = IUniswapV2Router02(uniswap_router).swapTokensForExactTokens(usdc_to_deus, type(uint256).max , dei2usdc_path, address(this), deadline);
        uint usdc_earned = usdc_arr[usdc_arr.length - 1];

		emit Mint(usdc_to_dei,deus,usdc_earned);
	}
	
	
	function getAmountsInUsdcToDei(uint collateral_ratio, uint usdc_amount, uint deus_price) public view returns(uint) {
		uint usdc_to_dei;
		uint times = while_times;
		while(times > 0) {
			uint usdc_for_swap = usdc_amount * collateral_ratio / scale;
			
			uint usdc_given_to_pairs = usdc_amount - usdc_for_swap;
			uint deus_amount = getAmountsOutUsdcToDeus(usdc_given_to_pairs);

			uint deus_to_usdc = (deus_amount * deus_price) / (scale * usdc_missing_decimals_d18);
			uint usdc_needed = collateral_ratio * deus_to_usdc / (scale - collateral_ratio);
			
			usdc_to_dei += usdc_needed;
			
			usdc_amount -= usdc_given_to_pairs + usdc_needed;
			times -= 1;
		}
		return usdc_to_dei;
	}
	
	
	function getAmountsOutUsdcToDeus(uint usdc_amount) public view returns(uint) {
	    uint[] memory amount_out =IUniswapV2Router02(uniswap_router).getAmountsOut(usdc_amount, usdc2deus_path);
		return amount_out[amount_out.length -1];
	}
	
	function emergencyWithdrawERC20(address token, address to, uint amount) external {
	    require(hasRole(TRUSTY_ROLE, msg.sender), "Caller is not a trusty");
		IERC20(token).transfer(to, amount);
	}

	function emergencyWithdrawETH(address recv, uint amount) external {
	    require(hasRole(TRUSTY_ROLE, msg.sender), "Caller is not a trusty");
		payable(recv).transfer(amount);
	}

	event Mint(uint usdc_to_dei, uint deus, uint usdc_earned);
}