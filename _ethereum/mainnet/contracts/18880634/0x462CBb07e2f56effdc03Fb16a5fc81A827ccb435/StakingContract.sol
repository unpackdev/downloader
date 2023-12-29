// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./Strings.sol";
import "./Address.sol";

interface IERC721 {
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract StakingContract is IERC721Receiver, Ownable {
  using Strings for uint256;
  // contractAddress => address => amount
  mapping(address => mapping(address => mapping(uint256 => uint))) public stakingInfo;
  event Staked(address indexed contractAddress, address indexed walletAddress, uint256 indexed tokenId);
  event Unstaked(address indexed contractAddress, address indexed walletAddress, uint256 indexed tokenId);

  constructor() {}

  function bulkStake(address[] memory contractAddresses, uint256[] memory tokenIds) public {
    require(contractAddresses.length == tokenIds.length, 'Length of contractAddresses and tokenIds should be same');
    for (uint256 i = 0; i < tokenIds.length; i++) {
      stake(contractAddresses[i], tokenIds[i]);
    }
  }

  function bulkUnstake(address[] memory contractAddresses, uint256[] memory tokenIds) public {
    require(contractAddresses.length == tokenIds.length, 'Length of contractAddresses and tokenIds should be same');
    for (uint256 i = 0; i < tokenIds.length; i++) {
      unstake(contractAddresses[i], tokenIds[i]);
    }
  }

  function stake(address contractAddress, uint256 tokenId) public {
    require(stakingInfo[contractAddress][msg.sender][tokenId] == 0, 'You already have this token');

    stakingInfo[contractAddress][msg.sender][tokenId] = 1;
    IERC721(contractAddress).safeTransferFrom(msg.sender, address(this), tokenId);
    emit Staked(contractAddress, msg.sender, tokenId);
  }

  function addStakingInfo(address walletAddress, uint256[] calldata tokenIds) public {
    require(Address.isContract(msg.sender), 'Only contract can call this function');
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(stakingInfo[msg.sender][walletAddress][tokenId] == 0, 'This token is already staked');
      stakingInfo[msg.sender][walletAddress][tokenId] = 1;
      emit Staked(msg.sender, walletAddress, tokenId);
    }
  }

  function unstake(address contractAddress, uint256 tokenId) public {
    require(stakingInfo[contractAddress][msg.sender][tokenId] == 1, "You don't have this token");
    stakingInfo[contractAddress][msg.sender][tokenId] = 0;
    IERC721(contractAddress).safeTransferFrom(address(this), msg.sender, tokenId);
    emit Unstaked(contractAddress, msg.sender, tokenId);
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4) {
    return this.onERC721Received.selector;
  }
}
