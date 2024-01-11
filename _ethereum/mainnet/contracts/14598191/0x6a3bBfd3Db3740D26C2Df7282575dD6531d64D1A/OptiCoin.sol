import "./ERC20.sol";

contract OptiCoin is ERC20 {
	constructor() ERC20("OptiSwap.pro", "OPTICOIN") {
		_mint(msg.sender, 10**9 * 10**18);
	}
}
