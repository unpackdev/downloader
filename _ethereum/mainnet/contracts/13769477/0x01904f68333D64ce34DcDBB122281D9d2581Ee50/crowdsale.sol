pragma solidity ^0.5.5;

import "./Crowdsale.sol";
import "./PausableCrowdsale.sol";
import "./AllowanceCrowdsale.sol";

contract TokenCrowdsale is Crowdsale, PausableCrowdsale, AllowanceCrowdsale {
    constructor(
        uint256 rate,
        address payable wallet,
        IERC20 token,
		address tokenWallet
    )
	AllowanceCrowdsale(tokenWallet)
	Crowdsale(rate, wallet, token)
	public
    {

    }
}
