pragma solidity ^0.8.0;

import "./ERC20Capped.sol";
import "./Ownable.sol";

contract CoiinToken is ERC20Capped, Ownable {
	/// @notice The monthly allowed COIIN to be minted
	uint256 public constant maxMintMonthly = 25000000 * 1e18;
	uint256 public constant minMintMonthly = 1000000 * 1e18;

	constructor(address _mintAddress) ERC20("Coiin", "COIIN") ERC20Capped(1000000000 * 1e18) public {
		// initial supply 100000000
		ERC20._mint(_mintAddress, 100000000 * 1e18);

	}

    function mint(address _to, uint256 amount) external onlyOwner returns(bool) {
        _mint(_to, amount);
        return true;
    }
}
