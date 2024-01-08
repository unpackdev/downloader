// contracts/MonsterDough.sol
// SPDX-License-Identifier: MIT
// Forked from Cheeth. <3
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";

contract MonsterDough is ERC20Burnable, Ownable {
    using SafeMath for uint256;

    uint256 public MAX_WALLET_STAKED = 10;
    uint256 public EMISSIONS_RATE = 11574070000000;
    uint256 public CLAIM_END_TIME = 1643673600;

    address nullAddress = 0x0000000000000000000000000000000000000000;

    address public monstersAddress;

    mapping(uint256 => uint256) internal tokenIdToTimeStamp;
    mapping(uint256 => address) internal tokenIdToStaker;
    mapping(address => uint256[]) internal stakerToTokenIds;

    constructor() ERC20("MonsterDough", "OCMD") {}

    function setMonstersAddress(address a) public onlyOwner {
        monstersAddress = a;
    }

    function getTokensStaked(address staker) public view returns (uint256[] memory) {
        return stakerToTokenIds[staker];
    }

    function removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {

                for (uint256 j = i; j < stakerToTokenIds[staker].length - 1; j++) {
                    stakerToTokenIds[staker][j] = stakerToTokenIds[staker][j + 1];
                }
                stakerToTokenIds[staker].pop();

                return;
            }
        }
    }

    function stakeByIds(uint256[] memory tokenIds) public {
        require(
            stakerToTokenIds[msg.sender].length + tokenIds.length <=
                MAX_WALLET_STAKED,
            "You can not stake more than 10 monsters."
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(monstersAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == nullAddress,
                "You can't stake this monster."
            );

            IERC721(monstersAddress).transferFrom(msg.sender, address(this), tokenIds[i]);

            stakerToTokenIds[msg.sender].push(tokenIds[i]);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = msg.sender;
        }
    }

    function unstakeAll() public {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "You don't have any monsters staked."
        );

        uint256 reward = 0;

        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

            IERC721(monstersAddress).transferFrom(address(this), msg.sender, tokenId);

            reward += (block.timestamp - tokenIdToTimeStamp[tokenId]) *
                    EMISSIONS_RATE;

            removeTokenIdFromStaker(msg.sender, tokenId);

            tokenIdToStaker[tokenId] = nullAddress;
        }

        _mint(msg.sender, reward);
    }

    function unstakeByIds(uint256[] memory tokenIds) public {
        uint256 reward = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "You are not the staker of this monster!"
            );

            IERC721(monstersAddress).transferFrom(address(this), msg.sender, tokenIds[i]);

            reward += (block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE;

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            tokenIdToStaker[tokenIds[i]] = nullAddress;
        }

        _mint(msg.sender, reward);
    }

    function claimByTokenId(uint256 tokenId) public {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "You are not the staker of this monster!"
        );
        require(block.timestamp < CLAIM_END_TIME, "Claim period is over!");

        _mint(
            msg.sender,
            ((block.timestamp - tokenIdToTimeStamp[tokenId]) * EMISSIONS_RATE)
        );

        tokenIdToTimeStamp[tokenId] = block.timestamp;
    }

    function claimAll() public {
        require(block.timestamp < CLAIM_END_TIME, "Claim period is over!");
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        
        uint256 reward = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Token is not claimable by you!"
            );

            reward += ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        _mint(msg.sender, reward);
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];

        uint256 reward = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            reward += ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);
        }

        return reward;
    }

    function getRewardsByTokenId(uint256 tokenId) public view returns (uint256) {
        require(tokenIdToStaker[tokenId] != nullAddress, "Monster is not staked!");

        return (block.timestamp - tokenIdToTimeStamp[tokenId]) * EMISSIONS_RATE;
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[tokenId];
    }
}