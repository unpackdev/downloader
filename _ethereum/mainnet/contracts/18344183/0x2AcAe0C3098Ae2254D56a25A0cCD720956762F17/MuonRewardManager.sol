// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./IBondedToken.sol";
import "./IToken.sol";

contract MuonRewardManager is Ownable{
    using ECDSA for bytes32;

    struct User {
        uint256 rewardAmount;
        uint256 tokenId;
    }


    uint256 public totalReward;

    IToken public muonToken;
    IBondedToken public bondedToken;

    mapping(address => User) public users;

    address public signer;

    // ======== Events ========
    event RewardClaimed(
        address indexed claimer,
        uint256 rewardAmount,
        uint256 indexed tokenId
    );

    constructor(
        address _muonTokenAddress,
        address _bondedTokenAddress,
        address _signer
    ) {
        muonToken = IToken(_muonTokenAddress);
        bondedToken = IBondedToken(_bondedTokenAddress);
        signer = _signer;
    }

    function claimReward(uint256 rewardAmount, bytes memory signature)
        external
        returns (uint256)
    {
        require(
            users[msg.sender].tokenId == 0 && 
            users[msg.sender].rewardAmount == 0, "Already claimed the reward.");

        bytes32 messageHash = keccak256(
            abi.encodePacked(msg.sender, rewardAmount)
        );
        address txSigner = messageHash.recover(signature);
        require(txSigner == signer, "Invalid signature.");

        require(
            muonToken.approve(address(bondedToken), rewardAmount),
            "Failed to approve to the bondedToken contract."
        );

        address[] memory tokens = new address[](1);
        tokens[0] = address(muonToken);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = rewardAmount;

        users[msg.sender].rewardAmount = rewardAmount;
        totalReward += rewardAmount;

        muonToken.mint(address(this), rewardAmount);
        uint256 tokenId = bondedToken.mintAndLock(tokens, amounts, msg.sender);

        users[msg.sender].tokenId = tokenId;
        emit RewardClaimed(msg.sender, rewardAmount, tokenId);

        return tokenId;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function withdraw(
        address tokenAddress,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(to != address(0));

        if (tokenAddress == address(0)) {
            payable(to).transfer(amount);
        } else {
            IToken(tokenAddress).transfer(to, amount);
        }
    }
}
