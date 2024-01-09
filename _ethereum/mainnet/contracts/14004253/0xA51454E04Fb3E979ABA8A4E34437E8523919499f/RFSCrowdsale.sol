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

    // Bypass default previous transfer gas limit of 2300
    function _forwardFunds() internal {
        (bool success,) = wallet().call.value(msg.value)('');
        require(success, 'Failed to forward funds');
    }
}
