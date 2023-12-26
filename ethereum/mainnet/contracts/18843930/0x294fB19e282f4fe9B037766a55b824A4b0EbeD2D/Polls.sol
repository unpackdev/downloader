// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Polls is Ownable {
	/* EVENTS  */
	event voteCasted(address voter, uint256 pollID, uint256 vote, uint256 weight);
	event pollCreated(address creator, uint256 pollID, string description, uint256 votingLength, bool lotteryBounty, uint256 tokensBounty);
	event pollStatusUpdate(uint256 pollID, PollStatus status);
	event bountyAssigned(uint256 pollID, uint256 numTokens);
	event bountyGiven(uint256 pollID);

	/* Determine the current state of a poll */
	enum PollStatus { IN_PROGRESS, ENDED }

	/* Determine mechanism to give bounty for a poll */
	enum BountyMechanism { PROPORTIONAL, LOTTERY }

	/* POLL */
	struct Poll {
		string[] options;
		uint256[] optionVotes;
		uint256 optionWinning;
		uint256 expirationTimeInDays;
		string description;
		PollStatus status;
		address creator;
		address[] voters;
		mapping(address => Voter) voterInfo;
		BountyMechanism mechanism;
		address winner;
	}

	/* VOTER */
	struct Voter {
		bool hasVoted;
		uint256 vote;
		uint256 weight;
	}

	/* TOKEN MANAGER */
	struct TokenManager {
		uint256 tokenBalance;
		uint256[] participatedPolls;
		mapping(uint256 => uint256) lockedTokens;
		mapping(uint256 => uint256) bountyTokens;
	}

	uint256 public pollCount;
	uint256 public limit;
	mapping(uint256 => Poll) public polls;
	mapping(address => TokenManager) public bank;
	mapping(uint256 => uint256) public bounties;
	IERC20 public token;

	/* AUTHENTICATION */
    address public master;

    modifier onlyOwnerOrMaster() {
        require(msg.sender == owner() || msg.sender == master);
        _;
    }

	constructor(address _token, uint256 _limit) {
		require(_token != address(0) );
		token = IERC20(_token);
		limit = _limit;
	}

	/* AUTHENTICATION OPERATIONS */

    /**
     *Sets a new master
     */
    function setMaster(address _master) external onlyOwner {
        master = _master;
    }

	/* POLL OPERATIONS */

	/*
	 * Creates a new poll.
	 * NOTE: _tokensBounty is denominated in *wei*.
	 */
	function createPoll(string calldata _description, uint256 _voteDurationInDays, bool _lotteryBounty, uint256 _tokensBounty) external onlyOwnerOrMaster returns (uint256) {
		require(_voteDurationInDays > 0);
		require(token.balanceOf(msg.sender) >= _tokensBounty);

		uint256 tokensReceived = 0;

		if (_tokensBounty > 0) {
			uint256 initialBalance = token.balanceOf(address(this));
			require(token.transferFrom(msg.sender, address(this), _tokensBounty));
			uint256 finalBalance = token.balanceOf(address(this));
			tokensReceived = finalBalance - initialBalance;
		}

		pollCount++;

		Poll storage curPoll = polls[pollCount];
		curPoll.creator = owner();
		curPoll.status = PollStatus.IN_PROGRESS;
		curPoll.expirationTimeInDays = block.timestamp + _voteDurationInDays * 1 days;
		curPoll.description = _description;

		if (_lotteryBounty) {
			curPoll.mechanism = BountyMechanism.LOTTERY;
		} else {
			curPoll.mechanism = BountyMechanism.PROPORTIONAL;
		}		

		emit pollCreated(owner(), pollCount, _description, _voteDurationInDays, _lotteryBounty, tokensReceived);

		assignBounty(pollCount, tokensReceived);

		return pollCount;
	}

	/*
	 * Ends a poll. Only the creator of a given poll can end that poll.
	 */
	function endPoll(uint256 _pollID, bool _force) external onlyOwnerOrMaster validPoll(_pollID) {
		require(polls[_pollID].status == PollStatus.IN_PROGRESS, "Poll has already ended.");

		if (!_force) {
			require(block.timestamp >= getPollExpirationTime(_pollID), "Voting period has not expired");
		}

		// Assign winning option to the poll
		uint256 winner = 0;

		for (uint256 i = 0; i < polls[_pollID].options.length; i++) {
			if (polls[_pollID].optionVotes[i] > polls[_pollID].optionVotes[winner]) {
				winner = i;
			}
		}

		polls[_pollID].optionWinning = winner;
		polls[_pollID].status = PollStatus.ENDED;

		updateTokenBank(_pollID, false);
		giveBounty(_pollID);

		emit pollStatusUpdate(_pollID, polls[_pollID].status);
	}

	function addOption(uint256 _pollID, string calldata _optionDescription) external onlyOwnerOrMaster validPoll(_pollID) {
		require(polls[_pollID].voters.length == 0, "Poll is in progress. It is not possible to add an option at this time.");

		polls[_pollID].options.push(_optionDescription);
		polls[_pollID].optionVotes.push(0);
	}

	function removeOption(uint256 _pollID, uint256 _optionIndex) external onlyOwnerOrMaster validPoll(_pollID) {
		require(polls[_pollID].voters.length == 0, "Poll is in progress. It is not possible to remove an option at this time.");

		string[] memory newOptions = new string[](polls[_pollID].options.length - 1);
		uint256[] memory newVotes = new uint256[](polls[_pollID].optionVotes.length - 1);
		uint256 index = 0;

		for (uint256 i = 0; i < polls[_pollID].options.length; i++) {
			if (i != _optionIndex) {
				newOptions[index] = polls[_pollID].options[i];
				newVotes[index] = polls[_pollID].optionVotes[i];
				index++;
			}
		}

		polls[_pollID].options = newOptions;
		polls[_pollID].optionVotes = newVotes;
	}

	/* GETTERS */

	/*
	 * Gets the status of a poll.
	 */
	function getPollStatus(uint256 _pollID) public view validPoll(_pollID) returns (PollStatus) {
		return polls[_pollID].status;
	}

	/*
	 * Gets the winning option of a poll.
	 */
	function getPollWinningOption(uint256 _pollID) public view validPoll(_pollID) returns (uint256) {
		require(polls[_pollID].status == PollStatus.ENDED, "Poll is still in progress.");
		return polls[_pollID].optionWinning;
	}

	/*
	 * Gets the complete list of options for a poll with their votes.
	 */
	function getPollOptions(uint256 _pollID) public view returns(string[] memory, uint256[] memory) {
		return (polls[_pollID].options, polls[_pollID].optionVotes);
	}

	/*
	 * Gets the expiration date of a poll.
	 */
	function getPollExpirationTime(uint256 _pollID) public view validPoll(_pollID) returns (uint256) {
		return polls[_pollID].expirationTimeInDays;
	}

	/*
	 * Gets the expiration date of a poll.
	 */
	function getPollDescription(uint256 _pollID) public view validPoll(_pollID) returns (string memory) {
		return polls[_pollID].description;
	}

	/*
	 * Gets the number of tokens of the bounty of a given poll.
	 */
	function getPollBountyTokens(uint256 _pollID) public view validPoll(_pollID) returns (uint256) {
		return bounties[_pollID];
	}

	/*
	 * Gets the mechanism used to give the bounty of a given poll.
	 */
	function getPollBountyMechanism(uint256 _pollID) public view validPoll(_pollID) returns (BountyMechanism) {
		return polls[_pollID].mechanism;
	}

	/*
	 * Gets the winner of the bounty of a given poll.
	 */
	function getPollBountyWinner(uint256 _pollID) public view validPoll(_pollID) returns (address) {
		require(polls[_pollID].mechanism == BountyMechanism.LOTTERY, "Poll mechanism has to be lottery.");
		return polls[_pollID].winner;
	}

	/*
	 * Gets the complete list of polls a user has voted in.
	 */
	function getPollHistory(address _voter) public view returns(uint256[] memory) {
		return bank[_voter].participatedPolls;
	}

	/*
	 * Gets a voter's vote and weight for a given poll.
	 */
	function getPollInfoForVoter(uint256 _pollID, address _voter) public view validPoll(_pollID) returns (uint256, uint256) {
		require(getIfUserHasVoted(_pollID, _voter));
		Poll storage curPoll = polls[_pollID];
		uint256 vote = curPoll.voterInfo[_voter].vote;
		uint256 weight = curPoll.voterInfo[_voter].weight;
		return (vote, weight);
	}

	function getPollsByStatus(uint256 _status) public view returns(string[] memory, uint256[] memory) {
		PollStatus _pollStatus = PollStatus.IN_PROGRESS;

		if (_status == 1) {
			_pollStatus = PollStatus.ENDED;
		}

		uint256 length = 0;

		for (uint256 i = 1; i <= pollCount; i++) {
			if (polls[i].status == _pollStatus) {
				length++;
			}
		}

		string[] memory pollDescriptions = new string[](length);
		uint256[] memory pollIDs = new uint256[](length);

		uint256 index = 0;

		for (uint256 i = 1; i <= pollCount; i++) {
			if (polls[i].status == _pollStatus) {
				pollDescriptions[index] = polls[i].description;
				pollIDs[index] = i;
				index++;
			}
		}

		return (pollDescriptions, pollIDs);
	}

	/*
	 * Gets all the voters of a poll.
	 */
	function getVotersForPoll(uint256 _pollID) public view validPoll(_pollID) returns (address[] memory) {
		require(getPollStatus(_pollID) != PollStatus.IN_PROGRESS);
		return polls[_pollID].voters;
	}

		/*
	 * Gets the amount of Voting Tokens that are locked for a given voter.
	 */

	function getLockedAmount(address _voter) public view returns (uint256) {
		TokenManager storage manager = bank[_voter];
		uint256 largest;
		for (uint256 i = 0; i < manager.participatedPolls.length; i++) {
			uint256 curPollID = manager.participatedPolls[i];
			if (manager.lockedTokens[curPollID] > largest)
				largest = manager.lockedTokens[curPollID];
		}
		return largest;
	}

	/*
	 * Gets the amount of Voting Credits for a given voter.
	 */
	function getTokenStake(address _voter) public view returns(uint256) {
		return bank[_voter].tokenBalance;
	}

	/*
	 * Gets the amount of bounty tokens earned for a given poll by a given voter.
	 */
	function getTokenBounty(address _voter, uint256 _pollID) public view returns(uint256) {
		return bank[_voter].bountyTokens[_pollID];
	}

	/*
	 * Checks if a user has voted for a specific poll.
	 */
	function getIfUserHasVoted(uint256 _pollID, address _user) public view validPoll(_pollID) returns (bool) {
		return (polls[_pollID].voterInfo[_user].hasVoted);
	}

	/*
	 * Modifier that checks for a valid poll ID.
	 */
	modifier validPoll(uint256 _pollID) {
		require(_pollID > 0 && _pollID <= pollCount, "Not a valid poll Id.");
		_;
	}

	/* VOTE OPERATIONS */

	/*
	 * Casts a vote for a given poll.
	 * NOTE: _weight is denominated in *wei*.
	 */
	function castVote(uint256 _pollID, uint256 _vote, uint256 _weight) external validPoll(_pollID) {
		require(_weight > 0, "Weight must be greater than 0.");
		require(getPollStatus(_pollID) == PollStatus.IN_PROGRESS, "Poll has expired.");
		require(!getIfUserHasVoted(_pollID, msg.sender), "User has already voted.");
		require(getPollExpirationTime(_pollID) > block.timestamp);
		require(getTokenStake(msg.sender) >= _weight, "User does not have enough staked tokens.");

		Poll storage curPoll = polls[_pollID];

		require(_vote < curPoll.options.length, "Vote option is not available.");

		// update token bank
		bank[msg.sender].lockedTokens[_pollID] = _weight;
		bank[msg.sender].participatedPolls.push(_pollID);	

		curPoll.voterInfo[msg.sender] = Voter({
				hasVoted: true,
				vote: _vote,
				weight: _weight
		});

		curPoll.optionVotes[_vote] += _weight;

		curPoll.voters.push(msg.sender);
		emit voteCasted(msg.sender, _pollID, _vote, _weight);
	}

	/* TOKEN OPERATIONS */

	/*
	 * Stakes tokens for a given voter in return for voting credits.
	 * NOTE:
	 *  User must approve transfer of tokens.
	 *  _numTokens is denominated in *wei*.
	 */
	function stakeVotingTokens(uint256 _numTokens) external {
		require(token.balanceOf(msg.sender) >= _numTokens, "User does not have enough tokens.");
		uint256 initialBalance = token.balanceOf(address(this));
		require(token.transferFrom(msg.sender, address(this), _numTokens), "User did not approve token transfer.");
		uint256 finalBalance = token.balanceOf(address(this));
		uint256 tokensReceived = finalBalance - initialBalance;
		bank[msg.sender].tokenBalance += tokensReceived;
		require(bank[msg.sender].tokenBalance <= limit, "User has exceeded the limit of tokens staked.");
	}

	/*
	 * Allows a voter to withdraw voting tokens after a poll has ended.
	 * NOTE: _numTokens is denominated in *wei*.
	 */
	function withdrawTokens(uint256 _numTokens) external {
		uint256 largest = getLockedAmount(msg.sender);
		require(getTokenStake(msg.sender) - largest >= _numTokens, "User is trying to withdraw too many tokens.");
		bank[msg.sender].tokenBalance -= _numTokens;
		require(token.transfer(msg.sender, _numTokens));
	}

	/*
	 * Allows a voter to withdraw all tokens that aren't locked.
	 */
	function withdrawAllTokens() external {
		uint256 largest = getLockedAmount(msg.sender);
		uint numTokens = getTokenStake(msg.sender) - largest;
		bank[msg.sender].tokenBalance -= numTokens;
		require(token.transfer(msg.sender, numTokens));
	}

	/*
	 * Helper function that updates active token balances after a poll has ended.
	 */
	function updateTokenBank(uint256 _pollID, bool _resetBalance) internal {
		Poll storage curPoll = polls[_pollID];
		for (uint256 i = 0; i < curPoll.voters.length; i++) {
			address voter = curPoll.voters[i];
			bank[voter].lockedTokens[_pollID] = 0;

			if (_resetBalance) {
				bank[voter].tokenBalance = 0;
			}
		}
	}

	/* BOUNTIES */

 	function getPseudoRandomNumber(uint256 _pollID) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, polls[_pollID].voters))) % polls[_pollID].voters.length;       
    }

	function assignBounty(uint256 _pollID, uint256 _numTokens) internal {
		bounties[_pollID] = _numTokens;
		emit bountyAssigned(_pollID, _numTokens);
	}

	function giveBounty(uint256 _pollID) internal {
		uint256 bountyTokens = bounties[_pollID];

		Poll storage curPoll = polls[_pollID];

		if (curPoll.mechanism == BountyMechanism.LOTTERY) {
			address winnerVoter = curPoll.voters[getPseudoRandomNumber(_pollID)];
			curPoll.winner = winnerVoter;
			bank[winnerVoter].tokenBalance += bountyTokens;
			bank[winnerVoter].bountyTokens[_pollID] = bountyTokens;
		} else {
			uint256 pollTokens = 0;

			for (uint256 i = 0; i < curPoll.optionVotes.length; i++) {
				pollTokens += curPoll.optionVotes[i];
			}

			for (uint256 i = 0; i < curPoll.voters.length; i++) {
				address voter = curPoll.voters[i];
				uint256 voterTokens = (bountyTokens * curPoll.voterInfo[voter].weight) / pollTokens;
				bank[voter].tokenBalance += voterTokens;
				bank[voter].bountyTokens[_pollID] = voterTokens;
			}
		}

		emit bountyGiven(_pollID);
	}

	/* RESCUE */

	/*
	 * Reset token bank for a given poll manually in case tokens have to be rescued
	 */

	function resetTokenBank(uint256 _pollID) external onlyOwner {
		updateTokenBank(_pollID, true);
	}

	/*
	 * Send any token from the contract balance to an address
	 */

    function rescueToken(address _token, address _to) external onlyOwner {
        IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
    }
}
