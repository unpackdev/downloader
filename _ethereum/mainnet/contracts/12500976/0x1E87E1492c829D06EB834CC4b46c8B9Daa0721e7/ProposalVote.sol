// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./Structs.sol";

contract ProposalVote {
    using SafeMath for uint256;

    mapping(bytes32 => Proposal) public proposalOf;

    mapping(address => uint256) public threshold;

    event ProposalVoted(
        address token,
        address from,
        address to,
        uint256 amount,
        address proposer,
        uint256 count,
        uint256 threshold
    );

    event ThresholdChanged(address token, uint256 oldThreshold, uint256 newThreshold);

    function _setThreshold(address token, uint256 _threshold) internal virtual {
        uint256 oldThreshold = threshold[token];
        threshold[token] = _threshold;
        emit ThresholdChanged(token, oldThreshold, _threshold);
    }

    function _vote(
        address tokenTo,
        address from,
        address to,
        uint256 amount,
        string memory txid
    ) internal virtual returns (bool result) {
        require(threshold[tokenTo] > 0, "ProposalVote: threshold should be greater than 0");
        uint256 count = threshold[tokenTo];
        bytes32 mid = keccak256(abi.encodePacked(tokenTo, from, to, amount, txid));
        Proposal storage p = proposalOf[mid];
        if (proposalOf[mid].isExist == false) {
            // create proposal
            p.tokenTo = tokenTo;
            p.from = from;
            p.to = to;
            p.amount = amount;
            p.count = 1;
            p.txid = txid;
            p.isExist = true;
            p.isVoted[msg.sender] = true;
        } else {
            require(p.isFinished == false, "_vote::proposal finished");
            require(p.isVoted[msg.sender] == false, "_vote::msg.sender voted");
            p.count = p.count.add(1);
            p.isVoted[msg.sender] = true;
        }
        if (p.count >= count) {
            p.isFinished = true;
            result = true;
        }
        emit ProposalVoted(tokenTo, from, to, amount, msg.sender, p.count, count);
    }
}
