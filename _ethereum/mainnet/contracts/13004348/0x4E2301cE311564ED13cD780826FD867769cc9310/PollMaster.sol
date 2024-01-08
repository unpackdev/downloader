//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./console.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

struct Vote {
  uint256 amount;
  uint256 answer;

  bool claimed;
}

struct Poll {
  // Poll Data
  string question;
  string[] choices;
  uint256 choiceCount;
  uint256 answer; // initialize to -1

  // Stats
  mapping(address => Vote) votes;
  uint256 totalStaked;
  mapping(uint256 => uint256) stakedForChoice;
}
  
contract PollMaster is Ownable{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  mapping(uint256 => Poll) public polls;
  uint256 public pollCount;

  IERC20 public immutable token;

  constructor(address _token) {
    token = IERC20(_token);
  }

  function createPoll(string memory question, string[] memory choices_) external onlyOwner {
    Poll storage poll = polls[pollCount];
    pollCount ++;
    
    poll.choices = choices_;
  
    poll.choiceCount = choices_.length;
    poll.answer = type(uint256).max;
    poll.question = question;
  }

  function choices(uint256 pollId) external view returns(string[] memory) {
    return polls[pollId].choices;
  }

  function finalizePoll(uint256 pollId, uint256 answerId) external onlyOwner {
    Poll storage poll = polls[pollId];
    require(!isFinalized(pollId), "already finalized");
    require(answerId < poll.choiceCount, "invalid answer");

    poll.answer = answerId;
  }

  function submit(uint256 pollId, uint256 choiceId, uint256 tokenAmount) external {
    Poll storage poll = polls[pollId];

    require(!isFinalized(pollId), "already finalized");
    require(choiceId < poll.choiceCount, "invalid answer");

    // clear previous vote
    poll.stakedForChoice[choiceId] = poll.stakedForChoice[poll.votes[msg.sender].answer].sub(poll.votes[msg.sender].amount);

    poll.votes[msg.sender].amount = poll.votes[msg.sender].amount.add(tokenAmount);
    poll.votes[msg.sender].answer = choiceId;
    
    poll.totalStaked = poll.totalStaked.add(tokenAmount);
    poll.stakedForChoice[choiceId] = poll.stakedForChoice[choiceId].add(poll.votes[msg.sender].amount);

    token.safeTransferFrom(msg.sender, address(this), tokenAmount);
  }

  function claim(uint256 pollId) external {
    Poll storage poll = polls[pollId];
    Vote storage vote = polls[pollId].votes[msg.sender];
    
    require(isFinalized(pollId), "not finalized");
    require(vote.answer == poll.answer, "incorrect answer");
    require(vote.amount > 0, "no stake");
    require(!vote.claimed, "already claimed");

    vote.claimed = true;

    uint256 rewardAmount = poll.totalStaked.mul(vote.amount).div(poll.stakedForChoice[vote.answer]);
    token.safeTransfer(msg.sender, rewardAmount);
  }

  function isFinalized(uint256 pollId) public view returns (bool){
    return polls[pollId].answer != type(uint256).max;
  }
}
