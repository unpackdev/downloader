//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./ERC20.sol";
import "./EnumerableSet.sol";

//@title Staking Rarity
contract RoboStaking is ERC20 {
    using EnumerableSet for EnumerableSet.UintSet;
    
    //@notice ERC721 Info
    struct RoboStaked {
        uint32 lastClaimBlock;
        uint256 reward;
    }

    //@notice Enumerable Set for Token Ids Staked By User
    mapping(address => EnumerableSet.UintSet) private depositsByUser;

    //@notice Address to their staked NFTs
    mapping (uint256 => RoboStaked) public tokenStaked;

    //@notice user to nft rewards
    mapping (address => uint256) public pendingRewards;

    //@notice ERC721 Token to use
    IERC721 immutable public stakingToken;

    //@notice ETH Average Block Time (After merge its done) 
    uint256 constant BLOCKS_IN_DAY = 6000;

    //@notice Supply for ROBO
    uint256 constant MAX_SUPPLY = 777_777_777 * 10 ** 18;

    //@notice Emitted when a user stakes
    event Staked(
        uint16[] tokenIds
    );

    //@notice Emitted when a user unstakes
    event Unstaked(
        uint16[] tokenIds
    );

    //@notice Emitted when claiming rewards
    event ClaimTokens(
        uint256 claimAmount
    );

    modifier updateUserRewards (address user) {
        EnumerableSet.UintSet storage usersStaked = depositsByUser[user];
        uint256 rewards;
        for(uint256 i = 0; i < usersStaked.length(); i++) {
                uint256 currentToken = usersStaked.at(i);
                RoboStaked memory currentStaked = tokenStaked[currentToken];
                tokenStaked[currentToken].lastClaimBlock = uint32(block.number);  
                pendingRewards[user] += (block.number - currentStaked.lastClaimBlock) * (currentStaked.reward) / BLOCKS_IN_DAY;           
        }
        _;
    }

    constructor(uint256[777] memory _rewards, address _stakingToken, address team) ERC20("Robofrens", "ROBO") {
        stakingToken = IERC721(_stakingToken);
        _mint(team, 544_444_444 * 10 ** 18);
        for(uint256 i = 0; i < _rewards.length; i++) {
            tokenStaked[i].reward = _rewards[i] * 10 ** 18;
        }
    }

    //@notice Allows users to stake their nfts
    //@param tokenIds, pass the token ids you own to stake
    function stake(uint16[] calldata tokenIds) external updateUserRewards(msg.sender) {
        unchecked {
            for(uint256 i = 0; i < tokenIds.length; i++) {
                uint256 currentId = tokenIds[i];
                require(stakingToken.ownerOf(currentId) == msg.sender);
                tokenStaked[currentId].lastClaimBlock = uint32(block.number);
                depositsByUser[msg.sender].add(currentId);
                stakingToken.transferFrom(msg.sender, address(this), currentId);
            }       
        }
    }

    //@notice Allows users to unstake their nfts
    //@param tokenIds, pass token ids you want to unstake
    function unstake(uint16[] calldata tokenIds) external updateUserRewards(msg.sender) {
        unchecked {
            for(uint256 i = 0; i < tokenIds.length; i++) {
                uint256 currentId = tokenIds[i];
                require(depositsByUser[msg.sender].contains(currentId));
                tokenStaked[currentId].lastClaimBlock = 0;
                depositsByUser[msg.sender].remove(currentId);
                stakingToken.transferFrom(address(this), msg.sender, currentId);
            }
        }
        emit Unstaked(tokenIds);
    }

    //@notice Claim Rewards 
    function claimRewards() external updateUserRewards(msg.sender) {
        uint256 userClaim = pendingRewards[msg.sender];
        require(MAX_SUPPLY >= totalSupply() + userClaim, "STAKING_END");
        require(userClaim > 0, "NO_REWARDS");
        pendingRewards[msg.sender] = 0;
        _mint(msg.sender, userClaim);
        emit ClaimTokens(userClaim);
    }

    //@notice Get staked amount of nfts
    //@param user to lookup 
    function getStakedCount(address user) public view returns (uint256) {
        return depositsByUser[user].length();
    }

    //@notice Get rewards for users staked assets
    //@param user to lookup
    function getEarned(address user) public view returns (uint256) {
       EnumerableSet.UintSet storage usersStaked = depositsByUser[user];
        uint256 rewards;
        for(uint256 i = 0; i < usersStaked.length(); i++) {
                uint256 currentToken = usersStaked.at(i);
                RoboStaked memory currentStaked = tokenStaked[currentToken];
                rewards += (block.number - currentStaked.lastClaimBlock) * (currentStaked.reward) / BLOCKS_IN_DAY;
        }
        return pendingRewards[user] + rewards;
    }

    //@notice Get user staked ids
    //@param user to lookup 
    function getStaked(address user) public view returns (uint256[] memory) {
        uint256[] memory usersStaked = depositsByUser[user].values();
        uint256[] memory staked = new uint256[](usersStaked.length);
        for(uint256 i = 0; i < usersStaked.length; i++) {
                staked[i] = usersStaked[i];
        }
        return staked;
    }
    
}
