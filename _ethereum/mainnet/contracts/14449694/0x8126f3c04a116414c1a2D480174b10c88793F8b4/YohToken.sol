// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";

contract YohToken is ERC20BurnableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public MAX_WALLET_STAKED;

    // 175 / 100 = 75%
    uint256 public MAX_MULTIPLIER;

    address nullAddress;
    address public yokaiAddress;
    address public yokaiOracle;

    //Mapping of yokai to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;
    //Mapping of yokai to staker
    mapping(uint256 => address) internal tokenIdToStaker;
    //Mapping of staker to yokai
    mapping(address => uint256[]) internal stakerToTokenIds;

    address public boostAddress;

    // Initializer function (replaces constructor)
    function initialize() public initializer {
        __ERC20_init("Yoh Token", "YOH");
        __ERC20Burnable_init();
        __Ownable_init();
        nullAddress = 0x0000000000000000000000000000000000000000;
        MAX_MULTIPLIER = 175;
        MAX_WALLET_STAKED = 100;
    }

    function setBoostAddress(address _boostAddress) public onlyOwner {
        boostAddress = _boostAddress;
    }

    function setYokaiAddress(address _yokaiAddress, address _yokaiOracle) public onlyOwner {
        yokaiAddress = _yokaiAddress;
        yokaiOracle = _yokaiOracle;
    }

    function setMaxWalletStaked(uint256 _max_stake) public onlyOwner {
        MAX_WALLET_STAKED = _max_stake;
    }

    function getTokensStaked(address staker) public view returns (uint256[] memory) {
        return stakerToTokenIds[staker];
    }

    function getBoostBalance(address staker) public view returns (uint256 boostAmount) {
        boostAmount = 0;
        if(boostAddress != address(0)){
          boostAmount = IBoost(boostAddress).balanceOf(staker, 1);
        }
    }

    function remove(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToTokenIds[staker].length - 1; i++) {
            stakerToTokenIds[staker][i] = stakerToTokenIds[staker][i + 1];
        }
        stakerToTokenIds[staker].pop();
    }

    function removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                remove(staker, i);
            }
        }
    }

    function stakeByIds(uint256[] memory tokenIds) public {
        require(stakerToTokenIds[msg.sender].length + tokenIds.length <= MAX_WALLET_STAKED,
            "You are staking too many!"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721EnumerableUpgradeable(yokaiAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == nullAddress,
                "Token must be stakable by you!"
            );

            IERC721EnumerableUpgradeable(yokaiAddress).transferFrom(msg.sender, address(this), tokenIds[i]);

            stakerToTokenIds[msg.sender].push(tokenIds[i]);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = msg.sender;
        }
    }

    function unstakeByIds(uint256[] memory tokenIds, bytes32[][] memory proof) public {
        uint256 totalRewards = 0;

        uint boostAmount = getBoostBalance(msg.sender);
        uint totalStakedAmount = stakerToTokenIds[msg.sender].length;


        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIdToStaker[tokenIds[i]] == msg.sender, "Message Sender was not original staker!");

            IERC721EnumerableUpgradeable(yokaiAddress).transferFrom(address(this), msg.sender, tokenIds[i]);

            totalRewards = totalRewards + getRewards(tokenIdToTimeStamp[tokenIds[i]], tokenIds[i], proof[i], totalStakedAmount, boostAmount);

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            tokenIdToStaker[tokenIds[i]] = nullAddress;
        }

        _mint(msg.sender, totalRewards);
    }

    function claimByTokenIds(uint256[] memory tokenIds, bytes32[][] memory proof) public {
        uint256 totalRewards = 0;
        uint boostAmount = getBoostBalance(msg.sender);
        uint totalStakedAmount = stakerToTokenIds[msg.sender].length;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIdToStaker[tokenIds[i]] == msg.sender, "Token is not claimable by you!");
            totalRewards = totalRewards + getRewards(tokenIdToTimeStamp[tokenIds[i]], tokenIds[i], proof[i], totalStakedAmount, boostAmount);
            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }


    function claimAll(bytes32[][] memory proof) public {
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;

        uint boostAmount = getBoostBalance(msg.sender);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIdToStaker[tokenIds[i]] == msg.sender, "Token is not claimable by you!");
            totalRewards = totalRewards + getRewards(tokenIdToTimeStamp[tokenIds[i]], tokenIds[i], proof[i], tokenIds.length, boostAmount);
            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }

    function getAllMultipliers(address staker, bytes32[][] memory proof) external view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        uint[] memory tokenIds = stakerToTokenIds[staker];
        IYokaiOracle oracle = IYokaiOracle(yokaiOracle);
        uint[] memory multiplier = new uint[](tokenIds.length);
        uint[] memory rarity = new uint[](tokenIds.length);
        uint[] memory rewards = new uint[](tokenIds.length);

        uint boostAmount = getBoostBalance(staker);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint delta_time = (block.timestamp - tokenIdToTimeStamp[tokenIds[i]]);
            multiplier[i] = getMultiplier(delta_time, tokenIds.length, boostAmount);

            if(oracle.isSpecialRarity(tokenIds[i], proof[i])){
              rarity[i] = 4;
            } else if(oracle.isMythicRarity(tokenIds[i], proof[i])){
              rarity[i] = 3;
            } else if(oracle.isLegendaryRarity(tokenIds[i], proof[i])){
              rarity[i] = 2;
            } else if(oracle.isRareRarity(tokenIds[i], proof[i])){
              rarity[i] = 1;
            } else {
              rarity[i] = 0;
            }

            rewards[i] = getRewards(tokenIdToTimeStamp[tokenIds[i]], tokenIds[i], proof[i], tokenIds.length, boostAmount);
        }

        return (tokenIds, multiplier, rarity, rewards);

    }

    function getAllRewards(address staker, bytes32[][] memory proof) external view returns (uint) {
        uint[] memory tokenIds = stakerToTokenIds[staker];
        uint rewards;

        uint boostAmount = getBoostBalance(staker);
        uint totalStakedAmount = stakerToTokenIds[staker].length;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            rewards += getRewards(tokenIdToTimeStamp[tokenIds[i]], tokenIds[i], proof[i], boostAmount, totalStakedAmount);
        }

        return rewards;
    }

    function getRewardsByTokenId(uint256 tokenId, bytes32[] memory proof) public view returns (uint256) {
        require(tokenIdToStaker[tokenId] != nullAddress, "Token is not staked!");

        uint boostAmount = getBoostBalance(tokenIdToStaker[tokenId]);
        uint totalStakedAmount = stakerToTokenIds[tokenIdToStaker[tokenId]].length;

        return getRewards(tokenIdToTimeStamp[tokenId], tokenId, proof, totalStakedAmount, boostAmount);
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[tokenId];
    }

    function getRewards(uint256 tokenTimestamp, uint tokenID, bytes32[] memory proof, uint totalStakedAmount, uint boostAmount) public view returns (uint256){
      IYokaiOracle oracle = IYokaiOracle(yokaiOracle);

      uint emission = 0;

      if(oracle.isSpecialRarity(tokenID, proof)){
        emission = 277e13;
      } else if(oracle.isMythicRarity(tokenID, proof)){
        emission = 230e13;
      } else if(oracle.isLegendaryRarity(tokenID, proof)){
        emission = 185e13;
      } else if(oracle.isRareRarity(tokenID, proof)){
        emission = 140e13;
      } else {
        emission = 93e13;
      }

      uint delta_time = (block.timestamp - tokenTimestamp);
      return delta_time.mul(emission).mul(getMultiplier(delta_time, totalStakedAmount, boostAmount)).div(100);
    }

    // multiplier activates daily
    function getMultiplier(uint delta_time, uint totalStakedAmount, uint boostAmount) internal view returns (uint) {
      // 0.83% / day
      uint multiplier = (60 * 60 * 24 * 120);


      if(boostAmount > 0){
        //12 days ~= 10.4% of boost
        //spread out bonus accross all nfts
        uint256 totalBonus = 24 * 60 * 60 * 12 * boostAmount / totalStakedAmount;
        delta_time += totalBonus;
      }


      uint multi = get_with_bound(delta_time.mul(100).div(multiplier).add(100), MAX_MULTIPLIER);

      if(multi < 100)
        multi = 100;

      return multi;
    }
    /// Clamp a value within a bound.
    /// The bound can be set with set_bound().
    function get_with_bound(uint value, uint bound) public pure returns (uint) {
          if (value < bound) {
              return value;
          } else {
              return bound;
          }
      }

}

interface IYokaiOracle {
  function isCommonRarity(uint id, bytes32[] memory _merkleProof) external view returns (bool);
  function isRareRarity(uint id, bytes32[] memory _merkleProof) external view returns (bool);
  function isLegendaryRarity(uint id, bytes32[] memory _merkleProof) external view returns (bool);
  function isMythicRarity(uint id, bytes32[] memory _merkleProof) external view returns (bool);
  function isSpecialRarity(uint id, bytes32[] memory _merkleProof) external view returns (bool);
}

interface IBoost {
  function balanceOf(address account, uint256 id) external view  returns (uint256);
}
