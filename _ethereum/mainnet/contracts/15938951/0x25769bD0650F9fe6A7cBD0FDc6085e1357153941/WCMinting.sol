// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./WCCompetition.sol";
import "./TeamNFTStruct.sol";
import "./StageEnum.sol";

/**
* @dev   WorldCupSweepstakeMinting is concerned with
*        - Minting at time of purchase
*        - Randomised World Cup Sweepstake
**/
contract WorldCupSweepstakeMinting is WorldCupSweepstakeCompetition {
    //TODO: via deployment constructor or something more configurable?
    uint256 public INITIAL_SALE_PRICE = 0.012 * 1e18; //ETH

    constructor() {}

    //Modifiers

    /**
    * @dev Used to ensure againt common mistakes
    *      https://consensys.github.io/smart-contract-best-practices/development-recommendations/token-specific/contract-address/
    *      Zero address is somewhat irrelevant as it is checked
    *      in inherited openzepplin contract for mint
    */
    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this) );
        _;
    }

    //Public / External methods

    /**
    * @dev   Buy and Mint next NFT
    **/
    function buyNextTeam(uint256 price, address to) validDestination(to) external payable {

        //Ensure the sender sent the amount of ETH they meant to send
        require(msg.value == price, "The amount sent does not match value");

        //Check price is equal to what we are selling at
        require(INITIAL_SALE_PRICE == price, "Please submit asking price");

        //Address to is sender - help limit user making a mistake
        require(msg.sender == to, "Only sender can own");

        //Fetch next team to be minted
        string memory teamId = _fetchNextTeam();

        //Mint the team to be owned by to address
        _mintTeam(to, teamId);
    }

    //Internal / Private methods
    
    /**
    * @dev   private function to decide which team
    *        should be next
    **/
    function _fetchNextTeam() private view returns (string memory) {
        // fetch all teamIds which are available for minting
        string[] memory unmintedTeams = _fetchUnmintedTeams();

        //revert if nothing left to mint
        if (unmintedTeams.length == 0) {
            revert("No more teams available");
        }

        // generate a random number and pick a team
        uint256 randomTeamIndex = _randomise(
            "A_RANDOM_SEED_HERE?!?!?",
            unmintedTeams.length
        );
        string memory teamId = unmintedTeams[randomTeamIndex];

        // return that team
        return teamId;
    }

    /**
     * @dev Generates a random number within the range specified
     * NOTE :  it would be MUCH better to get this from a random number oracle e.g. Chainlink but
     * for now we're just using the timestamp to randomise
     **/
    function _randomise(string memory seed, uint256 range)
        private
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        seed,
                        block.difficulty,
                        block.timestamp,
                        block.number
                    )
                )
            ) % range;
    }

    /**
     * @dev Generates array of unminted teams
     *      to facilitate minting next team  
     **/
    function _fetchUnmintedTeams() private view returns (string[] memory) {
        // build array to hold unminted teams
        uint256 totalAvailableSupply = _teamIds.length;
        uint256 length = totalAvailableSupply - totalSupply();
        string[] memory teams = new string[](length);
        uint256 currentIndex = 0;

        // loop through all available teams
        for (uint256 i = 0; i < _teamIds.length; i++) {
            // does the team already exist?
            if (!teamExists(_teamIds[i])) {
                // this team isn't minted yet
                teams[currentIndex] = _teamIds[i];
                currentIndex++;
            }
        }

        return teams;
    }
}
