import "./ERC20.sol";
import "./SafeMath.sol";

pragma solidity ^0.8.11;
// SPDX-License-Identifier: Unlicensed

contract Hoge2 is ERC20 {
	using SafeMath for uint256;
	IERC20 HOGE = IERC20(0xfAd45E47083e4607302aa43c65fB3106F1cd7607);
	constructor() ERC20("Hoge2.0", "HOGE2") {}

	function decimals() public view virtual override returns (uint8) {
	    return 9;
	}

	function wrap(uint256 hogeAmount) public {
		//Mint HOGE2 on receipt of HOGE
		require(HOGE.balanceOf(msg.sender) >= hogeAmount, "Insufficient HOGE balance.");
		HOGE.transferFrom(msg.sender, address(this), hogeAmount);
		_mint(msg.sender, hogeAmount.mul(98) / 100);
	}

	function unwrap(uint256 hoge2Amount) public {
		//Burn HOGE2 on withdrawal of HOGE.
		require(balanceOf(msg.sender) >= hoge2Amount, "Insufficient HOGE2 balance.");
		HOGE.transfer(msg.sender, hoge2Amount);
		_burn(msg.sender, hoge2Amount);
	}

	function burnableHoge() public view returns (uint256) {
		//Balance in excess of owed HOGE.
		return HOGE.balanceOf(address(this)).sub(this.totalSupply());
	}

	function burnHoge() public returns (uint256) {
		//Burn off excess reflected HOGE
		uint256 burnable = this.burnableHoge();
		HOGE.transfer(0x000000000000000000000000000000000000dEaD, burnable);
		return burnable;
	}
}