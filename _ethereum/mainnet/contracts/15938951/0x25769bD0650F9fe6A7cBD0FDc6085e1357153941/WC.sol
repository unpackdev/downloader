// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./WCMinting.sol";

/**
* @dev The main outer contract that we deploy
**/
contract WorldCupSweepstake is WorldCupSweepstakeMinting {

    /**
     * @dev Builds a metadata URI of the form baseuri/teamid
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        string memory teamId = teamFromTokenId(tokenId).teamId;
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, teamId))
                : "";
    }

    /**
     * @dev Hardcodes the ipfs base URI for tokens
     * NOTE: overrides openzepplin ERC721 contract
     */
    function _baseURI() internal pure override returns (string memory) {
        return
            "https://gateway.pinata.cloud/ipfs/QmU7EDeqv33VySjesK8Ye7bfEepKBsZVd14dreFiGTwyeT/";
    }
}
