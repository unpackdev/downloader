// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";

contract BapesFutureStake is Ownable {
  event Staked(address owner, uint256 tokenId, uint256 timestamp);
  event Unstaked(address owner, uint256 tokenId, uint256 timestamp);

  struct Stake {
    address owner;
    uint256 tokenId;
    uint256 timestamp;
  }

  IERC721 private bapesFuture;

  mapping(address => Stake[]) private stakes;

  bool isPaused = true;

  constructor() {
    bapesFuture = IERC721(0xc67b9897D793a823F0E9CF850aA1b0d23E3f8d09);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function stake(uint256 _tokenId) external {
    require(!isPaused, "Staking is paused.");

    bapesFuture.safeTransferFrom(msg.sender, address(this), _tokenId);

    uint256 timestamp = block.timestamp;

    stakes[msg.sender].push(Stake(msg.sender, _tokenId, timestamp));

    emit Staked(msg.sender, _tokenId, timestamp);
  }

  function unstake(uint256 _tokenId) external {
    uint256 senderStakes = stakes[msg.sender].length;

    require(senderStakes > 0, "Address has no stakes.");

    for (uint256 i = 0; i < senderStakes; i++) {
      if (stakes[msg.sender][i].tokenId == _tokenId && stakes[msg.sender][i].timestamp != 0) {
        uint256 elapsedMins = (block.timestamp - stakes[msg.sender][i].timestamp) / 60;
        uint256 elapsedDays = elapsedMins / 1440;

        require(elapsedDays >= 90, "Can not unstake before 90 days.");

        bapesFuture.safeTransferFrom(address(this), msg.sender, _tokenId);

        stakes[msg.sender][i].timestamp = 0;

        emit Unstaked(msg.sender, _tokenId, block.timestamp);

        break;
      }

      if (i == senderStakes - 1) {
        revert("Provided token id not staked.");
      }
    }
  }

  function getStakes(address _address) external view returns (Stake[] memory) {
    uint256 addressStakes = stakes[_address].length;

    require(addressStakes > 0, "Address has no stakes.");

    Stake[] memory res = new Stake[](addressStakes);

    for (uint256 i = 0; i < addressStakes; i++) {
      if (stakes[_address][i].timestamp != 0) {
        res[i] = Stake(stakes[_address][i].owner, stakes[_address][i].tokenId, stakes[_address][i].timestamp);
      }
    }

    return res;
  }

  function togglePause(bool _state) external onlyOwner {
    isPaused = _state;
  }
}
