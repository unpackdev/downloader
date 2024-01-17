// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

/******
*
*	CryptoComics Token
*
*	https://cryptocomics.world
*
******/
contract CryptoComics is ERC20, ERC20Burnable, Ownable {
	uint deployDate;
	uint256 teamLocked = 150_000_000 * 10 ** decimals();

	constructor() ERC20("CryptoComics", "CCM") {
		deployDate = block.timestamp;

		_mint(address(this), teamLocked); //team

		_mint(0x3C998E39CEd5eC111F2bc76EBC828483DDeAD6a0, 200_000_000 * 10 ** decimals()); //staking, airdrops
		_mint(0x9a690661A54E9047c29f8FF7f59189B966f015c0, 200_000_000 * 10 ** decimals()); //liquidity
		_mint(0xf03C0220e39CebeE51038794B278CF6DcB0ACD4E, 300_000_000 * 10 ** decimals()); //token sale
		_mint(0xb0D573B406a20Ce423D5D84B77B7d2aD89BD014b, 150_000_000 * 10 ** decimals()); //marketing
	}

	modifier canUnlockTeamTokens() {
		require(block.timestamp >= unlockTimeTeamTokens());
		_;
	}

	function unlockTimeTeamTokens() public view virtual returns (uint) {
		return deployDate + 365 days;
	}

	function unlockTeamTokens(address teamAddr)  public virtual onlyOwner canUnlockTeamTokens returns (bool) {
		require(teamLocked > 0, "CryptoComics: All team tokens already unlocked.");
		_transfer(address(this), teamAddr, teamLocked);
		teamLocked = 0;

		return true;
	}
}