pragma solidity ^0.5.5;

import "./Crowdsale.sol";
import "./CappedCrowdsale.sol";

contract RFSCrowdsale is Crowdsale, CappedCrowdsale {
    constructor(
        uint256 rate,
        address payable wallet,
        IERC20 token,
	address rfsMultiSignatureWallet,
	uint256 cap
    )
    CappedCrowdsale(cap)
    Crowdsale(rate, wallet, token)
    public
    {
    }
}
