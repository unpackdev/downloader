// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTRarityRegister.sol";
import "./IRaffle.sol";
import "./ERC165.sol";
import "./ERC1155.sol";
import "./RaffleAdminAccessControl.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";

contract PrizeAdder is RaffleAdminAccessControl, IERC721Receiver, IERC1155Receiver{
  INFTRarityRegister public rarityRegister;
  IRaffle public raffle;
  
  constructor(INFTRarityRegister _rarityRegister, IRaffle _raffle) RaffleAdminAccessControl(msg.sender, address(this)) {
    rarityRegister = _rarityRegister;
    raffle = _raffle;
  }

  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function onERC1155BatchReceived(address operator, address from, uint256[] memory ids, uint256[] memory values, bytes calldata data) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function supportsInterface(bytes4 interfaceID) public pure override(IERC165, AccessControlEnumerable) returns (bool) {
      return  interfaceID == 0x01ffc9a7 ||    // ERC165
              interfaceID == 0x4e2312e0;      // ERC1155_ACCEPTED ^ ERC1155_BATCH_ACCEPTED;
  }

  function storeNftRarity(
    address tokenAddress, 
    uint256 tokenId,
    uint16 rarityValue
  ) private {
    rarityRegister.storeNftRarity(
      tokenAddress,
      tokenId,
      rarityValue
    );
  }

  function addPrize(
    address tokenAddress,
    uint256 tokenId,
    uint256 raffleIndex
  ) private {
    bool isERC1155 = ERC165(tokenAddress).supportsInterface(type(IERC1155).interfaceId);

    if(isERC1155) {
      ERC1155(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId, 1, '');
      ERC1155(tokenAddress).setApprovalForAll(address(raffle), true);
      raffle.addERC1155Prize(raffleIndex, tokenAddress, tokenId);
    }
    else {
      ERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);
      ERC721(tokenAddress).approve(address(raffle), tokenId);
      raffle.addERC721Prize(raffleIndex, tokenAddress, tokenId);
    }
  }

  function addPrizeAndRarity(
    address tokenAddress,
    uint256 tokenId,
    uint16 rarityValue,
    uint256 raffleIndex
  ) private {
    // We do this because for ERC1155 we can have multiple tokens for the same id
    // and we cannot make the call again because it will revert and is also not needed
    uint256 rarity = rarityRegister.getNftRarity(tokenAddress, tokenId);
    if(rarity == 0) {
      storeNftRarity(
        tokenAddress,
        tokenId,
        rarityValue
      );
    }

    addPrize(tokenAddress, tokenId, raffleIndex);
  }

  function addPrizesAndRarity(
    address[] memory tokenAddress,
    uint256[] memory tokenId,
    uint16[] memory rarityValue,
    uint256[] memory raffleIndex
  ) public onlyPrizeManager {
    for(uint256 i = 0 ; i < tokenAddress.length ; i++) {
      addPrizeAndRarity(
        tokenAddress[i],
        tokenId[i],
        rarityValue[i],
        raffleIndex[i]
      );
    }
  }

  function addPrizes(
    address[] memory tokenAddress,
    uint256[] memory tokenId,
    uint256[] memory raffleIndex
  ) public onlyPrizeManager {
    for(uint256 i = 0 ; i < tokenAddress.length ; i++) {
      addPrize(
        tokenAddress[i],
        tokenId[i],
        raffleIndex[i]
      );
    }
  }

}

// Deployed 0.092213119 ETH
// Deployed 0.093342736 ETH