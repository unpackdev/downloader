// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract AsterfiStakingContract {
  struct Stake {
    address owner;
    uint256 tokenId;
    uint256 stakedAt;
    uint256 unstakeAvailableAt;
    bool active;
  }

  mapping(address => mapping(uint256 => Stake)) public stakes;
  mapping(address => uint256[]) public stakedNFTs;

  uint256 public stakingPeriod = 1 minutes;
  IERC721 public _AsterFiContract;

  constructor() {
    _AsterFiContract = IERC721(0xc6Bf836Eb4c65ac7546c1399239Cc9f45A1D0725);
  }

  function stake(uint256 _tokenId) external {
    require(
      _AsterFiContract.ownerOf(_tokenId) == msg.sender,
      "You don't own this NFT"
    );
    require(stakes[msg.sender][_tokenId].active == false, 'NFT already staked');

    stakes[msg.sender][_tokenId] = Stake(
      msg.sender,
      _tokenId,
      block.timestamp,
      block.timestamp + stakingPeriod,
      true
    );

    stakedNFTs[msg.sender].push(_tokenId);

    _AsterFiContract.transferFrom(msg.sender, address(this), _tokenId);
  }

  function unstake(uint256 _tokenId) external {
    require(stakes[msg.sender][_tokenId].active == true, 'NFT not staked');
    require(
      stakes[msg.sender][_tokenId].unstakeAvailableAt <= block.timestamp,
      'Cannot unstake yet'
    );

    uint256[] storage userStakedNFTs = stakedNFTs[msg.sender];
    for (uint256 i = 0; i < userStakedNFTs.length; i++) {
      if (userStakedNFTs[i] == _tokenId) {
        userStakedNFTs[i] = userStakedNFTs[userStakedNFTs.length - 1];
        userStakedNFTs.pop();
        break;
      }
    }

    delete stakes[msg.sender][_tokenId];

    _AsterFiContract.transferFrom(address(this), msg.sender, _tokenId);
  }

  function getStakeInfo(
    address _owner,
    uint256 _tokenId
  ) external view returns (Stake memory) {
    return stakes[_owner][_tokenId];
  }

  function getStakedNFTs(
    address _owner
  ) external view returns (uint256[] memory) {
    return stakedNFTs[_owner];
  }
}
