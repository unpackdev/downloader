pragma solidity ^0.5.5;

import "./Crowdsale.sol";
import "./CappedCrowdsale.sol";
import "./RFS.sol";
import "./RFSCrowdsale.sol";

contract RFSCrowdsaleDeployer {
    constructor()
    public
    {
	    uint MULTIPLIER = 1000000000000000000; // 18 decimals
        RFS rfsToken = new RFS("RFS", "RFS", 25000*MULTIPLIER);
        address payable multisig = address(0x1237eD8262B07Ea258a1730695e1CEAB7bc403aB);

        RFSCrowdsale crowdsale = new RFSCrowdsale(
            1,               // rate RFS per ETH
            multisig,        // send ETH to multisig 
            rfsToken,        // the token
	        multisig,
	        100*MULTIPLIER
        );

	    // Transfer RFS to the crowdsale
        rfsToken.transfer(address(crowdsale), 100*MULTIPLIER);

	    // Transfer the remains to multisig
        rfsToken.transfer(multisig, 24900*MULTIPLIER);
    }
}
