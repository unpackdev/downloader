// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz + @quentinmerabet

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ██████████████▌          ╟██           ████████████████          j██████████████  //
//  ██████████████▌          ╟███           ███████████████          j██████████████  //
//  ██████████████▌          ╟███▌           ██████████████          j██████████████  //
//  ██████████████▌          ╟████▌           █████████████          j██████████████  //
//  ██████████████▌          ╟█████▌          ╙████████████          j██████████████  //
//  ██████████████▌          ╟██████▄          ╙███████████          j██████████████  //
//  ██████████████▌          ╟███████           ╙██████████          j██████████████  //
//  ██████████████▌          ╟████████           ╟█████████          j██████████████  //
//  ██████████████▌          ╟█████████           █████████          j██████████████  //
//  ██████████████▌          ╟██████████           ████████          j██████████████  //
//  ██████████████▌          ╟██████████▌           ███████          j██████████████  //
//  ██████████████▌          ╟███████████▌           ██████          j██████████████  //
//  ██████████████▌          ╟████████████▄          ╙█████        ,████████████████  //
//  ██████████████▌          ╟█████████████           ╙████      ▄██████████████████  //
//  ██████████████▌          ╟██████████████           ╙███    ▄████████████████████  //
//  ██████████████▌          ╟███████████████           ╟██ ,███████████████████████  //
//  ██████████████▌                      ,████           ███████████████████████████  //
//  ██████████████▌                    ▄██████▌           ██████████████████████████  //
//  ██████████████▌                  ▄█████████▌           █████████████████████████  //
//  ██████████████▌               ,█████████████▄           ████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////

import "./IERC165.sol";

interface IDeed is IERC165 {
    event Contribute(
        uint256 indexed resourceId,
        address indexed contributor,
        uint64 units
    );

    struct Contribution {
        string name;
        uint64 perUnit;
        uint64 maxUnits;
    }

    struct ContributionState {
        string name;
        uint64 perUnit;
        uint64 maxUnits;
        uint64 totalUnits;
    }

    struct UserContribution {
        uint256 resourceId;
        uint256 units;
    }

    struct DeedContribution {
        uint256 resourceId;
        uint256 units;
    }

    struct ContributionInfo {
        uint256 resourceId;
        string resourceName;
        uint256 units;
        uint64 perUnit;
    }

    /**
     * Update/set contribution configuration
     */
    function updateContribution(
        uint256[] calldata resourceIds,
        Contribution[] calldata resourceContributions
    ) external;

    /**
     * Getter for contribution state of a resource
     */
    function getContributionState(
        uint256 resourceId
    ) external returns (ContributionState memory);

    /**
     * Get a user's contributions
     */
    function getUserContributions(
        address user
    )
        external
        returns (
            ContributionInfo[] memory contributions,
            uint256 totalContributions
        );

    /**
     * Get a deed's contributions
     */
    function getDeedContributions(
        uint256 tokenId
    )
        external
        returns (
            ContributionInfo[] memory contributions,
            uint256 totalContributions
        );

    /**
     * Open/Close the minting phase
     */
    function setMintEnabled(bool enabled) external;

    /**
     * Mint a deed
     */
    function mint() external;

    /**
     * Split a deed (A) into two new deeds (B and C)
     */
    function split(uint256 tokenA, uint256[] calldata tokenBUnits) external;

    /**
     * Merge a list of deeds.
     */
    function merge(uint256[] calldata tokenIds) external;

    /**
     * Set metadata
     */
    function setMetadata(
        string calldata description,
        string calldata imageBaseURI
    ) external;
}
