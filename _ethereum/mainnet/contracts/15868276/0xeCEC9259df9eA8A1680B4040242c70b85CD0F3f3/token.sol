// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./LockableRevealERC721EnumerableToken.sol";
contract token is LockableRevealERC721EnumerableToken {

    constructor()
    LockableRevealERC721EnumerableToken(
        666,                           // _projectID
        666,                         // _maxSupply
        "House of Dead Knights",              // _name
        "HoDK",                    // _symbol
        "https://ether-cards.mypinata.cloud/ipfs/QmP95eqtPquPHizvwexGixLeefGAB2mRgJQLmZTXxXgZkJ",  // _tokenPreRevealURI
        "",  // _tokenRevealURI
        false,                        // _transferLocked
        0,                            // _reservedSupply
        0                             // _giveawaySupply
    ) 
    {
    }

}