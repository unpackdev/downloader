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
import "./IERC721Receiver.sol";
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
 * @dev Stake sunflowers, get $GRATIS. $GRATIS can be used to purchase
 * items in the Gratitude Store
 */
contract FlowerPower is Context, ReentrancyGuard, IERC721Receiver {
  //used in unstake()
  using Address for address;

  // ============ Constants ============

  //tokens earned per second
  uint256 public constant TOKEN_RATE = 0.0001 ether;
  IERC721B public immutable SUNFLOWER_COLLECTION;
  //this is the contract address for $GRATIS
  IGratis public immutable GRATIS;

  // ============ Storage ============

  //mapping of owners to tokens
  mapping(address => uint256[]) private _stakers;
  //start time of a token staked
  mapping(uint256 => uint256) private _start;

  // ============ Deploy ============

  constructor(IERC721B collection, IGratis gratis) {
    SUNFLOWER_COLLECTION = collection;
    GRATIS = gratis;
  }

  // ============ Read Methods ============

  /**
   * @dev Returns all the tokens an owner owns
   */
  function ownerTokens(address owner) external view returns(uint256[] memory) {
    uint256 supply = SUNFLOWER_COLLECTION.totalSupply();
    uint256[] memory tokens = new uint256[](
      SUNFLOWER_COLLECTION.balanceOf(owner)
    );
    uint256 index;
    for (uint256 i = 1; i <= supply; i++) {
      if (SUNFLOWER_COLLECTION.ownerOf(i) == owner) {
        tokens[index++] = i;
      }
    }
    return tokens;
  }

  /**
   * @dev Returns all the tokens the `owner` has staked
   */
  function tokensStaked(address owner) external view returns(uint256[] memory) {
    return _stakers[owner];
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
   * @dev Returns true if token staked
   */
  function stakedSince(uint256 tokenId) public view returns(uint256) {
    return _start[tokenId];
  }

  /**
   * @dev Calculate how many a tokens a staker earned
   */
  function totalReleaseable(address staker) 
    public view returns(uint256 total) 
  {
    for (uint256 i = 0; i < _stakers[staker].length; i++) {
      total += releaseable(_stakers[staker][i]);
    }
  }

  // ============ Write Methods ============

  /**
   * @dev allows to receive tokens
   */
  function onERC721Received(address, address, uint256, bytes calldata)
    external pure returns(bytes4)
  {
    return 0x150b7a02;
  }

  /**
   * @dev Releases tokens without unstaking
   */
  function release() external nonReentrant {
    //get the staker
    address staker = _msgSender();
    if (_stakers[staker].length == 0) revert InvalidCall();
    uint256 toRelease = 0;
    for (uint256 i = 0; i < _stakers[staker].length; i++) {
      toRelease += releaseable(_stakers[staker][i]);
      //reset when staking started
      _start[_stakers[staker][i]] = block.timestamp;
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
  function stake(uint256 tokenId) external {
    //if (for some reason) token is already staked
    if (_start[tokenId] > 0
      //or if not approved
      || SUNFLOWER_COLLECTION.getApproved(tokenId) != address(this)
    ) revert InvalidCall();
    //get the staker
    address staker = _msgSender();
    //transfer token to here
    SUNFLOWER_COLLECTION.safeTransferFrom(staker, address(this), tokenId);
    //add staker so we know who to return this to
    _stakers[staker].push(tokenId);
    //remember when staking started
    _start[tokenId] = block.timestamp;
  }

  /**
   * @dev Unstakes NFTs and releases tokens
   */
  function unstake() external nonReentrant {
    //get the staker
    address staker = _msgSender();
    if (_stakers[staker].length == 0) revert InvalidCall();
    uint256 toRelease = 0;
    for (uint256 i = 0; i < _stakers[staker].length; i++) {
      toRelease += releaseable(_stakers[staker][i]);
      //transfer token to staker
      SUNFLOWER_COLLECTION.safeTransferFrom(
        address(this), 
        staker, 
        _stakers[staker][i]
      );
      //zero out the start date
      _start[_stakers[staker][i]] = 0;
    }

    //remove the staker
    delete _stakers[staker];

    //next mint tokens
    address(GRATIS).functionCall(
      abi.encodeWithSelector(
        GRATIS.mint.selector, 
        staker, 
        toRelease
      ), 
      "Low-level mint failed"
    );
  }
}