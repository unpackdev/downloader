// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @custom:security-contact dennison@dennisonbertram.com

import "./IMetaPunk2018.sol";
import "./ReentrancyGuard.sol";

interface IDAOToken {
    function safeMint(address) external;
}

contract VoteDistributionController is ReentrancyGuard {
    IDAOToken public daoToken;
    IMetaPunk2018 public ppToken;

    mapping(uint256 => uint256) public tokenLastClaimDate;
    mapping(address => uint256) public addressLastClaimDate;

    event VoteClaimed(address recipient, uint256 amount);

    constructor(IDAOToken _daoToken, IMetaPunk2018 _ppToken){
        daoToken = _daoToken;
        ppToken = _ppToken;
    }

    function claim(uint256 _tokenId) public nonReentrant {
        // check the last time they claimed
        require(((block.timestamp - tokenLastClaimDate[_tokenId]) > 12 weeks), "err: must wait longer");
        require(((block.timestamp - addressLastClaimDate[msg.sender]) > 12 weeks), "err: must wait longer");

        // be sure they own the token they are claiming for
        require(ppToken.ownerOf(_tokenId) == msg.sender, "err: user does not own this token");

        // update the last time they claimed to now
        tokenLastClaimDate[_tokenId] = block.timestamp;
        addressLastClaimDate[msg.sender] = block.timestamp;

        // mint them a single vote token
        _distributeVote(msg.sender, 1);
    }

    function _distributeVote(address recipient, uint256 amount) internal {
        for (uint256 x = 0; x < amount; x++) {
            daoToken.safeMint(recipient);
        }
        emit VoteClaimed(recipient, amount);
    }
}
