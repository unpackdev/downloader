// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//   ____           _   _ _             _      
//  / ___|_ __ __ _| |_(_) |_ _   _  __| | ___ 
// | |  _| '__/ _` | __| | __| | | |/ _` |/ _ \
// | |_| | | | (_| | |_| | |_| |_| | (_| |  __/
//  \____|_|  \__,_|\__|_|\__|\__,_|\__,_|\___|
//
// A collection of 2,222 unique Non-Fungible Power SUNFLOWERS living in 
// the metaverse. Becoming a GRATITUDE GANG NFT owner introduces you to 
// a FAMILY of heart-centered, purpose-driven, service-oriented human 
// beings.
//
// https://www.gratitudegang.io/
//

import "./IERC721.sol";
import "./IERC20.sol";

import "./ReentrancyGuard.sol";

import "./Address.sol";
import "./Context.sol";

// ============ Errors ============

error InvalidCall();

// ============ Interfaces ============

interface IGratis is IERC20 {
  function mint(address to, uint256 amount) external;
}

interface IERC721B is IERC721 {
  function totalSupply() external view returns(uint256);
}

// ============ Contract ============

/**
 * @dev Soft stake sunflowers, get $GRATIS. $GRATIS can be used to 
 * purchase items in the Gratitude Store
 */
contract FlowerShower is Context, ReentrancyGuard {
  //used in unstake()
  using Address for address;

  // ============ Constants ============

  //tokens earned per second
  uint256 public constant TOKEN_RATE = 0.00006 ether;
  IERC721B public immutable SUNFLOWER_COLLECTION;
  //this is the contract address for $GRATIS
  IGratis public immutable GRATIS;

  // ============ Storage ============

  //start time of a token staked
  mapping(uint256 => uint256) private _start;

  // ============ Deploy ============

  constructor(IERC721B collection, IGratis gratis) {
    SUNFLOWER_COLLECTION = collection;
    GRATIS = gratis;
  }

  // ============ Read Methods ============

  /**
   * @dev Returns all the tokens an owner owns (just a helper)
   */
  function ownerTokens(address owner) public view returns(
    uint256[] memory staked,
    uint256[] memory unstaked
  ) {
    uint256 balance = SUNFLOWER_COLLECTION.balanceOf(owner);
    if (balance == 0) {
      return (staked, unstaked);
    }

    uint256 supply = SUNFLOWER_COLLECTION.totalSupply();

    uint256 stakedIndex;
    uint256 unstakedIndex;
    
    staked = new uint256[](balance);
    unstaked = new uint256[](balance);

    for (uint256 i = 1; i <= supply; i++) {
      if (SUNFLOWER_COLLECTION.ownerOf(i) == owner) {
        if (_start[i] > 0) {
          staked[stakedIndex++] = i;
        } else {
          unstaked[unstakedIndex++] = i;
        }
      }
    }

    uint256 stakedSub = balance - stakedIndex;
    uint256 unstakedSub = balance - unstakedIndex;

    //resize arrays
    assembly { 
      mstore(staked, sub(mload(staked), stakedSub))
      mstore(unstaked, sub(mload(unstaked), unstakedSub))
    }
  }

  /**
   * @dev Calculate how many a tokens an NFT earned
   */
  function releaseable(uint256 tokenId) public view returns(uint256) {
    if (_start[tokenId] == 0) {
      return 0;
    }
    return (block.timestamp - _start[tokenId]) * TOKEN_RATE;
  }

  /**
   * @dev Returns the start time when stake started
   */
  function stakedSince(uint256 tokenId) public view returns(uint256) {
    return _start[tokenId];
  }

  /**
   * @dev Calculate how many a tokens a staker earned
   */
  function totalReleaseable(uint256[] memory tokenIds) 
    public view returns(uint256 total) 
  {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      total += releaseable(tokenIds[i]);
    }
  }

  // ============ Write Methods ============

  /**
   * @dev Releases tokens without unstaking
   */
  function release(uint256[] memory tokenIds) external nonReentrant {
    //get the staker
    address staker = _msgSender();
    uint256 toRelease = 0;
    uint256 timestamp = block.timestamp;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      //if not owner
      if (SUNFLOWER_COLLECTION.ownerOf(tokenIds[i]) != staker) 
        revert InvalidCall();
      //add releaseable
      toRelease += releaseable(tokenIds[i]);
      //reset when staking started
      _start[tokenIds[i]] = timestamp;
    }
    //next mint tokens
    address(GRATIS).functionCall(
      abi.encodeWithSelector(GRATIS.mint.selector, staker, toRelease), 
      "Low-level mint failed"
    );
  }

  /**
   * @dev Stakes NFTs
   */
  function stake(uint256[] memory tokenIds) external {
    //get the staker
    address staker = _msgSender();
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      //if (for some reason) token is already staked
      if (_start[tokenId] > 0
        //or if not owner
        || SUNFLOWER_COLLECTION.ownerOf(tokenId) != staker
      ) revert InvalidCall();
      //remember when staking started
      _start[tokenId] = block.timestamp;
    }
  }

  /**
   * @dev Unstakes NFTs and releases tokens
   */
  function unstake(uint256[] memory tokenIds) external nonReentrant {
    //get the staker
    address staker = _msgSender();
    uint256 toRelease = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      //if not owner
      if (SUNFLOWER_COLLECTION.ownerOf(tokenIds[i]) != staker) 
        revert InvalidCall();
      //add releasable
      toRelease += releaseable(tokenIds[i]);
      //zero out the start date
      _start[tokenIds[i]] = 0;
    }

    //next mint tokens
    address(GRATIS).functionCall(
      abi.encodeWithSelector(GRATIS.mint.selector, staker, toRelease), 
      "Low-level mint failed"
    );
  }
}