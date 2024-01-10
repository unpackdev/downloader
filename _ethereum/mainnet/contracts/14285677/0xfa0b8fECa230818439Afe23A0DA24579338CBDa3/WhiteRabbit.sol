// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC1155Holder.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./WhiteRabbitProducerPass.sol";

contract WhiteRabbit is Ownable, ERC1155Holder {
    using Strings for uint256;
    using SafeMath for uint256;

    // The Producer Pass contract used for staking/voting on episodes
    WhiteRabbitProducerPass private whiteRabbitProducerPass;
    // The total number of episodes that make up the film
    uint256 private _numberOfEpisodes;
    // A mapping from episodeId to whether or not voting is enabled
    mapping(uint256 => bool) public votingEnabledForEpisode;

    // The address of the White Rabbit token ($WRAB)
    address public whiteRabbitTokenAddress;
    // The initial fixed supply of White Rabbit tokens
    uint256 public tokenInitialFixedSupply;

    // The wallet addresses of the two artists creating the film
    address private _artist1Address;
    address private _artist2Address;

    // The percentage of White Rabbit tokens that will go to the artists
    uint256 public artistTokenAllocationPercentage;
    // The number of White Rabbit tokens to send to each artist per episode
    uint256 public artistTokenPerEpisodePerArtist;
    // A mapping from episodeId to a boolean indicating whether or not
    // White Rabbit tokens have been transferred the artists yet
    mapping(uint256 => bool) public hasTransferredTokensToArtistForEpisode;

    // The percentage of White Rabbit tokens that will go to producers (via Producer Pass staking)
    uint256 public producersTokenAllocationPercentage;
    // The number of White Rabbit tokens to send to producers per episode
    uint256 public producerPassTokenAllocationPerEpisode;
    // The base number of White Rabbit tokens to allocate to producers per episode
    uint256 public producerPassTokenBaseAllocationPerEpisode;
    // The number of White Rabbit tokens to allocate to producers who stake early
    uint256 public producerPassTokenEarlyStakingBonusAllocationPerEpisode;
    // The number of White Rabbit tokens to allocate to producers who stake for the winning option
    uint256 public producerPassTokenWinningBonusAllocationPerEpisode;

    // The percentage of White Rabbit tokens that will go to the platform team
    uint256 public teamTokenAllocationPercentage;
    // Whether or not the team has received its share of White Rabbit tokens
    bool public teamTokenAllocationDistributed;

    // Event emitted when a Producer Pass is staked to vote for an episode option
    event ProducerPassStaked(
        address indexed account,
        uint256 episodeId,
        uint256 voteId,
        uint256 amount,
        uint256 tokenAmount
    );
    // Event emitted when a Producer Pass is unstaked after voting is complete
    event ProducerPassUnstaked(
        address indexed account,
        uint256 episodeId,
        uint256 voteId,
        uint256 tokenAmount
    );

    // The list of episode IDs (e.g. [1, 2, 3, 4])
    uint256[] public episodes;

    // The voting option IDs by episodeId (e.g. 1 => [1, 2])
    mapping(uint256 => uint256[]) private _episodeOptions;

    // The total vote counts for each episode voting option, agnostic of users
    // _episodeVotesByOptionId[episodeId][voteOptionId] => number of votes
    mapping(uint256 => mapping(uint256 => uint256))
        private _episodeVotesByOptionId;

    // A mapping from episodeId to the winning vote option
    // 0 means no winner has been declared yet
    mapping(uint256 => uint256) public winningVoteOptionByEpisode;

    // A mapping of how many Producer Passes have been staked per user per episode per option
    // e.g. _usersStakedEpisodeVotingOptionsCount[address][episodeId][voteOptionId] => number staked
    // These values will be updated/decremented when Producer Passes are unstaked
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        private _usersStakedEpisodeVotingOptionsCount;

    // A mapping of the *history* how many Producer Passes have been staked per user per episode per option
    // e.g. _usersStakedEpisodeVotingHistoryCount[address][episodeId][voteOptionId] => number staked
    // Note: These values DO NOT change after Producer Passes are unstaked
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        private _usersStakedEpisodeVotingHistoryCount;

    // The base URI for episode metadata
    string private _episodeBaseURI;
    // The base URI for episode voting option metadata
    string private _episodeOptionBaseURI;

    /**
     * @dev Initializes the contract by setting up the Producer Pass contract to be used
     */
    constructor(address whiteRabbitProducerPassContract) {
        whiteRabbitProducerPass = WhiteRabbitProducerPass(
            whiteRabbitProducerPassContract
        );
    }

    /**
     * @dev Sets the Producer Pass contract to be used
     */
    function setWhiteRabbitProducerPassContract(
        address whiteRabbitProducerPassContract
    ) external onlyOwner {
        whiteRabbitProducerPass = WhiteRabbitProducerPass(
            whiteRabbitProducerPassContract
        );
    }

    /**
     * @dev Sets the base URI for episode metadata
     */
    function setEpisodeBaseURI(string memory baseURI) external onlyOwner {
        _episodeBaseURI = baseURI;
    }

    /**
     * @dev Sets the base URI for episode voting option metadata
     */
    function setEpisodeOptionBaseURI(string memory baseURI) external onlyOwner {
        _episodeOptionBaseURI = baseURI;
    }

    /**
     * @dev Sets the list of episode IDs (e.g. [1, 2, 3, 4])
     *
     * This will be updated every time a new episode is added.
     */
    function setEpisodes(uint256[] calldata _episodes) external onlyOwner {
        episodes = _episodes;
    }

    /**
     * @dev Sets the voting option IDs for a given episode.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     */
    function setEpisodeOptions(
        uint256 episodeId,
        uint256[] calldata episodeOptionIds
    ) external onlyOwner {
        require(episodeId <= episodes.length, "Episode does not exist");
        _episodeOptions[episodeId] = episodeOptionIds;
    }

    /**
     * @dev Retrieves the voting option IDs for a given episode.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     */
    function getEpisodeOptions(uint256 episodeId)
        public
        view
        returns (uint256[] memory)
    {
        require(episodeId <= episodes.length, "Episode does not exist");
        return _episodeOptions[episodeId];
    }

    /**
     * @dev Retrieves the number of episodes currently available.
     */
    function getCurrentEpisodeCount() external view returns (uint256) {
        return episodes.length;
    }

    /**
     * @dev Constructs the metadata URI for a given episode.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     */
    function episodeURI(uint256 episodeId)
        public
        view
        virtual
        returns (string memory)
    {
        require(episodeId <= episodes.length, "Episode does not exist");
        string memory baseURI = episodeBaseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, episodeId.toString(), ".json")
                )
                : "";
    }

    /**
     * @dev Constructs the metadata URI for a given episode voting option.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     * - The episode voting option ID is valid
     */
    function episodeOptionURI(uint256 episodeId, uint256 episodeOptionId)
        public
        view
        virtual
        returns (string memory)
    {
        // TODO: DRY up these requirements? ("Episode does not exist", "Invalid voting option")
        require(episodeId <= episodes.length, "Episode does not exist");

        string memory baseURI = episodeOptionBaseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        _episodeOptionBaseURI,
                        episodeId.toString(),
                        "/",
                        episodeOptionId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    /**
     * @dev Getter for the `_episodeBaseURI`
     */
    function episodeBaseURI() internal view virtual returns (string memory) {
        return _episodeBaseURI;
    }

    /**
     * @dev Getter for the `_episodeOptionBaseURI`
     */
    function episodeOptionBaseURI()
        internal
        view
        virtual
        returns (string memory)
    {
        return _episodeOptionBaseURI;
    }

    /**
     * @dev Retrieves the voting results for a given episode's voting option ID
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     * - Voting is no longer enabled for the given episode
     * - Voting has completed and a winning option has been declared
     */
    function episodeVotes(uint256 episodeId, uint256 episodeOptionId)
        public
        view
        virtual
        returns (uint256)
    {
        require(episodeId <= episodes.length, "Episode does not exist");
        require(!votingEnabledForEpisode[episodeId], "Voting is still enabled");
        require(
            winningVoteOptionByEpisode[episodeId] > 0,
            "Voting not finished"
        );
        return _episodeVotesByOptionId[episodeId][episodeOptionId];
    }

    /**
     * @dev Retrieves the number of Producer Passes that the user has staked
     * for a given episode and voting option at this point in time.
     *
     * Note that this number will change after a user has unstaked.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     */
    function userStakedProducerPassCount(
        uint256 episodeId,
        uint256 episodeOptionId
    ) public view virtual returns (uint256) {
        require(episodeId <= episodes.length, "Episode does not exist");
        return
            _usersStakedEpisodeVotingOptionsCount[msg.sender][episodeId][
                episodeOptionId
            ];
    }

    /**
     * @dev Retrieves the historical number of Producer Passes that the user
     * has staked for a given episode and voting option.
     *
     * Note that this number will not change as a result of unstaking.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     */
    function userStakedProducerPassCountHistory(
        uint256 episodeId,
        uint256 episodeOptionId
    ) public view virtual returns (uint256) {
        require(episodeId <= episodes.length, "Episode does not exist");
        return
            _usersStakedEpisodeVotingHistoryCount[msg.sender][episodeId][
                episodeOptionId
            ];
    }

    /**
     * @dev Stakes Producer Passes for the given episode's voting option ID,
     * with the ability to specify an `amount`. Staking is used to vote for the option
     * that the user would like to see producers for the next episode.
     *
     * Emits a `ProducerPassStaked` event indicating that the staking was successful,
     * including the total number of White Rabbit tokens allocated as a result.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     * - Voting is enabled for the given episode
     * - The user is attempting to stake more than zero Producer Passes
     * - The user has enough Producer Passes to stake
     * - The episode voting option is valid
     * - A winning option hasn't been declared yet
     */
    function stakeProducerPass(
        uint256 episodeId,
        uint256 voteOptionId,
        uint256 amount
    ) public {
        require(episodeId <= episodes.length, "Episode does not exist");
        require(votingEnabledForEpisode[episodeId], "Voting not enabled");
        require(amount > 0, "Cannot stake 0");
        require(
            whiteRabbitProducerPass.balanceOf(msg.sender, episodeId) >= amount,
            "Insufficient pass balance"
        );
        uint256[] memory votingOptionsForThisEpisode = _episodeOptions[
            episodeId
        ];
        // vote options should be [1, 2], ID <= length
        require(
            votingOptionsForThisEpisode.length >= voteOptionId,
            "Invalid voting option"
        );
        uint256 winningVoteOptionId = winningVoteOptionByEpisode[episodeId];
        // rely on winningVoteOptionId to determine that this episode is valid for voting on
        require(winningVoteOptionId == 0, "Winner already declared");

        // user's vote count for selected episode & option
        uint256 userCurrentVoteCount = _usersStakedEpisodeVotingOptionsCount[
            msg.sender
        ][episodeId][voteOptionId];

        // Get total vote count of this option user is voting/staking for
        uint256 currentTotalVoteCount = _episodeVotesByOptionId[episodeId][
            voteOptionId
        ];

        // Get total vote count from every option of this episode for bonding curve calculation
        uint256 totalVotesForEpisode = 0;

        for (uint256 i = 0; i < votingOptionsForThisEpisode.length; i++) {
            uint256 currentVotingOptionId = votingOptionsForThisEpisode[i];
            totalVotesForEpisode += _episodeVotesByOptionId[episodeId][
                currentVotingOptionId
            ];
        }

        // calculate token rewards here
        uint256 tokensAllocated = getTokenAllocationForUserBeforeStaking(
            episodeId,
            amount
        );
        uint256 userNewVoteCount = userCurrentVoteCount + amount;
        _usersStakedEpisodeVotingOptionsCount[msg.sender][episodeId][
            voteOptionId
        ] = userNewVoteCount;
        _usersStakedEpisodeVotingHistoryCount[msg.sender][episodeId][
            voteOptionId
        ] = userNewVoteCount;
        _episodeVotesByOptionId[episodeId][voteOptionId] =
            currentTotalVoteCount +
            amount;

        // Take custody of producer passes from user
        whiteRabbitProducerPass.safeTransferFrom(
            msg.sender,
            address(this),
            episodeId,
            amount,
            ""
        );
        // Distribute wr tokens to user
        IERC20(whiteRabbitTokenAddress).transfer(msg.sender, tokensAllocated);

        emit ProducerPassStaked(
            msg.sender,
            episodeId,
            voteOptionId,
            amount,
            tokensAllocated
        );
    }

    /**
     * @dev Unstakes Producer Passes for the given episode's voting option ID and
     * sends White Rabbit tokens to the user's wallet if they staked for the winning side.
     *
     *
     * Emits a `ProducerPassUnstaked` event indicating that the unstaking was successful,
     * including the total number of White Rabbit tokens allocated as a result.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     * - Voting is not enabled for the given episode
     * - The episode voting option is valid
     * - A winning option has been declared
     */
    function unstakeProducerPasses(uint256 episodeId, uint256 voteOptionId)
        public
    {
        require(!votingEnabledForEpisode[episodeId], "Voting is still enabled");
        uint256 stakedProducerPassCount = _usersStakedEpisodeVotingOptionsCount[
            msg.sender
        ][episodeId][voteOptionId];
        require(stakedProducerPassCount > 0, "No producer passes staked");
        uint256 winningBonus = getUserWinningBonus(episodeId, voteOptionId) *
            stakedProducerPassCount;

        _usersStakedEpisodeVotingOptionsCount[msg.sender][episodeId][
            voteOptionId
        ] = 0;
        if (winningBonus > 0) {
            IERC20(whiteRabbitTokenAddress).transfer(msg.sender, winningBonus);
        }
        whiteRabbitProducerPass.safeTransferFrom(
            address(this),
            msg.sender,
            episodeId,
            stakedProducerPassCount,
            ""
        );

        emit ProducerPassUnstaked(
            msg.sender,
            episodeId,
            voteOptionId,
            winningBonus
        );
    }

    /**
     * @dev Calculates the number of White Rabbit tokens to award the user for unstaking
     * their Producer Passes for a given episode's voting option ID.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     * - Voting is not enabled for the given episode
     * - The episode voting option is valid
     * - A winning option has been declared
     */
    function getUserWinningBonus(uint256 episodeId, uint256 episodeOptionId)
        public
        view
        returns (uint256)
    {
        uint256 winningVoteOptionId = winningVoteOptionByEpisode[episodeId];
        require(winningVoteOptionId > 0, "Voting is not finished");
        require(!votingEnabledForEpisode[episodeId], "Voting is still enabled");

        bool isWinningOption = winningVoteOptionId == episodeOptionId;
        uint256 numberOfWinningVotes = _episodeVotesByOptionId[episodeId][
            episodeOptionId
        ];
        uint256 winningBonus = 0;

        if (isWinningOption && numberOfWinningVotes > 0) {
            winningBonus =
                producerPassTokenWinningBonusAllocationPerEpisode /
                numberOfWinningVotes;
        }
        return winningBonus;
    }

    /**
     * @dev This method is only for the owner since we want to hide the voting results from the public
     * until after voting has ended. Users can verify the veracity of this via the `episodeVotes` method
     * which can be called publicly after voting has finished for an episode.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     */
    function getTotalVotesForEpisode(uint256 episodeId)
        external
        view
        onlyOwner
        returns (uint256[] memory)
    {
        uint256[] memory votingOptionsForThisEpisode = _episodeOptions[
            episodeId
        ];
        uint256[] memory totalVotes = new uint256[](
            votingOptionsForThisEpisode.length
        );

        for (uint256 i = 0; i < votingOptionsForThisEpisode.length; i++) {
            uint256 currentVotingOptionId = votingOptionsForThisEpisode[i];
            uint256 votesForEpisode = _episodeVotesByOptionId[episodeId][
                currentVotingOptionId
            ];

            totalVotes[i] = votesForEpisode;
        }

        return totalVotes;
    }

    /**
     * @dev Owner method to toggle the voting state of a given episode.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     * - The voting state is different than the current state
     * - A winning option has not yet been declared
     */
    function setVotingEnabledForEpisode(uint256 episodeId, bool enabled)
        public
        onlyOwner
    {
        require(episodeId <= episodes.length, "Episode does not exist");
        require(
            votingEnabledForEpisode[episodeId] != enabled,
            "Voting state unchanged"
        );
        // if winner already set, don't allow re-opening of voting
        if (enabled) {
            require(
                winningVoteOptionByEpisode[episodeId] == 0,
                "Winner for episode already set"
            );
        }
        votingEnabledForEpisode[episodeId] = enabled;
    }

    /**
     * @dev Sets up the distribution parameters for White Rabbit (WRAB) tokens.
     *
     * - We will create fractionalized NFT basket first, which will represent the finished film NFT
     * - Tokens will be stored on platform and distributed to artists and producers as the film progresses
     *   - Artist distribution happens when new episodes are uploaded
     *   - Producer distribution happens when Producer Passes are staked and unstaked (with a bonus for winning the vote)
     *
     * Requirements:
     *
     * - The allocation percentages do not exceed 100%
     */
    function startWhiteRabbitShowWithParams(
        address tokenAddress,
        address artist1Address,
        address artist2Address,
        uint256 numberOfEpisodes,
        uint256 producersAllocationPercentage,
        uint256 artistAllocationPercentage,
        uint256 teamAllocationPercentage
    ) external onlyOwner {
        require(
            (producersAllocationPercentage +
                artistAllocationPercentage +
                teamAllocationPercentage) <= 100,
            "Total percentage exceeds 100"
        );
        whiteRabbitTokenAddress = tokenAddress;
        tokenInitialFixedSupply = IERC20(whiteRabbitTokenAddress).totalSupply();
        _artist1Address = artist1Address;
        _artist2Address = artist2Address;
        _numberOfEpisodes = numberOfEpisodes;
        producersTokenAllocationPercentage = producersAllocationPercentage;
        artistTokenAllocationPercentage = artistAllocationPercentage;
        teamTokenAllocationPercentage = teamAllocationPercentage;
        // If total supply is 1000000 and pct is 40 => (1000000 * 40) / (7 * 100 * 2) => 28571
        artistTokenPerEpisodePerArtist =
            (tokenInitialFixedSupply * artistTokenAllocationPercentage) /
            (_numberOfEpisodes * 100 * 2); // 2 for 2 artists
        // If total supply is 1000000 and pct is 40 => (1000000 * 40) / (7 * 100) => 57142
        producerPassTokenAllocationPerEpisode =
            (tokenInitialFixedSupply * producersTokenAllocationPercentage) /
            (_numberOfEpisodes * 100);
    }

    /**
     * @dev Sets the White Rabbit (WRAB) token distrubution for producers.
     * This distribution is broken into 3 categories:
     * - Base allocation (every Producer Pass gets the same)
     * - Early staking bonus (bonding curve distribution where earlier stakers are rewarded more)
     * - Winning bonus (extra pot split among winning voters)
     *
     * Requirements:
     *
     * - The allocation percentages do not exceed 100%
     */
    function setProducerPassWhiteRabbitTokensAllocationParameters(
        uint256 earlyStakingBonus,
        uint256 winningVoteBonus
    ) external onlyOwner {
        require(
            (earlyStakingBonus + winningVoteBonus) <= 100,
            "Total percentage exceeds 100"
        );
        uint256 basePercentage = 100 - earlyStakingBonus - winningVoteBonus;
        producerPassTokenBaseAllocationPerEpisode =
            (producerPassTokenAllocationPerEpisode * basePercentage) /
            100;
        producerPassTokenEarlyStakingBonusAllocationPerEpisode =
            (producerPassTokenAllocationPerEpisode * earlyStakingBonus) /
            100;
        producerPassTokenWinningBonusAllocationPerEpisode =
            (producerPassTokenAllocationPerEpisode * winningVoteBonus) /
            100;
    }

    /**
     * @dev Calculates the number of White Rabbit tokens the user would receive if the
     * provided `amount` of Producer Passes is staked for the given episode.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     */
    function getTokenAllocationForUserBeforeStaking(
        uint256 episodeId,
        uint256 amount
    ) public view returns (uint256) {
        ProducerPass memory pass = whiteRabbitProducerPass
            .getEpisodeToProducerPass(episodeId);
        uint256 maxSupply = pass.maxSupply;
        uint256 basePerPass = SafeMath.div(
            producerPassTokenBaseAllocationPerEpisode,
            maxSupply
        );

        // Get total vote count from every option of this episode for bonding curve calculation
        uint256[] memory votingOptionsForThisEpisode = _episodeOptions[
            episodeId
        ];
        uint256 totalVotesForEpisode = 0;
        for (uint256 i = 0; i < votingOptionsForThisEpisode.length; i++) {
            uint256 currentVotingOptionId = votingOptionsForThisEpisode[i];
            totalVotesForEpisode += _episodeVotesByOptionId[episodeId][
                currentVotingOptionId
            ];
        }

        // Below calculates number of tokens user will receive if staked
        // using a linear bonding curve where early stakers get more
        // Y = aX (where X = number of stakers, a = Slope, Y = tokens each staker receives)
        uint256 maxBonusY = 1000 *
            ((producerPassTokenEarlyStakingBonusAllocationPerEpisode * 2) /
                maxSupply);
        uint256 slope = SafeMath.div(maxBonusY, maxSupply);

        uint256 y1 = (slope * (maxSupply - totalVotesForEpisode));
        uint256 y2 = (slope * (maxSupply - totalVotesForEpisode - amount));
        uint256 earlyStakingBonus = (amount * (y1 + y2)) / 2;
        return basePerPass * amount + earlyStakingBonus / 1000;
    }

    function endVotingForEpisode(uint256 episodeId) external onlyOwner {
        uint256[] memory votingOptionsForThisEpisode = _episodeOptions[
            episodeId
        ];
        uint256 winningOptionId = 0;
        uint256 totalVotesForWinningOption = 0;

        for (uint256 i = 0; i < votingOptionsForThisEpisode.length; i++) {
            uint256 currentOptionId = votingOptionsForThisEpisode[i];
            uint256 votesForEpisode = _episodeVotesByOptionId[episodeId][
                currentOptionId
            ];

            if (votesForEpisode >= totalVotesForWinningOption) {
                winningOptionId = currentOptionId;
                totalVotesForWinningOption = votesForEpisode;
            }
        }

        setVotingEnabledForEpisode(episodeId, false);
        winningVoteOptionByEpisode[episodeId] = winningOptionId;
    }

    /**
     * @dev Manually sets the winning voting option for a given episode.
     * Only call this method to break a tie among voting options for an episode.
     *
     * Requirements:
     *
     * - This should only be called for ties
     */
    function endVotingForEpisodeOverride(
        uint256 episodeId,
        uint256 winningOptionId
    ) external onlyOwner {
        setVotingEnabledForEpisode(episodeId, false);
        winningVoteOptionByEpisode[episodeId] = winningOptionId;
    }

    /**
     * Token distribution for artists and team
     */

    /**
     * @dev Sends the artists their allocation of White Rabbit tokens after an episode is launched.
     *
     * Requirements:
     *
     * - The artists have not yet received their tokens for the given episode
     */
    function sendArtistTokensForEpisode(uint256 episodeId) external onlyOwner {
        require(
            !hasTransferredTokensToArtistForEpisode[episodeId],
            "Artist tokens distributed"
        );

        hasTransferredTokensToArtistForEpisode[episodeId] = true;

        IERC20(whiteRabbitTokenAddress).transfer(
            _artist1Address,
            artistTokenPerEpisodePerArtist
        );
        IERC20(whiteRabbitTokenAddress).transfer(
            _artist2Address,
            artistTokenPerEpisodePerArtist
        );
    }

    /**
     * @dev Transfers White Rabbit tokens to the team based on the `teamTokenAllocationPercentage`
     *
     * Requirements:
     *
     * - The tokens have not yet been distributed to the team
     */
    function withdrawTokensForTeamAllocation(address[] calldata teamAddresses)
        external
        onlyOwner
    {
        require(!teamTokenAllocationDistributed, "Team tokens distributed");

        uint256 teamBalancePerMember = (teamTokenAllocationPercentage *
            tokenInitialFixedSupply) / (100 * teamAddresses.length);
        for (uint256 i = 0; i < teamAddresses.length; i++) {
            IERC20(whiteRabbitTokenAddress).transfer(
                teamAddresses[i],
                teamBalancePerMember
            );
        }

        teamTokenAllocationDistributed = true;
    }

    /**
     * @dev Transfers White Rabbit tokens to the team based on the platform allocation
     *
     * Requirements:
     *
     * - All Episodes finished
     * - Voting completed
     */
    function withdrawPlatformReserveTokens() external onlyOwner {
        require(episodes.length == _numberOfEpisodes, "Show not ended");
        require(
            !votingEnabledForEpisode[_numberOfEpisodes],
            "Last episode still voting"
        );
        uint256 leftOverBalance = IERC20(whiteRabbitTokenAddress).balanceOf(
            address(this)
        );
        IERC20(whiteRabbitTokenAddress).transfer(msg.sender, leftOverBalance);
    }
}
