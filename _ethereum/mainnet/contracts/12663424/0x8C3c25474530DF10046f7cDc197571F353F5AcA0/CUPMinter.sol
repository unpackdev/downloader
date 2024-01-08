// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Approvable.sol";



interface IERC20Short {
    function burnFrom(address account, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}


contract CUPMinter is Approvable {
    using SafeMath for uint256;

    address private _cup;
    mapping(address => bool) private _tokens;

    struct Proposal {
        uint256 id;
        bool applied;
        address token;
        uint256 approvalsWeight;
    }
    Proposal[] private _proposals;
    mapping(address => mapping(uint256 => bool)) private _approvalsProposal;

    event NewProposal(uint256 indexed id, address indexed token);
    event VoteForProposal(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event ProposalApplied(uint256 indexed id, address indexed token);


    constructor(uint256 weight, uint256 threshold) public {
        _setupApprover(_msgSender(), weight);
        _setupThreshold(threshold);
    }

    function convert(address token, uint256 amount) public {
        require(_tokens[token], "This token is not allowed to convert");
        address msgSender = _msgSender();
        IERC20Short(token).burnFrom(msgSender, amount);
        IERC20Short(cup()).mint(msgSender, amount);
    }

    function cup() public view returns (address) {
        return _cup;
    }

    function setCup(address token) public onlyApprover {
        require(token != address(0), "New CUP address is the zero address");
        require(cup() == address(0), "The CUP address is already setted");
        _cup = token;
    }

    function proposalsCount() public view returns (uint256) {
        return _proposals.length;
    }

    function getProposal(uint256 id) public view returns (Proposal memory) {
        return _proposals[id];
    }

    function addProposal(address token) public onlyApprover returns (uint256) {
        uint256 id = _addNewProposal(token);
        _voteForProposal(id);
        return id;
    }

    function approveProposal(uint256 id) public onlyApprover {
        require(_proposals[id].applied == false, "Proposal has already applied");
        require(_approvalsProposal[_msgSender()][id] == false, "Cannot approve transfer twice");
        _voteForProposal(id);
    }


    function _addNewProposal(address token) private returns (uint256) {
        require(token != address(0), "Token is the zero address");
        uint256 id = _proposals.length;
        _proposals.push(Proposal(id, false, token, 0));
        emit NewProposal(id, token);
        return id;
    }

    function _voteForProposal(uint256 id) private {
        address msgSender = _msgSender();
        _approvalsProposal[msgSender][id] = true;
        uint256 approverWeight = getApproverWeight(msgSender);
        _proposals[id].approvalsWeight = _proposals[id].approvalsWeight.add(approverWeight);
        emit VoteForProposal(id, msgSender, approverWeight, _proposals[id].approvalsWeight);
        if (_proposals[id].approvalsWeight >= getThreshold())
            _applyProposal(id);
    }

    function _applyProposal(uint256 id) private {
        _tokens[_proposals[id].token] = true;
        _proposals[id].applied = true;
        emit ProposalApplied(id, _proposals[id].token);
    }
}
