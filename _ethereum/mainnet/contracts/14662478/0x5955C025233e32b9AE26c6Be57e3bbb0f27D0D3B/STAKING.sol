// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./EnumerableSet.sol";
import "./IERC721Receiver.sol";


interface ERC20Token {
    function mint(address to, uint256 amount) external;
}

contract RoboHiroStake is Ownable {

    using EnumerableSet for EnumerableSet.UintSet;

    ERC721A public STAKED_TOKEN;
    ERC20Token public MINT_TOKEN;
    uint256 private RATE;

    mapping(address => EnumerableSet.UintSet) private _stakes;
    mapping(address => mapping(uint256 => uint256)) public stakeBlocks;
    uint256 public totalStakes;

    constructor(ERC721A _nft_contract_to_stake, address _nft_contract_to_mint, uint256 rate){
        STAKED_TOKEN = ERC721A(_nft_contract_to_stake);
        MINT_TOKEN = ERC20Token(_nft_contract_to_mint);
        RATE = rate;
    }

    function setRate(uint256 _rate) public onlyOwner() {
        RATE = _rate;
    }

    function stakesOf(address account) external view returns (uint256[] memory) {
        EnumerableSet.UintSet storage stakeSet = _stakes[account];
        uint256[] memory tokenIds = new uint256[](stakeSet.length());

        for (uint256 i; i < stakeSet.length(); i++) {
            tokenIds[i] = stakeSet.at(i);
        }

        return tokenIds;
    }

    function calculateRewards(address account, uint256[] memory tokenIds) public view returns (uint256[] memory rewards) {
        rewards = new uint256[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            rewards[i] = RATE * (_stakes[account].contains(tokenId) ? 1 : 0) * ((block.timestamp - stakeBlocks[account][tokenId]) / 60 / 60 / 24 );
        }
        return rewards;
    }

    function getTotalStaked() public view returns (uint256) {
        return totalStakes;
    }

    function claimRewards(uint256[] calldata tokenIds) public {
        uint256 reward;
        uint256 _block = block.timestamp;

        uint256[] memory rewards = calculateRewards(msg.sender, tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            reward += rewards[i];
            stakeBlocks[msg.sender][tokenIds[i]] = _block;
        }

        if (reward > 0) {
            MINT_TOKEN.mint(msg.sender, reward);
        }
    }

    function stake(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);
        for (uint256 i; i < tokenIds.length; i++) {
            STAKED_TOKEN.transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
            _stakes[msg.sender].add(tokenIds[i]);
            totalStakes += 1;
        }
    }

    function withdraw(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);
        for (uint256 i; i < tokenIds.length; i++) {
            require( _stakes[msg.sender].contains(tokenIds[i]), 'CONTRACT ERROR: either token has not been staked or it has been staked by another user' );
            _stakes[msg.sender].remove(tokenIds[i]);
            STAKED_TOKEN.transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
            totalStakes -= 1;
        }
    }
}