//  $$$$$$$$\ $$$$$$$$\  $$$$$$\  $$\      $$\       $$$$$$$$\  $$$$$$\  $$\   $$\ $$$$$$$$\ $$\   $$\
//  \__$$  __|$$  _____|$$  __$$\ $$$\    $$$ |      \__$$  __|$$  __$$\ $$ | $$  |$$  _____|$$$\  $$ |
//     $$ |   $$ |      $$ /  $$ |$$$$\  $$$$ |         $$ |   $$ /  $$ |$$ |$$  / $$ |      $$$$\ $$ |
//     $$ |   $$$$$\    $$$$$$$$ |$$\$$\$$ $$ |         $$ |   $$ |  $$ |$$$$$  /  $$$$$\    $$ $$\$$ |
//     $$ |   $$  __|   $$  __$$ |$$ \$$$  $$ |         $$ |   $$ |  $$ |$$  $$<   $$  __|   $$ \$$$$ |
//     $$ |   $$ |      $$ |  $$ |$$ |\$  /$$ |         $$ |   $$ |  $$ |$$ |\$$\  $$ |      $$ |\$$$ |
//     $$ |   $$$$$$$$\ $$ |  $$ |$$ | \_/ $$ |         $$ |    $$$$$$  |$$ | \$$\ $$$$$$$$\ $$ | \$$ |
//     \__|   \________|\__|  \__|\__|     \__|         \__|    \______/ \__|  \__|\________|\__|  \__|
//
//   Web: teamtoken.com
//   Twitter: twitter.com/TeamTokenCrypto
//   Contact Email: admin@teamtoken.com
//
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./Structs.sol";
import "./ITeamNFT.sol";
import "./ITTMarketplace.sol";

error NotEnoughTokensForTransfer(uint256 id, uint256 amount);

