// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Ownable.sol";

enum PollType { PROPOSAL, EXECUTIVE, EVENT, PRIVATE }
enum VoteType { FOR, AGAINST }
enum PollStatus { PENDING, APPROVED, REJECTED, DRAW }

struct Poll {
    PollType pollType;
    uint64 pollDeadline;
    uint64 pollStopped;
    address pollOwner;
    string pollInfo;
    uint256 forWeight;
    uint256 againstWeight;
}

struct Vote {
    VoteType voteType;
    uint256 voteWeight;
}

contract GlydeFinanceGovernanceToken is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    // Poll-related state variables
    Poll[] public polls;
    mapping(uint256 => mapping(address => Vote)) public voted;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event PollCreated(uint256 pollNum);

    constructor(string memory name_, string memory symbol_, uint256 initialSupply) {
        _name = name_;
        _symbol = symbol_;
        _mint(_msgSender(), initialSupply);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Poll-related functions
    function createProposalPoll(uint64 _pollDeadline, string memory _pollInfo) external {
        _createPoll(PollType.PROPOSAL, _pollDeadline, _pollInfo);
    }

    function createExecutivePoll(uint64 _pollDeadline, string memory _pollInfo) external onlyOwner {
        _createPoll(PollType.EXECUTIVE, _pollDeadline, _pollInfo);
    }

    function createEventPoll(uint64 _pollDeadline, string memory _pollInfo) external onlyOwner {
        _createPoll(PollType.EVENT, _pollDeadline, _pollInfo);
    }

    function _createPoll(PollType _pollType, uint64 _pollDeadline, string memory _pollInfo) private returns (uint256) {
        require(_pollDeadline > block.timestamp, "Poll deadline should be in the future");

        Poll memory newPoll = Poll({
            pollType: _pollType,
            pollDeadline: _pollDeadline,
            pollStopped: _pollDeadline,
            pollOwner: msg.sender,
            pollInfo: _pollInfo,
            forWeight: 0,
            againstWeight: 0
        });

        polls.push(newPoll);
        uint256 pollNum = polls.length - 1;
        emit PollCreated(pollNum);

        return pollNum;
    }

function vote(uint256 pollNum, VoteType voteType, uint256 voteWeight) external {
    require(pollNum < polls.length, "Invalid poll number");
    require(!hasVoted[pollNum][_msgSender()], "Already voted");

    Poll storage poll = polls[pollNum];
    require(block.timestamp < poll.pollDeadline, "Poll is closed");

    voted[pollNum][_msgSender()] = Vote(voteType, voteWeight);
    hasVoted[pollNum][_msgSender()] = true;

    if (voteType == VoteType.FOR) {
        poll.forWeight += voteWeight;
    } else {
        poll.againstWeight += voteWeight;
    }
}

    function getPollStatus(uint256 pollNum) public view returns (PollStatus) {
        require(pollNum < polls.length, "Invalid poll number");

        Poll storage poll = polls[pollNum];
        if (block.timestamp < poll.pollDeadline) {
            return PollStatus.PENDING;
        }

        if (poll.forWeight > poll.againstWeight) {
            return PollStatus.APPROVED;
        } else if (poll.forWeight < poll.againstWeight) {
            return PollStatus.REJECTED;
        } else {
            return PollStatus.DRAW;
        }
    }

    function closePoll(uint256 pollNum) external onlyOwner {
        require(pollNum < polls.length, "Invalid poll number");

        Poll storage poll = polls[pollNum];
        require(block.timestamp < poll.pollDeadline, "Poll is already closed");

        poll.pollDeadline = uint64(block.timestamp);
    }
}
