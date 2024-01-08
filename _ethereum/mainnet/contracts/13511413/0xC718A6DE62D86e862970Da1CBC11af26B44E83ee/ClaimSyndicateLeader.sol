// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./DeepSkyNetwork.sol";
import "./Syndicates.sol";
import "./TheLostGlitches.sol";

contract ClaimSyndicateLeader {
    TheLostGlitches public tlg;
    DeepSkyNetwork public dsn;
    Syndicates public syndicates;
    mapping(uint256 => bool) public hasClaimed;

    constructor(
        address _tlg,
        address _dsn,
        address _syn
    ) {
        tlg = TheLostGlitches(_tlg);
        dsn = DeepSkyNetwork(_dsn);
        syndicates = Syndicates(_syn);
    }

    function claim(uint256 glitch) public {
        require(hasClaimed[glitch] == false, "CLAIM_NFT: ALREADY_CLAIMED");
        require(_isApprovedOrOwner(msg.sender, glitch), "THE_LOST_GLITCHES: NOT_APPROVED");

        uint256 syndicate = syndicates.syndicate(glitch);
        require(syndicate != 0, "SYNDICATE: NOT_A_MEMBER");
        require(1 <= syndicate && syndicate <= 5, "SYNDICATE: INVALID_SYNDICATE");

        address owner = tlg.ownerOf(glitch);

        hasClaimed[glitch] = true;

        // Song of the Chain
        if (syndicate == 1) {
            // Elaine Jones
            dsn.mint(owner, 11, 1, "");
        }
        // Curators Maxima
        else if (syndicate == 2) {
            // Dareion Magdy
            dsn.mint(owner, 10, 1, "");
        }
        // Adamant Hands
        else if (syndicate == 3) {
            // Daphne Caracci
            dsn.mint(owner, 9, 1, "");
        }
        // Sentinels of Eternity
        else if (syndicate == 4) {
            // Asahi Nomura
            dsn.mint(owner, 8, 1, "");
        }
        // Guardians of the Source
        else if (syndicate == 5) {
            // Ephira
            dsn.mint(owner, 12, 1, "");
        }
    }

    function _isApprovedOrOwner(address operator, uint256 glitch) internal view virtual returns (bool) {
        require(tlg.exists(glitch), "ERC721: operator query for nonexistent token");
        address owner = tlg.ownerOf(glitch);
        return (operator == owner || tlg.getApproved(glitch) == operator || tlg.isApprovedForAll(owner, operator));
    }
}