contract TeamNFTManager is
    Initializable,
    ERC1155HolderUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    // A mapping of all sports/leagues. Every league qualifies for
    // an entry, some some sports will have multiple entries
    mapping(uint256 => string) public sports;

    // Mapping Sport -> Series -> SeriesData
    mapping(uint256 => mapping(uint256 => SeriesData)) public series;

    // TeamNFT address
    ITeamNFT public teamNft;

    ITTMarketplace public marketplace;

    // Total number of sports for tracking the mapping.
    uint256 private _numberOfSports;
    mapping(uint256 => uint256) private _numberOfSeriesInSport;

    // Mapping storing data about individual tokens.
    // Mapping of tokenId -> NFTData
    mapping(uint256 => TeamNFTData) private _nftData;

    // EVENTS
    event SportCreated(uint256 sportId, string sport);
    event SeriesCreated(
        uint256 sportId,
        uint256 seriesId,
        string seriesName,
        uint256 numberOfTeams,
        uint256 nftsPerTeam,
        uint256 firstTokenId
    );

    function nftData(
        uint256 tokenId
    )
        external
        view
        returns (
            string memory sport,
            string memory seriesName,
            string memory cityName,
            string memory teamName,
            string memory color1,
            string memory color2
        )
    {
        TeamNFTData memory teamNftData = _nftData[tokenId];
        sport = sports[teamNftData.sport];
        cityName = bytesToString(teamNftData.cityName);
        teamName = bytesToString(teamNftData.teamName);
        seriesName = bytesToString(teamNftData.seriesName);
        color1 = bytesToString(teamNftData.color1);
        color2 = bytesToString(teamNftData.color2);
    }

    function sportsLength() external view returns (uint256) {
        return _numberOfSports;
    }

    function seriesForSportLength(
        uint256 _sport
    ) external view returns (uint256) {
        return _numberOfSeriesInSport[_sport];
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin) public initializer {
        __Pausable_init();
        __Ownable_init();
        __ERC1155Holder_init();
        transferOwnership(_admin);

        _numberOfSports = 0;
    }

    function genTokenId(
        uint256 sportId,
        uint256 seriesId,
        uint256 teamId
    ) public pure returns (uint256) {
        return (sportId * 1e6) + (seriesId * 1e3) + teamId;
    }

    // External

    // Functions to be able to receive ether at this contract
    receive() external payable {}

    fallback() external payable {}

    // Admin only

    function createSport(string calldata _sport) external onlyOwner {
        uint256 newSportId = _numberOfSports + 1;
        sports[newSportId] = _sport;
        _numberOfSports++;
        _numberOfSeriesInSport[newSportId] = 0;
        emit SportCreated(newSportId, _sport);
    }

    function createMarketplaceListing(
        uint64 _sport,
        uint64 _series,
        uint256[] calldata _prices,
        uint256 _starttime,
        uint256 _deadline
    ) external onlyOwner {
        require(_sport <= _numberOfSports, "Invalid sport");
        require(_series <= _numberOfSeriesInSport[_sport], "Invalid series");

        SeriesData memory ourSeries = series[_sport][_series];

        uint256[] memory tokenIds = new uint256[](ourSeries.numberOfTeams);
        uint256[] memory amountOfTokens = new uint256[](
            ourSeries.numberOfTeams
        );
        uint256[] memory prices = new uint256[](ourSeries.numberOfTeams);

        for (uint256 i = 0; i < ourSeries.numberOfTeams; i++) {
            uint256 newTokenId = genTokenId(_sport, _series, i + 1);
            tokenIds[i] = newTokenId;
            amountOfTokens[i] = ourSeries.nftsPerTeam;
            prices[i] = _prices[i];
        }
        marketplace.listBatchTeamNFT(
            tokenIds,
            amountOfTokens,
            prices,
            _starttime,
            _deadline
        );
    }

    function createSeries(
        uint64 sport,
        string calldata seriesName,
        uint128 nftsPerTeam,
        string[] calldata cityNames,
        string[] calldata teamNames,
        string[] calldata color1s,
        string[] calldata color2s
    ) external onlyOwner returns (bool) {
        uint128 numberOfTeams = uint128(teamNames.length);
        require(
            teamNames.length == color1s.length &&
                teamNames.length == color2s.length
        );
        require(sport <= _numberOfSports, "Invalid sport");

        SeriesData memory newSeries = SeriesData({
            seriesName: seriesName,
            numberOfTeams: numberOfTeams,
            nftsPerTeam: nftsPerTeam
        });

        uint64 newSeriesId = uint64(_numberOfSeriesInSport[sport] + 1);
        series[sport][newSeriesId] = newSeries;
        _numberOfSeriesInSport[sport] = newSeriesId;
        _createSeriesNFTs(
            sport,
            newSeriesId,
            seriesName,
            numberOfTeams,
            nftsPerTeam,
            teamNames,
            cityNames,
            color1s,
            color2s
        );
        emit SeriesCreated(
            sport,
            newSeriesId,
            seriesName,
            numberOfTeams,
            nftsPerTeam,
            genTokenId(sport, newSeriesId, 1)
        );

        return true;
    }

    /// @dev Testing function for transferring initial tokens
    function transferNFT(
        address to,
        uint256 _id,
        uint256 _amount
    ) public onlyOwner {
        _transferNFT(to, _id, _amount);
    }

    function updateTeamNft(address _teamNft) public onlyOwner {
        require(_teamNft != address(0));
        teamNft = ITeamNFT(_teamNft);
    }

    function updateMarketplace(address _marketplace) public onlyOwner {
        require(_marketplace != address(0));
        marketplace = ITTMarketplace(_marketplace);
        teamNft.setApprovalForAll(_marketplace, true);
    }

    /// @dev Set to 0 address to disable onChain metadata
    function updateTeamNftRenderer(address _teamNftRenderer) public onlyOwner {
        teamNft.setTeamNftRenderer(_teamNftRenderer);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // function governanceRecoverNative(address payable _to) external onlyOwner {
    //     (bool sent, ) = _to.call{value: getBalance()}("");
    //     require(sent, "Failed to send native");
    // }

    // function governanceRecoverToken(
    //     IERC20Upgradeable _token,
    //     address _to
    // ) external onlyOwner {
    //     require(
    //         _token.transfer(_to, _token.balanceOf(address(this))),
    //         "Token could not be transferred"
    //     );
    // }

    // Internal functions

    function _createSeriesNFTs(
        uint64 sport,
        uint64 seriesId,
        string calldata seriesName,
        uint128 numberOfTeams,
        uint128 nftsPerTeam,
        string[] calldata teamNames,
        string[] calldata cityNames,
        string[] calldata color1s,
        string[] calldata color2s
    ) internal {
        uint256[] memory tokenIdData = new uint256[](numberOfTeams);
        uint256[] memory amountsData = new uint256[](numberOfTeams);
        for (uint256 i = 0; i < numberOfTeams; i++) {
            uint256 newTokenId = genTokenId(sport, seriesId, i + 1);
            tokenIdData[i] = newTokenId;
            amountsData[i] = nftsPerTeam;
            _nftData[newTokenId] = TeamNFTData({
                sport: sport,
                series: seriesId,
                seriesName: stringToBytes(seriesName),
                teamName: stringToBytes(teamNames[i]),
                cityName: stringToBytes(cityNames[i]),
                color1: stringToBytes(color1s[i]),
                color2: stringToBytes(color2s[i])
            });
        }
        _createBatchNFT(address(this), tokenIdData, amountsData);
    }

    function _createNFT(address to, uint256 _id, uint256 _amount) internal {
        teamNft.mint(to, _id, _amount, "");
    }

    function _createBatchNFT(
        address to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) internal {
        teamNft.mintBatch(to, _ids, _amounts, "");
    }

    function _transferNFT(address to, uint256 _id, uint256 _amount) internal {
        if (teamNft.balanceOf(address(this), _id) < _amount) {
            revert NotEnoughTokensForTransfer(_id, _amount);
        }

        teamNft.safeTransferFrom(address(this), to, _id, _amount, "");
    }

    function bytesToString(
        bytes32 _bytes32
    ) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function stringToBytes(
        string calldata input
    ) internal pure returns (bytes32) {
        return bytes32(abi.encodePacked(input));
    }

    function getBalance() internal view returns (uint) {
        return address(this).balance;
    }
}
