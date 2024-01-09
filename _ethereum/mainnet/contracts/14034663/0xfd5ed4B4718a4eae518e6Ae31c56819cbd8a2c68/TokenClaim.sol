// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract TokenClaim is Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    bool public disabled;
    bytes32 public tokenClaimMerkleRoot;
    IERC20 public token;
    uint256 public startTime;
    uint256 public endTime;
    mapping(address => bool) public claimed;

    /* ========== CONSTRUCTOR ========== */

    constructor(IERC20 _token, bytes32 _claimMerkleRoot, uint256 _startTime, uint256 _endTime) {
        require(block.timestamp < _startTime, "startTime should be larger than contract deployed time");
        require(_startTime < _endTime, "endTime should be larger than startTime");
        token = _token;
        tokenClaimMerkleRoot = _claimMerkleRoot;
        startTime = _startTime;
        endTime = _endTime;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setDisabled(bool _disabled) external onlyOwner {
        disabled = _disabled;
    }

    function withdraw(IERC20 _token) external onlyOwner {
        if (_token == token) {
            require(block.timestamp < startTime || endTime < block.timestamp, "cannot withdraw reward token when claim activated");
        }
        uint256 _tokenBalance = _token.balanceOf(address(this));
        _token.safeTransfer(msg.sender, _tokenBalance);
    }

    /* ========== WRITE FUNCTIONS ========== */

    function claim(bytes32[] memory proof, uint256 amount)
        external
        nonReentrant
    {
        require(!disabled, "the contract is disabled");
        require(block.timestamp > startTime, "claim has not started");
        require(block.timestamp < endTime, "claim has finished");
        require(!claimed[msg.sender], "this address has already claimed");
        require(
            proof.verify(
                tokenClaimMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, amount))
            ),
            "failed to verify merkle proof"
        );

        claimed[msg.sender] = true;
        token.safeTransfer(msg.sender, amount);
        emit TokenClaimed(msg.sender, amount);
    }

    /* ========== EVENTS ========== */

    event TokenClaimed(address _address, uint256 _amount);
}
