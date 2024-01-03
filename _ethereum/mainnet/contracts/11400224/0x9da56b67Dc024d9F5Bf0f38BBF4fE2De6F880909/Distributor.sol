pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface yVaultInterface is IERC20 {
    function token() external view returns (address);
    function balance() external view returns (uint);
    function deposit(uint _amount) external;
    function withdraw(uint _shares) external;
    function getPricePerFullShare() external view returns (uint);
}

interface Uni {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


library UniformRandomNumber {
  /// @notice Select a random number without modulo bias using a random seed and upper bound
  /// @param _entropy The seed for randomness
  /// @param _upperBound The upper bound of the desired number
  /// @return A random number less than the _upperBound
  function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
    uint256 min = -_upperBound % _upperBound;
    uint256 random = _entropy;
    while (true) {
      if (random >= min) {
        break;
      }
      random = uint256(keccak256(abi.encodePacked(random)));
    }
    return random % _upperBound;
  }
}
// Copyright 2020 PooDaddy
// PooTogether: the best no-loss shitcoin lottery
// https://www.pootogether.com
// https://twitter.com/pootogether

contract Distributor {
	Uni public constant uniswap = Uni(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	
	function shitcoinMenu(uint entropy) public pure returns (address) { 
		uint idx = UniformRandomNumber.uniform(
			entropy,
			40 /* WARNING: ADJUST BASED ON TOKEN COUNT AND CHANCE TO WIN POO */
		);
		if (idx == 0) return address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984); // UNI 
		if (idx == 1) return address(0x62359Ed7505Efc61FF1D56fEF82158CcaffA23D7); // CORE
		if (idx == 2) return address(0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b); // DPI
		if (idx == 3) return address(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5); // PICKLE
		if (idx == 4) return address(0xa0246c9032bC3A600820415aE600c6388619A14D); // FARM
		if (idx == 5) return address(0x514910771AF9Ca656af840dff83E8264EcF986CA); // LINK
		if (idx == 6) return address(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9); // AAVE
		if (idx == 7) return address(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44); // KP3R
		if (idx == 8) return address(0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD); // LRC
		if (idx == 9) return address(0x584bC13c7D411c00c01A62e8019472dE68768430); // HEGIC
		if (idx == 10) return address(0x69692D3345010a207b759a7D1af6fc7F38b35c5E); // CHADS
		if (idx == 11) return address(0x20945cA1df56D237fD40036d47E866C7DcCD2114); // NSURE
		if (idx == 12) return address(0x066798d9ef0833ccc719076Dab77199eCbd178b0); // SAKE
		if (idx == 13) return address(0x8Ab7404063Ec4DBcfd4598215992DC3F8EC853d7); // AKRO
		if (idx == 14) return address(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39); // HEX
		if (idx == 15) return address(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e); // YFI
		if (idx == 16) return address(0x45804880De22913dAFE09f4980848ECE6EcbAf78); // PAXG
		if (idx == 17) return address(0x8888801aF4d980682e47f1A9036e589479e835C5); // MPH
		if (idx == 18) return address(0xa7ED29B253D8B4E3109ce07c80fc570f81B63696); // BAS
		if (idx == 19) return address(0x5D8d9F5b96f4438195BE9b99eee6118Ed4304286); // COVER
		if (idx == 20) return address(0xADE00C28244d5CE17D72E40330B1c318cD12B7c3); // ADX
		if (idx == 21) return address(0x1695936d6a953df699C38CA21c2140d497C08BD9); // SYN
		if (idx == 22) return address(0x09a3EcAFa817268f77BE1283176B946C4ff2E608); // MIR
		// POO
		return address(0xe5a4Dad2Ea987215460379Ab285DF87136E83BEA);
	}
	
	// This contract is not meant to hold any tokens at any point - you're supposed to call distribute() immediately after receiving tokens
	// However, in case tokens are sent to it accidently and stuck, anyone can recover them by calling distribute() with the given inputToken
	function distribute(address inputToken, uint entropy, address winner) external {
		address[] memory path = new address[](3);
		path[0] = inputToken;
		path[1] = WETH;
		path[2] = shitcoinMenu(entropy);
		uint total = IERC20(inputToken).balanceOf(address(this));
		// That's not a safe approval call, but the entire thing will revert w/o damage if it's failing silently
		IERC20(inputToken).approve(address(uniswap), total);
		uniswap.swapExactTokensForTokens(total, uint(0), path, winner, block.timestamp);
		// drop some $POO
		//if (msg.sender == address(PooTogether) && poo.allowance(pooDaddy, address(this)) >= POO_DROP_PER_DRAW)) poo.transferFrom(pooDaddy, winner, POO_DROP_PER_DRAW);
	}
}