// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./Initializable.sol";
import "./INFTGemMultiToken.sol";
import "./INFTGemGovernor.sol";
import "./INFTGemPool.sol";
import "./IERC1155.sol";
import "./IProposal.sol";
import "./IProposalFactory.sol";
import "./ERC1155Holder.sol";
import "./SafeMath.sol";

contract Proposal is Initializable, ERC1155Holder, IProposal {
    using SafeMath for uint256;

    uint256 private constant MONTH = 2592000;
    uint256 private constant PROPOSAL_COST = 1 ether;

    string private _title;
    address private _creator;
    address private _funder;
    address private _multitoken;
    address private _governor;
    uint256 private _expiration;

    address private _proposalData;
    ProposalType private _proposalType;

    bool private _funded;
    bool private _executed;
    bool private _closed;

    constructor() {}

    function initialize(
        address __creator,
        string memory __title,
        address __proposalData,
        ProposalType __proposalType
    ) external override initializer {
        _title = __title;
        _creator = __creator;
        _proposalData = __proposalData;
        _proposalType = __proposalType;
    }

    function setMultiToken(address token) external override {
        require(_multitoken == address(0), "IMMUTABLE");
        _multitoken = token;
    }

    function setGovernor(address gov) external override {
        require(_governor == address(0), "IMMUTABLE");
        _governor = gov;
    }

    function title() external view override returns (string memory) {
        return _title;
    }

    function creator() external view override returns (address) {
        return _creator;
    }

    function funder() external view override returns (address) {
        return _creator;
    }

    function expiration() external view override returns (uint256) {
        return _expiration;
    }

    function _status() internal view returns (ProposalStatus curCtatus) {
        curCtatus = ProposalStatus.ACTIVE;
        if (!_funded) {
            curCtatus = ProposalStatus.NOT_FUNDED;
        } else if (_executed) {
            curCtatus = ProposalStatus.EXECUTED;
        } else if (_closed) {
            curCtatus = ProposalStatus.CLOSED;
        } else {
            uint256 totalVotesSupply = INFTGemMultiToken(_multitoken).totalBalances(uint256(address(this)));
            uint256 totalVotesInFavor = IERC1155(_multitoken).balanceOf(address(this), uint256(address(this)));
            uint256 votesToPass = totalVotesSupply.div(2).add(1);
            curCtatus = totalVotesInFavor >= votesToPass ? ProposalStatus.PASSED : ProposalStatus.ACTIVE;
            if (block.timestamp > _expiration) {
                curCtatus = totalVotesInFavor >= votesToPass ? ProposalStatus.PASSED : ProposalStatus.FAILED;
            }
        }

    }

    function status() external view override returns (ProposalStatus curCtatus) {
        curCtatus = _status();
    }

    function proposalData() external view override returns (address) {
        return _proposalData;
    }

    function proposalType() external view override returns (ProposalType) {
        return _proposalType;
    }

    function fund() external payable override {
        // ensure we cannot fund while in an invalida state
        require(!_funded, "ALREADY_FUNDED");
        require(!_closed, "ALREADY_CLOSED");
        require(!_executed, "ALREADY_EXECUTED");
        require(msg.value >= PROPOSAL_COST, "MISSING_FEE");

        // proposal is now funded and clock starts ticking
        _funded = true;
        _expiration = block.timestamp + MONTH;
        _funder = msg.sender;

        // create the vote tokens that will be used to vote on the proposal.
        INFTGemGovernor(_governor).createProposalVoteTokens(uint256(address(this)));

        // check for overpayment and if found then return remainder to user
        uint256 overpayAmount = msg.value.sub(PROPOSAL_COST);
        if (overpayAmount > 0) {
            (bool success, ) = payable(msg.sender).call{value: overpayAmount}("");
            require(success, "REFUND_FAILED");
        }
    }

    function execute() external override {
        // ensure we are funded and open and not executed
        require(_funded, "NOT_FUNDED");
        require(!_closed, "IS_CLOSED");
        require(!_executed, "IS_EXECUTED");
        require(_status() == ProposalStatus.PASSED, "IS_FAILED");

        // create the vote tokens that will be used to vote on the proposal.
        INFTGemGovernor(_governor).executeProposal(address(this));

        // this proposal is now executed
        _executed = true;

        // dewstroy the now-useless vote tokens used to vote for this proposal
        INFTGemGovernor(_governor).destroyProposalVoteTokens(uint256(address(this)));

        // refurn the filing fee to the funder of the proposal
        (bool success, ) = _funder.call{value: PROPOSAL_COST}("");
        require(success, "EXECUTE_FAILED");
    }

    function close() external override {
        // ensure we are funded and open and not executed
        require(_funded, "NOT_FUNDED");
        require(!_closed, "IS_CLOSED");
        require(!_executed, "IS_EXECUTED");
        require(block.timestamp > _expiration, "IS_ACTIVE");
        require(_status() == ProposalStatus.FAILED, "IS_PASSED");

        // this proposal is now closed - no action was taken
        _closed = true;

        // destroy the now-useless vote tokens used to vote for this proposal
        INFTGemGovernor(_governor).destroyProposalVoteTokens(uint256(address(this)));

        // send the proposal funder their filing fee back
        (bool success, ) = _funder.call{value: PROPOSAL_COST}("");
        require(success, "EXECUTE_FAILED");
    }
}
