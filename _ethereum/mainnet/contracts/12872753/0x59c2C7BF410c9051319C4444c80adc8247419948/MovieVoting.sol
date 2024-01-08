//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.2;

import "./SafeMath.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./IERC1155.sol";
import "./BasicMetaTransaction.sol";
import "./IMogulSmartWallet.sol";
import "./IMovieVotingMasterChef.sol";
import "./Sqrt.sol";

contract MovieVoting is BasicMetaTransaction, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    // The Stars token.
    IERC20 public stars;
    // The movie NFT.
    IERC1155 public mglMovie;
    // The staking contrract.
    IMovieVotingMasterChef movieVotingMasterChef;
    // Max amount of movies per round
    uint256 public constant MAX_MOVIES = 5;

    enum VotingRoundState { Active, Paused, Canceled, Executed }

    struct VotingRound {
        // list of movies available to vote on.
        // The list must be filled left to right, leaving empty slots as 0.
        uint256[MAX_MOVIES] movieIds;
        // voting starts on this block.
        uint256 startVoteBlockNum;
        // voting ends at this block.
        uint256 endVoteBlockNum;
        // total Stars rewards for the round.
        uint256 starsRewards;
        VotingRoundState votingRoundState;
        // mapping variables: movieId
        mapping(uint256 => uint256) votes;
        // mapping variables: userAddress
        mapping(address => bool) rewardsClaimed;
        // mapping variables: userAddress, movieId
        mapping(address => mapping(uint256 => uint256)) totalStarsEntered;
    }

    VotingRound[] public votingRounds;

    event VotingRoundCreated(
        uint256[MAX_MOVIES] movieIds,
        uint256 startVoteBlockNum,
        uint256 endVoteBlockNum,
        uint256 starsRewards,
        uint256 votingRound
    );
    event VotingRoundPaused(uint256 roundId);
    event VotingRoundUnpaused(uint256 roundId);
    event VotingRoundCanceled(uint256 roundId);
    event VotingRoundExecuted(uint256 roundId);

    event Voted(
        address voter,
        uint256 roundId,
        uint256 movieId,
        uint256 starsAmountMantissa,
        uint256 quadraticVoteScore
    );
    event Unvoted(
        address voter,
        uint256 roundId,
        uint256 movieId,
        uint256 starsAmountMantissa,
        uint256 quadraticVoteScore
    );

    modifier onlyAdmin {
        require(hasRole(ROLE_ADMIN, msgSender()), "Sender is not admin");
        _;
    }

    modifier votingRoundMustExist(uint256 roundId) {
        require(
            roundId < votingRounds.length,
            "Voting Round id does not exist yet"
        );
        _;
    }

    /**
     * @dev Sets the admin role and records the stars, movie nft
     * and staking contract addresses. Also approves Stars
     * for the staking contract.
     *
     * Parameters:
     *
     * - _admin: admin of the smart wallet.
     * - _stars: Stars token address.
     * - _mglMovie: Movie NFT address.
     * - _movieVotingMasterChef: staking contract address.
     *
     */
    constructor(
        address _admin,
        address _stars,
        address _mglMovie,
        address _movieVotingMasterChef
    ) public {
        _setupRole(ROLE_ADMIN, _admin);
        _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);

        stars = IERC20(_stars);
        mglMovie = IERC1155(_mglMovie);
        movieVotingMasterChef = IMovieVotingMasterChef(_movieVotingMasterChef);
        // Note: uint256(-1) is max number
        stars.approve(_movieVotingMasterChef, uint256(-1));
    }

    /**
     * @dev Returns all movie NFT ids of the voting round.
     * id 0 represents empty slot.
     *
     * Parameters:
     *
     * - votingRoundId: id of the voting round.
     */
    function getMovieIds(uint256 votingRoundId)
        external
        view
        returns (uint256[MAX_MOVIES] memory)
    {
        return votingRounds[votingRoundId].movieIds;
    }

    /**
     * @dev Returns all movie NFT votes of the voting round.
     *
     * Parameters:
     *
     * - votingRoundId: voting round id.
     */
    function getMovieVotes(uint256 votingRoundId)
        external
        view
        returns (uint256[MAX_MOVIES] memory)
    {
        VotingRound storage votingRound = votingRounds[votingRoundId];
        uint256[MAX_MOVIES] memory votes;
        for (uint256 i; i < MAX_MOVIES; i++) {
            votes[i] = (votingRound.votes[votingRound.movieIds[i]]);
        }
        return votes;
    }

    /**
     * @dev Returns the details of the voting round.
     *
     * Parameters:
     *
     * - votingRoundId: voting round id.
     */
    function getVotingRound(uint256 votingRoundId)
        external
        view
        returns (
            uint256[MAX_MOVIES] memory,
            uint256[MAX_MOVIES] memory,
            uint256,
            uint256,
            uint256,
            VotingRoundState
        )
    {
        VotingRound storage votingRound = votingRounds[votingRoundId];
        uint256[MAX_MOVIES] memory movieIds = votingRound.movieIds;
        uint256[MAX_MOVIES] memory votes;

        for (uint256 i; i < MAX_MOVIES; i++) {
            votes[i] = (votingRound.votes[votingRound.movieIds[i]]);
        }
        return (
            movieIds,
            votes,
            votingRound.startVoteBlockNum,
            votingRound.endVoteBlockNum,
            votingRound.starsRewards,
            votingRound.votingRoundState
        );
    }

    /**
     * @dev Returns the total stars entered by a user.
     *
     * Parameters:
     *
     * - userAddress: user's address.
     * - movieId: movie round id.
     * - votingRoundId: voting round id.
     */
    function getUserMovieTotalStarsEntered(
        address userAddress,
        uint256 movieId,
        uint256 votingRoundId
    ) external view returns (uint256) {
        uint256 userMovieTotalStarsEntered =
            votingRounds[votingRoundId].totalStarsEntered[userAddress][movieId];
        return userMovieTotalStarsEntered;
    }

    /**
     * @dev Returns if user has already claimed their Stars rewards.
     *
     * Parameters:
     *
     * - userAddress: user's address.
     * - votingRoundId: voting round id.
     */
    function didUserClaimRewards(address userAddress, uint256 votingRoundId)
        external
        view
        returns (bool)
    {
        bool _didUserClaimRewards =
            votingRounds[votingRoundId].rewardsClaimed[userAddress];
        return _didUserClaimRewards;
    }

    /**
     * @dev Creates a new movie voting round.
     *
     * Parameters:
     *
     * - movieIds: list of movie ids, filled from left to right.
     * Id 0 represents empty slot.
     * - startVoteBlockNum: the block voting will start on.
     * - endVoteBlockNum: the block voting will end on.
     * - starsRewards: the total Stars rewards to distribute to voters.
     *
     * Requirements:
     *
     * - Start Vote Block must be less than End Vote Block.
     * - Caller must be an admin.
     */
    function createNewVotingRound(
        uint256[MAX_MOVIES] calldata movieIds,
        uint256 startVoteBlockNum,
        uint256 endVoteBlockNum,
        uint256 starsRewards
    ) external onlyAdmin {
        require(
            startVoteBlockNum < endVoteBlockNum,
            "Start block must be less than end block"
        );

        VotingRound memory votingRound;
        votingRound.movieIds = movieIds;
        votingRound.startVoteBlockNum = startVoteBlockNum;
        votingRound.endVoteBlockNum = endVoteBlockNum;
        votingRound.starsRewards = starsRewards;
        votingRound.votingRoundState = VotingRoundState.Active;

        votingRounds.push(votingRound);

        stars.transferFrom(msgSender(), address(this), starsRewards);

        // transfer stars for rewards
        movieVotingMasterChef.add(
            startVoteBlockNum,
            endVoteBlockNum,
            starsRewards,
            false
        );

        emit VotingRoundCreated(
            movieIds,
            startVoteBlockNum,
            endVoteBlockNum,
            starsRewards,
            votingRounds.length
        );
    }

    /**
     * @dev Pause a movie voting round.
     *
     * Parameters:
     *
     * - roundId: Voting round id.
     *
     * Requirements:
     *
     * - Caller must be an admin.
     * - Voting round must exist.
     * - Voting round must be active.
     * - Voting round has not ended.
     */
    function pauseVotingRound(uint256 roundId)
        external
        onlyAdmin
        votingRoundMustExist(roundId)
    {
        VotingRound storage votingRound = votingRounds[roundId];

        require(
            votingRound.votingRoundState == VotingRoundState.Active,
            "Only active voting rounds can be paused"
        );
        require(
            votingRound.endVoteBlockNum >= block.number,
            "Voting Round has already concluded"
        );
        votingRound.votingRoundState = VotingRoundState.Paused;

        emit VotingRoundPaused(roundId);
    }

    /**
     * @dev Unpause a movie voting round.
     *
     * Parameters:
     *
     * - roundId: Voting round id.
     *
     * Requirements:
     *
     * - Caller must be an admin.
     * - Voting round must exist.
     * - Voting round must be paused.
     */
    function unpauseVotingRound(uint256 roundId)
        external
        onlyAdmin
        votingRoundMustExist(roundId)
    {
        VotingRound storage votingRound = votingRounds[roundId];

        require(
            votingRound.votingRoundState == VotingRoundState.Paused,
            "Only paused voting rounds can be unpaused"
        );
        votingRound.votingRoundState = VotingRoundState.Active;

        emit VotingRoundUnpaused(roundId);
    }

    /**
     * @dev Cancel a movie voting round.
     *
     * Parameters:
     *
     * - roundId: Voting round id.
     *
     * Requirements:
     *
     * - Caller must be an admin.
     * - Voting round must exist.
     * - Voting round must be active or paused.
     */
    function cancelVotingRound(uint256 roundId)
        external
        onlyAdmin
        votingRoundMustExist(roundId)
    {
        VotingRound storage votingRound = votingRounds[roundId];

        require(
            votingRound.votingRoundState == VotingRoundState.Active ||
                votingRound.votingRoundState == VotingRoundState.Paused,
            "Only active or paused voting rounds can be cancelled"
        );
        require(
            block.number <= votingRound.endVoteBlockNum,
            "Voting Round has already concluded"
        );
        votingRound.votingRoundState = VotingRoundState.Canceled;

        emit VotingRoundCanceled(roundId);
    }

    /**
     * @dev Execute a movie voting round.
     *
     * Parameters:
     *
     * - roundId: Voting round id.
     *
     * Requirements:
     *
     * - Caller must be an admin.
     * - Voting round must exist.
     * - Voting round must be active.
     * - Voting round has not ended.
     */
    function executeVotingRound(uint256 roundId)
        external
        onlyAdmin
        votingRoundMustExist(roundId)
    {
        VotingRound storage votingRound = votingRounds[roundId];

        require(
            votingRound.votingRoundState == VotingRoundState.Active,
            "Only active voting rounds can be executed"
        );
        require(
            votingRound.endVoteBlockNum < block.number,
            "Voting round has not ended"
        );
        votingRound.votingRoundState = VotingRoundState.Executed;

        emit VotingRoundExecuted(roundId);
    }

    /**
     * @dev Returns the total amount of voting rounds
     * that have been created.
     *
     */
    function totalVotingRounds() external view returns (uint256) {
        return votingRounds.length;
    }

    /**
     * @dev Checks if the caller is the owner of the Mogul Smart Wallet and return its address.
     * Return the caller's addres if it is declared smart wallet is not used.
     *
     * Parameters:
     *
     * - isMogulSmartWallet: Whether or not smart wallet is used.
     * - mogulSmartWallet: address of the smart wallet, Zero address is passed if not used.
     * - msgSender: address of the caller.
     *
     */
    function _verifySmartWalletOwner(
        bool isMogulSmartWallet,
        address mogulSmartWallet,
        address msgSender
    ) internal returns (address) {
        if (isMogulSmartWallet) {
            require(
                msgSender == IMogulSmartWallet(mogulSmartWallet).owner(),
                "Invalid Mogul Smart Wallet Owner"
            );
            return mogulSmartWallet;
        } else {
            return msgSender;
        }
    }

    /**
     * @dev Vote for a movie by staking Stars.
     *
     * Parameters:
     *
     * - roundId: voting round id.
     * - movieId: movie id to vote for.
     * - starsAmountMantissa: total Stars to stake.
     * - isMogulSmartWallet: Whether or not smart wallet is used.
     * - mogulSmartWallet: address of the smart wallet, Zero address is passed if not used.
     *
     * Requirements:
     *
     * - Voting round id must exists.
     * - Must deposit at least 1 Stars token.
     * - Movie Id must be in voting round.
     * - Voting round must be active.
     * - Voting round must be started and has not ended.
     */
    function voteForMovie(
        uint256 roundId,
        uint256 movieId,
        uint256 starsAmountMantissa,
        bool isMogulSmartWallet,
        address mogulSmartWalletAddress
    ) external votingRoundMustExist(roundId) {
        require(
            starsAmountMantissa >= 1 ether,
            "Must deposit at least 1 Stars token"
        );

        address _msgSender =
            _verifySmartWalletOwner(
                isMogulSmartWallet,
                mogulSmartWalletAddress,
                msgSender()
            );

        VotingRound storage votingRound = votingRounds[roundId];

        uint256[MAX_MOVIES] memory movieIds = votingRound.movieIds;
        require(
            movieId != 0 &&
                (movieId == movieIds[0] ||
                    movieId == movieIds[1] ||
                    movieId == movieIds[2] ||
                    movieId == movieIds[3] ||
                    movieId == movieIds[4]),
            "Movie Id is not in voting round"
        );

        require(
            votingRound.votingRoundState == VotingRoundState.Active,
            "Can only vote in active rounds"
        );

        require(
            votingRound.startVoteBlockNum <= block.number &&
                block.number <= votingRound.endVoteBlockNum,
            "Voting round has not started or has ended"
        );

        uint256 quadraticVoteScoreOld =
            Sqrt.sqrt(
                votingRound.totalStarsEntered[_msgSender][movieId].div(1 ether)
            );

        votingRound.totalStarsEntered[_msgSender][movieId] = votingRound
            .totalStarsEntered[_msgSender][movieId]
            .add(starsAmountMantissa);

        uint256 quadraticVoteScoreNew =
            Sqrt.sqrt(
                votingRound.totalStarsEntered[_msgSender][movieId].div(1 ether)
            );

        votingRound.votes[movieId] = votingRound.votes[movieId]
            .add(quadraticVoteScoreNew)
            .sub(quadraticVoteScoreOld);

        movieVotingMasterChef.deposit(roundId, starsAmountMantissa, _msgSender);

        emit Voted(
            _msgSender,
            roundId,
            movieId,
            starsAmountMantissa,
            quadraticVoteScoreNew
        );
    }

    /**
     * @dev Remove vote for a movie by withdrawing Stars, and forgoing Stars rewards.
     *
     * Parameters:
     *
     * - roundId: voting round id.
     * - movieId: movie id to vote for.
     * - starsAmountMantissa: total Stars to stake.
     * - isMogulSmartWallet: Whether or not smart wallet is used.
     * - mogulSmartWallet: address of the smart wallet, Zero address is passed if not used.
     *
     * Requirements:
     *
     * - Voting round id must exists.
     * - Must withdraw more than 0 Stars token.
     * - Must have enough Stars deposited to withdraw.
     * - Movie Id must be in voting round.
     * - Voting round must be active.
     * - Voting round must be started and has not ended.
     */
    function removeVoteForMovie(
        uint256 roundId,
        uint256 movieId,
        uint256 starsAmountMantissa,
        bool isMogulSmartWallet,
        address mogulSmartWalletAddress
    ) external votingRoundMustExist(roundId) {
        require(starsAmountMantissa > 0, "Cannot remove 0 votes");

        address _msgSender =
            _verifySmartWalletOwner(
                isMogulSmartWallet,
                mogulSmartWalletAddress,
                msgSender()
            );

        VotingRound storage votingRound = votingRounds[roundId];

        uint256[MAX_MOVIES] memory movieIds = votingRound.movieIds;
        require(
            movieId == movieIds[0] ||
                movieId == movieIds[1] ||
                movieId == movieIds[2] ||
                movieId == movieIds[3] ||
                movieId == movieIds[4],
            "Movie Id is not in voting round"
        );
        require(
            starsAmountMantissa <=
                votingRound.totalStarsEntered[_msgSender][movieId],
            "Not enough Stars to remove"
        );
        require(
            votingRound.votingRoundState == VotingRoundState.Active,
            "Can only remove vote in active rounds"
        );

        require(
            votingRound.startVoteBlockNum <= block.number &&
                block.number <= votingRound.endVoteBlockNum,
            "Voting round has not started or ended"
        );

        uint256 oldQuadraticVoteScore =
            Sqrt.sqrt(
                votingRound.totalStarsEntered[_msgSender][movieId].div(1 ether)
            );

        votingRound.totalStarsEntered[_msgSender][movieId] = votingRound
            .totalStarsEntered[_msgSender][movieId]
            .sub(starsAmountMantissa);

        uint256 updatedUserTotalStarsEntered =
            votingRound.totalStarsEntered[_msgSender][movieId];

        movieVotingMasterChef.withdrawPartial(
            roundId,
            starsAmountMantissa,
            _msgSender
        );

        votingRound.votes[movieId] = votingRound.votes[movieId]
            .add(Sqrt.sqrt(updatedUserTotalStarsEntered.div(1 ether)))
            .sub(oldQuadraticVoteScore);

        emit Unvoted(
            _msgSender,
            roundId,
            movieId,
            starsAmountMantissa,
            Sqrt.sqrt(updatedUserTotalStarsEntered.div(1 ether))
        );
    }

    function calculateStarsRewards(address userAddress, uint256 roundId)
        external
        view
        votingRoundMustExist(roundId)
        returns (uint256)
    {
        return movieVotingMasterChef.pendingStars(roundId, userAddress);
    }

    /**
     * @dev Withdraw deposited Stars and claim Stars rewards for a given
     * voting round.
     *
     * Parameters:
     *
     * - roundId: voting round id.
     * - isMogulSmartWallet: Whether or not smart wallet is used.
     * - mogulSmartWallet: address of the smart wallet, Zero address is passed if not used.
     *
     * Requirements:
     *
     * - Rewards has not been claimed.
     */
    function withdrawAndClaimStarsRewards(
        uint256 roundId,
        bool isMogulSmartWallet,
        address mogulSmartWalletAddress
    ) external votingRoundMustExist(roundId) {
        address _msgSender =
            _verifySmartWalletOwner(
                isMogulSmartWallet,
                mogulSmartWalletAddress,
                msgSender()
            );

        VotingRound storage votingRound = votingRounds[roundId];

        require(
            !votingRound.rewardsClaimed[_msgSender],
            "Rewards have already been claimed"
        );

        votingRound.rewardsClaimed[_msgSender] = true;

        movieVotingMasterChef.withdraw(roundId, _msgSender);
    }

    /**
     * @dev Withdraw deposited ETH.
     *
     * Requirements:
     *
     * - Withdrawer must be an admin
     */
    function withdrawETH() external onlyAdmin {
        payable(msgSender()).transfer(address(this).balance);
    }
}
