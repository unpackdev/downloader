//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC721Staked.sol";

contract CritterzStaking is IERC721ReceiverUpgradeable, OwnableUpgradeable {
  using SafeMath for uint256;

  /* 
  GLOBAL STATE
  */

  mapping(address => mapping(uint256 => address)) public stakings;
  mapping(address => address) public tokenToStakedToken;

  function initialize() public initializer {
    __Ownable_init();
  }

  /* 
  WRITE FUNCTIONS
  */

  function stake(
    address account,
    address token,
    uint256[] calldata stakeIds
  ) external onlyAccountOrToken(account, token) {
    for (uint256 i = 0; i < stakeIds.length; i++) {
      _stakeToken(account, token, stakeIds[i]);
    }
  }

  function unstake(
    address account,
    address token,
    uint256[] calldata stakeIds
  ) external onlyAccountOrToken(account, token) {
    for (uint256 i = 0; i < stakeIds.length; i++) {
      uint256 tokenId = stakeIds[i];
      _unstakeToken(account, token, tokenId);
    }
  }

  function _stakeToken(
    address staker,
    address token,
    uint256 tokenId
  ) private {
    IERC721(token).transferFrom(staker, address(this), tokenId);
    IERC721Staked(tokenToStakedToken[token]).mint(staker, tokenId);
    stakings[token][tokenId] = staker;
  }

  function _stakeReceivedToken(
    address staker,
    address token,
    uint256 tokenId
  ) private {
    require(
      IERC721(token).ownerOf(tokenId) == address(this),
      "Token not received"
    );
    IERC721Staked(tokenToStakedToken[token]).mint(staker, tokenId);
    stakings[token][tokenId] = staker;
  }

  function _unstakeToken(
    address staker,
    address token,
    uint256 tokenId
  ) private {
    IERC721(token).transferFrom(address(this), staker, tokenId);
    IERC721Staked(tokenToStakedToken[token]).burn(tokenId);
    require(stakings[token][tokenId] == staker, "Could not unstake token");
    delete stakings[token][tokenId];
  }

  function onERC721Received(
    address,
    address,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    address token = msg.sender;
    require(
      tokenToStakedToken[token] != address(0),
      "Caller is not an accepted token"
    );
    address owner = abi.decode(data, (address));
    _stakeReceivedToken(owner, token, tokenId);
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  /*
  READ FUNCTIONS
  */

  function ownerOf(address token, uint256 tokenId)
    public
    view
    returns (address)
  {
    address owner = stakings[token][tokenId];
    require(owner != address(0), "Owner query for nonexistent token");
    return owner;
  }

  /*
  OWNER FUNCTIONS
  */

  function addTokenPair(address token, address stakedToken) external onlyOwner {
    tokenToStakedToken[token] = stakedToken;
  }

  /*
  MODIFIER
  */

  modifier onlyAccountOrToken(address account, address token) {
    require(
      msg.sender == account || msg.sender == token,
      "Caller is not account nor token contract"
    );
    _;
  }
}
