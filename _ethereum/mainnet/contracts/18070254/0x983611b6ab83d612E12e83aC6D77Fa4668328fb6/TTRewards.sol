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
import "./IERC20Upgradeable.sol";
import "./ITeamNFTManager.sol";
import "./ITTMarketplace.sol";

contract TTRewards is Initializable, PausableUpgradeable, OwnableUpgradeable {
    struct SeriesReward {
        uint256 baseRewards;
        uint256 bonusRewards;
        uint256 rewardsReceivedForPayouts;
        uint256 startDate;
        uint256 endDate;
        uint256 rewardsAllocated;
        uint256 rewardTiers;
    }

    struct RewardTier {
        uint256 allocationPercent;
        uint256 totalWinners;
    }

    ITeamNFTManager public teamNftManager;

    IERC20Upgradeable public teamtoken;

    // Mapping Sport -> Series -> SeriesReward
    mapping(uint256 => mapping(uint256 => SeriesReward)) public seriesRewards;

    mapping(uint256 => mapping(uint256 => mapping(uint256 => RewardTier)))
        public seriesRewardTiers;

    event SeriesRewardsCreated(
        uint256 indexed sportId,
        uint256 indexed seriesId,
        uint256 baseRewards,
        uint256 bonusRewards,
        uint256 startDate,
        uint256 endDate
    );

    event RewardsReceived(
        uint256 indexed sportId,
        uint256 indexed seriesId,
        uint256 amount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _admin,
        address _teamNftManager,
        address _teamNft
    ) public initializer {
        __Pausable_init();
        __Ownable_init();

        teamNftManager = ITeamNFTManager(_teamNftManager);
        teamtoken = IERC20Upgradeable(_teamNft);

        _transferOwnership(_admin);
    }

    function createSeriesRewards(
        uint256 _sport,
        uint256 _series,
        uint256 _baseRewards,
        uint256 _bonusRewards,
        uint256 _startDate,
        uint256 _endDate
    ) public onlyOwner {
        require(_sport <= teamNftManager.sportsLength());
        require(_series <= teamNftManager.seriesForSportLength(_sport));
        require(_endDate > _startDate, "EndDate must be later than start date");
        SeriesReward memory newSeriesReward = SeriesReward({
            baseRewards: _baseRewards,
            bonusRewards: _bonusRewards,
            rewardsReceivedForPayouts: 0,
            startDate: _startDate,
            endDate: _endDate,
            rewardsAllocated: 0,
            rewardTiers: 0
        });
        seriesRewards[_sport][_series] = newSeriesReward;

        emit SeriesRewardsCreated(
            _sport,
            _series,
            _baseRewards,
            _bonusRewards,
            _startDate,
            _endDate
        );
    }

    function createSeriesRewardsTier(
        uint256 _sport,
        uint256 _series,
        uint256 _allocation,
        uint256 _totalWinners
    ) public onlyOwner {
        SeriesReward storage seriesReward = seriesRewards[_sport][_series];
        RewardTier memory newRewardTier = RewardTier({
            allocationPercent: _allocation,
            totalWinners: _totalWinners
        });
        uint256 rewardTierNumber = seriesReward.rewardTiers + 1;
        seriesRewardTiers[_sport][_series][rewardTierNumber] = newRewardTier;
        seriesReward.rewardTiers = rewardTierNumber;
    }

    function receiveRewards(uint256 amount, uint256 tokenId) external {
        address marketplace = teamNftManager.marketplace();
        require(_msgSender() == marketplace);
        // teamtoken.transferFrom(marketplace, address(this), amount);
        (uint _sport, uint _series) = _calculateSportAndLeagueFromTokenId(
            tokenId
        );
        require(seriesRewards[_sport][_series].startDate > 0, "Doesn't exist");
        seriesRewards[_sport][_series].rewardsReceivedForPayouts += amount;

        emit RewardsReceived(_sport, _series, amount);
    }

    function _calculateSportAndLeagueFromTokenId(
        uint256 tokenId
    ) internal pure returns (uint256 sport, uint256 league) {
        sport = tokenId / 1000000;
        league = (tokenId - (sport * 1000000)) / 1000;
    }

    // This contract will handle rewards for all TeamTokens

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
