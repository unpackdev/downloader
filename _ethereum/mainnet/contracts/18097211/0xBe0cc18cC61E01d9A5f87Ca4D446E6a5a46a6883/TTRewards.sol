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
import "./ITeamNFT.sol";
import "./Structs.sol";

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

    struct UserRewards {
        uint256 rewardsEarned;
        uint256 rewardsClaimed;
    }

    mapping(address => UserRewards) public usersRewards;

    address public operator;

    ITeamNFT public teamNft;

    event SeriesRewardsCreated(
        uint256 indexed sportId,
        uint256 indexed seriesId,
        uint256 baseRewards,
        uint256 bonusRewards,
        uint256 startDate,
        uint256 endDate
    );

    event SeriesRewardsTierCreated(
        uint256 indexed sportId,
        uint256 indexed seriesId,
        uint256 allocation,
        uint256 totalWinners
    );

    event RewardsClaimed(
        address indexed user,
        uint256 indexed amountClaimed,
        uint256 lifetimeClaimed
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _admin,
        address _teamNftManager,
        address _teamtoken
    ) public initializer {
        __Pausable_init();
        __Ownable_init();

        teamNftManager = ITeamNFTManager(_teamNftManager);
        teamtoken = IERC20Upgradeable(_teamtoken);

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
            startDate: (_startDate == 0) ? block.timestamp : _startDate,
            endDate: (_endDate == 0)
                ? block.timestamp + (60 * 60 * 24 * 365)
                : _endDate,
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
        require(_allocation <= 10000); // 10000 is 100%
        SeriesReward storage seriesReward = seriesRewards[_sport][_series];
        RewardTier memory newRewardTier = RewardTier({
            allocationPercent: _allocation,
            totalWinners: _totalWinners
        });
        uint256 rewardTierNumber = seriesReward.rewardTiers + 1;
        seriesRewardTiers[_sport][_series][rewardTierNumber] = newRewardTier;
        seriesReward.rewardTiers = rewardTierNumber;

        emit SeriesRewardsTierCreated(
            _sport,
            _series,
            _allocation,
            _totalWinners
        );
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
    }

    function _calculateSportAndLeagueFromTokenId(
        uint256 tokenId
    ) internal pure returns (uint256 sport, uint256 league) {
        sport = tokenId / 1000000;
        league = (tokenId - (sport * 1000000)) / 1000;
    }

    // This is called once per winning event.
    function pushRewards(
        uint256 sport,
        uint256 series,
        uint256 rewardTier,
        uint256[] calldata winningTokenIds
    ) public {
        require(_msgSender() == operator || _msgSender() == owner());
        uint256 length = winningTokenIds.length;

        RewardTier memory thisRewardTier = seriesRewardTiers[sport][series][
            rewardTier
        ];

        // Get the allocation of this reward tier from the total rewards.
        uint256 rewardAmount = ((seriesRewards[sport][series].baseRewards +
            seriesRewards[sport][series].bonusRewards) *
            thisRewardTier.allocationPercent) / 10000;

        // See what each winning event will pay, and then divide by 100 to equal one tokens rewards.
        uint256 rewardPerWinner = rewardAmount /
            thisRewardTier.totalWinners /
            100;

        // Loop through all winning tokenIds
        for (uint256 i = 0; i < length; i++) {
            // Get all holders of the winning token.
            OwnersBalances[] memory thisTokensOwners = teamNft
                .allOwnersWithBalances(winningTokenIds[i]);

            // For each holder of the winning token, add appropriate amount to their claimable amount.
            for (uint256 w = 0; w < thisTokensOwners.length; w++) {
                OwnersBalances memory thisWinner = thisTokensOwners[w];
                usersRewards[thisWinner.account]
                    .rewardsEarned += (rewardPerWinner * thisWinner.balance);
            }
        }

        seriesRewards[sport][series].rewardsAllocated += (length *
            rewardPerWinner *
            100);
    }

    function rewardsAvailable(address _winner) public view returns (uint256) {
        UserRewards memory thisWinner = usersRewards[_winner];
        return thisWinner.rewardsEarned - thisWinner.rewardsClaimed;
    }

    function claimRewards() public {
        address _user = _msgSender();
        uint256 _rewardAvailable = rewardsAvailable(_user);
        require(_rewardAvailable > 0, "Rewards not available");
        usersRewards[_user].rewardsClaimed = usersRewards[_user].rewardsEarned;
        teamtoken.transfer(_user, _rewardAvailable);
        emit RewardsClaimed(
            _user,
            _rewardAvailable,
            usersRewards[_user].rewardsClaimed
        );
    }

    function setOperator(address _operator) public onlyOwner {
        operator = _operator;
    }

    function setTeamNft(address _teamNft) public onlyOwner {
        teamNft = ITeamNFT(_teamNft);
    }

    function setTeamToken(address _teamToken) public onlyOwner {
        teamtoken = IERC20Upgradeable(_teamToken);
    }

    // This contract will handle rewards for all TeamTokens

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
