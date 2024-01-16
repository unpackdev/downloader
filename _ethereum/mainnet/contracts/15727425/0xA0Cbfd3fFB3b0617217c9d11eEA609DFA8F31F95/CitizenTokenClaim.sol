// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.9;

import "./ILand.sol";
import "./IERC721.sol";
import "./console.sol";

// 2022 $LAND Claim for $CITIZENs.
contract CitizenTokenClaim {

  ILand public immutable landERC20;
  IERC721 public immutable citizenERC721;
  
  uint256 claimStartTime;
  uint256 claimEndTime;

  mapping(uint256 => bool) public _claimedERC721;

  event LandClaimed(address to, uint256 amount);

  constructor(ILand _landERC20, IERC721 _citizenERC721, uint256 _claimStartTime, uint256 _claimEndTime) { 
      landERC20 = _landERC20;
      citizenERC721 = _citizenERC721;
      claimStartTime = _claimStartTime;
      claimEndTime = _claimEndTime;
  }

  // TODO: Let $CITIZENs mint.
  function claim(uint256 tokenId) external {

    address to = msg.sender;

    // Verify that timelock has expired.
    require(block.timestamp >= claimStartTime, 'Cannot claim yet.');   

    // Verify that timelock has expired.
    require(block.timestamp <= claimEndTime, 'Past claim date.');       

    // Require that the account calling is the same as the owner of the tokenId.
    require(citizenERC721.ownerOf(tokenId) == to, "Only token holder can claim.");

    // Verify that this token has not minted yet.
    require(_claimedERC721[tokenId] == false, 'Already claimed.');

    // Set that this token has been claimed.
    _claimedERC721[tokenId] = true;

    // Verify that token holder is 238 or lower.
    if(tokenId <= 238) {
        // Mint 500,000 to burned Alpha $CITIZENs who have burned.
        landERC20.mint(msg.sender, 500000 * 10 ** 18);
        emit LandClaimed(to, 500000 * 10 ** 18);
    }

    // Verify Alphas that burn after contract deployment.
    else if(tokenId <= 500) {
        // Mint 200,000 to Alpha $CITIZENs who burn after announcement.
        landERC20.mint(msg.sender, 200000 * 10 ** 18);
        emit LandClaimed(to, 200000 * 10 ** 18);
    }

    // Check to see if these $CITIZENs are not included in exception roots, e.g. ERC20 or Titan.
    else if(tokenId > 500) {
        // Mint 50,000 to any future $CITIZEN.
        landERC20.mint(msg.sender, 50000 * 10 ** 18);
        emit LandClaimed(to, 50000 * 10 ** 18);
    }

  }

}
