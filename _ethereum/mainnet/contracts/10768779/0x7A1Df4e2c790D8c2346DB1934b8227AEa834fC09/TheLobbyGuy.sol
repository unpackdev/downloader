/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.7.0;


library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);
        return c;
    }

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }
        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO);
        uint256 c = _a / _b;
        return c;
    }
}

interface ERC20 {
    function balanceOf(address _to) external view returns (uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
}

interface MiniMeToken {
    function balanceOfAt(address _holder, uint256 _blockNumber) external view returns (uint256);
}

interface Voting {
    enum VoterState { Absent, Yea, Nay }
    enum VoteStatus { Active, Paused, Cancelled, Executed }

    function token() external view returns (MiniMeToken);
    function getCastVote(uint256 _voteId, address _voter) external view returns (VoterState state, address caster);
    function getVote(uint256 _voteId) external view returns (uint256, uint256, uint256, uint256, uint256, VoteStatus, uint64, uint64, uint64, uint64, uint64, VoterState, bytes calldata);
}

contract TheLobbyGuy {
    using SafeMath for uint256;

    uint256 public constant FUNDS_WITHDRAW_WINDOW = 60 * 60 * 24 * 365; // 1 year

    string private constant ERROR_SENDER_NOT_OWNER = "TLG_SENDER_NOT_OWNER";
    string private constant ERROR_CANNOT_RECOVER_FUNDS = "TLG_CANNOT_RECOVER_FUNDS";
    string private constant ERROR_VOTE_WAS_NOT_EXECUTED = "TLG_VOTE_WAS_NOT_EXECUTED";
    string private constant ERROR_VOTER_DID_NOT_SUPPORT = "TLG_VOTER_DID_NOT_SUPPORT";
    string private constant ERROR_TOKEN_TRANSFER_FAILED = "TLG_TOKEN_TRANSFER_FAILED";
    string private constant ERROR_NO_BALANCE_TO_DISTRIBUTE = "TLG_NO_BALANCE_TO_DISTRIBUTE";
    string private constant ERROR_VOTER_HAS_ALREADY_CLAIMED = "TLG_VOTER_HAS_ALREADY_CLAIMED";
    string private constant ERROR_CONTRACT_ALREADY_INITIALIZED = "TLG_CONTRACT_ALREADY_INITIALIZED";

    address public owner;
    uint256 public withdrawsEndDate;

    Voting public voting;
    uint256 public voteId;
    mapping (address => bool) hasClaimed;

    event ShareClaimed(address indexed sender, ERC20 token, uint256 amount);
    event FundsRecovered(address indexed sender, ERC20 token, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function initialize(Voting _voting, uint256 _voteId) external {
        require(msg.sender == owner, ERROR_SENDER_NOT_OWNER);
        require(voting == Voting(0), ERROR_CONTRACT_ALREADY_INITIALIZED);

        voting = _voting;
        voteId = _voteId;
    }

    function recover(ERC20 _token) external {
        require(msg.sender == owner, ERROR_SENDER_NOT_OWNER);
        require(withdrawsEndDate != 0 && block.timestamp >= withdrawsEndDate, ERROR_CANNOT_RECOVER_FUNDS);

        uint256 balance = _token.balanceOf(address(this));
        require(_token.transfer(msg.sender, balance), ERROR_TOKEN_TRANSFER_FAILED);
        emit FundsRecovered(msg.sender, _token, balance);
    }

    function withdraw(ERC20 _token) external {
        require(!hasClaimed[msg.sender], ERROR_VOTER_HAS_ALREADY_CLAIMED);

        (uint256 yeas,,,,, Voting.VoteStatus status,, uint64 snapshotBlock,,,,,) = voting.getVote(voteId);
        require(status == Voting.VoteStatus.Executed, ERROR_VOTE_WAS_NOT_EXECUTED);

        uint256 currentBalance = _token.balanceOf(address(this));
        require(currentBalance > 0, ERROR_NO_BALANCE_TO_DISTRIBUTE);

        (Voting.VoterState state,) = voting.getCastVote(voteId, msg.sender);
        require(state == Voting.VoterState.Yea, ERROR_VOTER_DID_NOT_SUPPORT);

        MiniMeToken votingToken = voting.token();
        uint256 voterStake = votingToken.balanceOfAt(msg.sender, snapshotBlock);

        uint256 share = voterStake.mul(currentBalance).div(yeas);
        require(_token.transfer(msg.sender, share), ERROR_TOKEN_TRANSFER_FAILED);

        hasClaimed[msg.sender] = true;
        emit ShareClaimed(msg.sender, _token, share);

        if (withdrawsEndDate == 0) {
            withdrawsEndDate = block.timestamp.add(FUNDS_WITHDRAW_WINDOW);
        }
    }
}
