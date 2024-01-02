pragma solidity ^0.8.20;

import "./MerkleProof.sol";
import "./IUniswapV2Router02.sol";

import "./IWETH.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";
import "./console2.sol";

interface OZIERC20 is IERC20 {
	function increaseAllowance(address spender, uint256 amount) external returns (bool);
}

// A new contract with a new address is used to avoid the NFT contract to manipulate RG
contract UseOnce {
	// 10% slippage for bot honeypotting
	function f90pc(uint256 value) pure internal returns (uint256) {
		return (value * 90) / 100;
	}
	constructor(address from, address inMemoryOf, address _dao) payable {
		IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		OZIERC20 RG = OZIERC20(0x2C91D908E9fab2dD2441532a04182d791e590f2d);
		IERC20 WETH = IERC20(uniswapRouter.WETH());

		// Initialize address[] memory path  with Weth and RG pair
		address[] memory path = new address[](2);
		path[0] = address(WETH);
		path[1] = address(RG);

		// Take half of the msg.value
		uint256 amount = msg.value >> 1;
		// half of the ETH amount is now RG, increasing RG price
        uint[] memory maxOuts = uniswapRouter.getAmountsOut(amount, path);
		uniswapRouter.swapExactETHForTokens{value: amount}(maxOuts[1], path, address(this), block.timestamp + 60);
		IWETH(address(WETH)).deposit{value: msg.value - amount}();
		WETH.approve(address(uniswapRouter), type(uint256).max);
		// Send 1 RG towards the sender
		RG.transfer(from, 1);
		// Send 1 RG towards the account to remember account
		RG.transfer(inMemoryOf, 1);
		uint256 RGAmount = RG.balanceOf(address(this));
		// add liquitidy to the pool
		RG.increaseAllowance(address(uniswapRouter), RGAmount);
		// send the LP RG to DAO
		uniswapRouter.addLiquidity(path[1], path[0], RGAmount, msg.value - amount,
								f90pc(RGAmount), f90pc(msg.value - amount),
								   _dao, block.timestamp + 60);
		// transfer RG remaining to SENDER
		RGAmount = RG.balanceOf(address(this));
		path[0] = address(RG);
		path[1] = address(WETH);
		// swap remaining RG to ETH and send to dao
		// 10% slippage for bot honeypotting
		if (RGAmount > 0) {
            maxOuts = uniswapRouter.getAmountsOut(RGAmount, path);
			uniswapRouter.swapExactTokensForTokens(RGAmount, f90pc(maxOuts[1]), path, _dao, block.timestamp + 60);
		    RGAmount = RG.balanceOf(address(this));
		}
		// transfer WETH remaining to DAO
		amount = WETH.balanceOf(address(this));
		if (amount > 0) {
			WETH.transfer(_dao, amount);
		}
		// transfer RG remaining to SENDER
		RGAmount = RG.balanceOf(address(this));
		if (RGAmount > 0) {
			RG.transfer(from, RGAmount);
		}
	}
}

interface IPricing {
  function getPrice(uint256 color) external returns (uint256 price, uint256 errno);
  function getPrice(uint256 color, bytes calldata proof) external returns (uint256 price, uint256 errno);
  function payment(address from, address destination, address dao) payable external;
  function baseURI() external view returns (string memory);
}

contract Pricing is IPricing {
	string public baseURI = "https://rge.6120.eu/nft/";
	constructor (bytes32 _couponRoot) {
		couponRoot_ = _couponRoot;
	}
	// Structure of a coupon with the bytes32 proof and the reduction percentage
	struct Coupon {
		bytes32[] proof;
		// First 1 bits is type
		// 0: Percentage
		// 1: address max reduction
		uint256 reduction;
	}
	// Mapping of the used coupons
	bytes32 public couponRoot_;
	mapping (bytes32 => bool) public usedCoupons_;

    function payment(address from, address inMemoryOf, address dao) payable external override {
		new UseOnce{value: msg.value}(from, inMemoryOf, dao);
	}
    function getPrice(uint256 color) public returns (uint256, uint256) {
		bytes memory proof = "";
		return getPrice(color, proof);
	}
	function isValidCoupon(bytes memory proof) public view returns (bool, bytes32 leaf, Coupon memory coupon) {
			// Unpack proof
			coupon = abi.decode(proof, (Coupon));
			leaf = keccak256(bytes.concat(keccak256(abi.encode(coupon.reduction))));
			// Verify proof
			return (MerkleProof.verify(coupon.proof, couponRoot_, leaf),
					keccak256(bytes.concat(keccak256(abi.encode(coupon)))), coupon);
	}

    function getPrice(uint256 color, bytes memory proof) public returns (uint256, uint256) {
        uint256 r = (color & 0xFF0000) >> 16;
        uint256 g = (color & 0x00FF00) >> 8;
        uint256 b = (color & 0x0000FF);
        uint256 CMax = r;
        if (g > CMax) CMax = g;
        if (b > CMax) CMax = b;

        uint256 CMin = r;
        if (g < CMin) CMin = g;
        if (b < CMin) CMin = b;

        CMax = (CMax * 1 ether ) / 255;
        CMin = (CMin * 1 ether ) / 255;

        if (CMax == 0) {
            return (0, 1); // Black // already used
        }

        uint256 value = CMax;
        uint256 sat = (((1 ether * (CMax - CMin)) / CMax) * 1 ether ) / 1 ether;

        // Case 1:
        // If (value + sat) is below 100% if mainly brightness
        // pricing on that solely
        // Case 2: 
        // Above the 50% brightPrice, there is more color
		uint256 price = (value + sat < 1 ether) ? value : value + sat;
        // See https://www.peko-step.com/en/tool/colorchart_en.html for vizualisation
        if (proof.length > 0) {
			// Check if coupon is valid
			(bool isValid, bytes32 leaf, Coupon memory coupon) = isValidCoupon(proof);
			if (!isValid) {
				return (price, 2); // Invalid coupon
			}
			if (usedCoupons_[leaf]) {
				return (price, 3); // Already used coupon
			}
			// Mark it as used using proof+leaf
			usedCoupons_[leaf] = true;
			
			// Apply discount
			if (coupon.reduction >> 255 == 1) {
				// Address reduction
				address couponAddress = address(uint160((~(uint256(1)<<255)) & coupon.reduction));
				require(tx.origin == couponAddress, "Not your coupon");
				price = price / 100; // 1% reduction
			} else {
				// Percentage reduction
				uint256 couponPercentage = coupon.reduction;
				price = (couponPercentage * price) / 10000;
			}
		}
		return (price, 0);
    }
}
