// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./WCERC721.sol";
import "./TeamNFTStruct.sol";
import "./StageEnum.sol";
import "./Counters.sol";

/**
* @dev WorldCupSweepstakeBase Contract Defines the state variables (such as mappings)
       which are specifically related to World Cup Teams and provides methods for
      mapping between tokenIds and teams.
**/
abstract contract WorldCupSweepstakeBase is WorldCupSweepstakeERC721 {
    using Counters for Counters.Counter;

    //Constants
    // the official FIFA team Ids to be made available
    string[32] internal _teamIds = [
        "QAT",
        "NED",
        "SEN",
        "ECU",
        "ENG",
        "USA",
        "IRN",
        "WAL",
        "ARG",
        "POL",
        "MEX",
        "KSA",
        "FRA",
        "DEN",
        "TUN",
        "AUS",
        "ESP",
        "GER",
        "JPN",
        "CRC",
        "BEL",
        "CAN",
        "MAR",
        "CRO",
        "BRA",
        "SRB",
        "SUI",
        "CMR",
        "POR",
        "GHA",
        "URU",
        "KOR"
    ];

    //Private variables
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => TeamNFT) private _tokenIdToTeam;
    mapping(string => bool) private _teamIdExists;
    mapping(string => uint256) private _teamIdToTokenId;

    //Events
    event TeamMinted(
        address indexed _to,
        string _teamId,
        TournamentStageEnum _stage
    );
    event TeamTournamentStageChange(
        address indexed _from,
        string _teamId,
        TournamentStageEnum _stage
    );

    /**
     * @dev Constructor sets contract name and symbol passing through
     *      to the openzepplin ERC721 contract
     */
    constructor() WorldCupSweepstakeERC721("World Cup Sweepstake", "WCSWP") {}

    //Public/External Methods

    /**
     * @dev Allows direct minting
     * NOTE: Public so retstricted to contract owner.
     *       Only defined for testing
     *       TODO: use a test contract instead of exposing this method
     */
    function mintTeam(address to, string memory teamId) public onlyOwner {
        _mintTeam(to, teamId);
    }

    /**
     * @dev Exposes a way to determine all teams
     *      This could be made redundant if making
     *      _teamId public
     */
    function getAllPossibleTeamIds() external view returns (string[32] memory) {
        return _teamIds;
    }

    /**
     * @dev Determine if Team has already been minted
     */
    function teamExists(string memory teamId) public view returns (bool) {
        return _teamIdExists[teamId];
    }

    /**
     * @dev Mapping helper - find team from teamId
     * NOTE: Team includes the stage of the tournament the team is at
     */
    function teamFromTeamId(string memory teamId)
        external
        view
        returns (TeamNFT memory)
    {
        require(teamExists(teamId), "teamId does not exist");
        uint256 tokenId = _teamIdToTokenId[teamId];
        return teamFromTokenId(tokenId);
    }

    /**
     * @dev Mapping helper - find team from tokenId
     * NOTE: Team includes the stage of the tournament the team is at
     */
    function teamFromTokenId(uint256 tokenId)
        public
        view
        returns (TeamNFT memory)
    {
        require(_exists(tokenId), "tokenId does not exist");
        return _tokenIdToTeam[tokenId];
    }

    /**
     * @dev Mapping helper - find tokenId from teamId
     * NOTE: Assumes one to one single token per team
     *       This is correct at time of writing but
     *       we did have aspirations to provide multiple
     *       flavours of nft teams in the future.
     */
    function tokenIdFromTeamId(string memory teamId)
        public
        view
        returns (uint256)
    {
        require(teamExists(teamId));
        return _teamIdToTokenId[teamId];
    }

    /**
     * @dev Mapping helper - find owner from teamId
     * NOTE: Assumes one to one single token per team
     *       This is correct at time of writing but
     *       we did have aspirations to provide multiple
     *       flavours of nft teams in the future.
     */
    function ownerOfTeam(string memory teamId) public view returns (address) {
        uint256 tokenId = tokenIdFromTeamId(teamId);
        return ownerOf(tokenId);
    }

    //Private / Internal Methods

    /**
     * @dev Allows direct minting and handles
     *      team to token mapping and vice versa
     * NOTE: Called internal ONLY and therefore
     *       not restricted to owner
     * WARNING: Inheriting contracts should consider restrictions if using
     */
    function _mintTeam(address to, string memory teamId) internal {
        require(!teamExists(teamId), "team already exists");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        //setup team to mint
        TeamNFT memory team = TeamNFT(teamId, TournamentStageEnum.GroupStage);

        //store mappings
        _tokenIdToTeam[tokenId] = team;
        _teamIdExists[team.teamId] = true;
        _teamIdToTokenId[team.teamId] = tokenId;

        //call safe mint to mint new token id
        _safeMint(to, tokenId);

        emit TeamMinted(to, team.teamId, team.stage);
    }

    /**
     * @dev Enables setting the relevant team's tournament stage
     *      via mappings.
     * NOTE: Restricted to onlyOwner of the contract to make sure
     *       system cannot be abused.
     *       However, we acknowledge this introduces a centralised
     *       and single point of failure for this simple implementation
     */
    function _setTeamStage(string memory teamId, TournamentStageEnum stage)
        internal
        virtual
        onlyOwner
    {
        require(teamExists(teamId), "team does not exist");

        uint256 tokenId = _teamIdToTokenId[teamId];
        TeamNFT memory team = _tokenIdToTeam[tokenId];
        team.stage = stage;
        _tokenIdToTeam[tokenId] = team;

        // emit event
        emit TeamTournamentStageChange(msg.sender, team.teamId, stage);
    }
}
