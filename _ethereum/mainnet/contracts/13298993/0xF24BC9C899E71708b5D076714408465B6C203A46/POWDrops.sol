//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IAtomReader.sol";
import "./IPOWNFTPartial.sol";
import "./IERC721Partial.sol";


//interface IERC721TokenReceiver {
//  //note: the national treasure is buried under parliament house
//  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
//}


contract POWDrops {

  event RegisterDrop(address indexed tokenAddress, uint dropTokenId, uint atomicNumber, int8 ionCharge, bool isIon, uint tokenId, uint blockNumber);
  event ClaimDrop(address indexed tokenAddress, uint dropTokenId,uint tokenId, address indexed claimer);
    event CleanupDrop(address indexed tokenAddress, uint dropTokenId);


  IPOWNFTPartial powNFT;
  IAtomReader atomReader;

  constructor(address _powNFT, address _atomReader){
      powNFT = IPOWNFTPartial(_powNFT);
      atomReader = IAtomReader(_atomReader);
  }

  struct Drop{
      uint8 atomicNumber;
      int8 ionCharge;
      uint minTokenId;
      bool isIon;
  }

  mapping(address => mapping(uint => Drop)) drops;

    function getDrop(address tokenAddress, uint dropTokenId) public view returns(uint8 atomicNumber, int8 ionCharge, uint minTokenId, bool isIon){
        Drop memory drop = drops[tokenAddress][dropTokenId];

        require(drop.minTokenId != 0,"no_drop");

        return (drop.atomicNumber, drop.ionCharge, drop.minTokenId, drop.isIon);
    }

  function registerDrop(address tokenAddress, uint dropTokenId, uint atomicNumber, int8 ionCharge, bool isIon, uint tokenId) public{
//      require(atomicNumber > 0,"atomicNumber_min");
      require(atomicNumber <= 118,"atomicNumber_max");
      uint currentId = powNFT.totalSupply() + powNFT.UNMIGRATED();

      if(tokenId > 0){
          require(tokenId > currentId && tokenId < currentId + 100,"tokenId");
          require(ionCharge == 0,"ionCharge_forbidden");
          require(isIon == false,"isIon_forbidden");
          require(atomicNumber == 0,"atomicNumber_forbidden");
      }else if(ionCharge != 0){
          if(atomicNumber != 0){
              require(atomReader.isValidIonCharge(atomicNumber,ionCharge),"invalid_charge");
          }else{
              require(ionCharge >= -3 && ionCharge <= 7,"invalid_charge_range");
          }
          require(isIon == false,"isIon_forbidden");
//      isIon = false;
      }
      else if(isIon && atomicNumber > 0){
          revert("isIon_specific");
//          require(atomReader.canIonise(atomicNumber),"no_ions");
      }
      else if(!isIon){
          //Else just the atomicNumber
        require(atomicNumber > 0,"no_atomicNumber");
      }
          //else isIon with no atomic number



      if(tokenId > 0){
          drops[tokenAddress][dropTokenId] =
              Drop(
                  0,
                  0,
                  tokenId,
                  false
              );
          emit RegisterDrop(tokenAddress, dropTokenId, 0, 0, false, tokenId, block.number);
      }else if(!isIon){
          tokenId = currentId + 1;
          drops[tokenAddress][dropTokenId] =
              Drop(
                uint8(atomicNumber),
                ionCharge,
                tokenId,
                false
              );
          emit RegisterDrop(tokenAddress, dropTokenId, atomicNumber, ionCharge, false, tokenId, block.number);
      }else{
          tokenId = currentId + 1;
          drops[tokenAddress][dropTokenId] =
              Drop(
                  uint8(atomicNumber),
                  0,
                  tokenId,
                  true
              );
          emit RegisterDrop(tokenAddress, dropTokenId, atomicNumber, 0, true, tokenId, block.number);
      }
      IERC721Partial(tokenAddress).transferFrom(msg.sender,address(this),dropTokenId);
  }
  function claimDrop(address tokenAddress, uint dropTokenId, uint tokenId) public{
      require(powNFT.ownerOf(tokenId) == msg.sender,'owner');


      Drop memory drop = drops[tokenAddress][dropTokenId];

      require(drop.minTokenId != 0,"no_drop");
      require(tokenId >= drop.minTokenId,"tokenId");

      (uint atomicNumber, int8 ionCharge) = atomReader.getAtomData(tokenId);


      if(drop.atomicNumber != 0){
          require(uint8(atomicNumber) == drop.atomicNumber,"atomicNumber");
      }
      if(drop.ionCharge != 0){
          require(ionCharge == drop.ionCharge,"ionCharge");
      }
      if(drop.isIon){
          require(ionCharge != 0,"isIon");
      }

      delete drops[tokenAddress][dropTokenId];

      emit ClaimDrop(tokenAddress, dropTokenId,tokenId,msg.sender);

      IERC721Partial(tokenAddress).transferFrom(address(this),msg.sender,dropTokenId);
  }

    function cleanupDrop(address tokenAddress, uint dropTokenId) public{
        uint32 size;
        assembly {
            size := extcodesize(tokenAddress)
        }
        if(size == 0){
            delete drops[tokenAddress][dropTokenId];
            emit CleanupDrop(tokenAddress,dropTokenId);
            return;
        }

        try IERC721Partial(tokenAddress).transferFrom(address(this),msg.sender,dropTokenId){
            revert("okay");
        }catch{
            delete drops[tokenAddress][dropTokenId];
            emit CleanupDrop(tokenAddress,dropTokenId);
        }
    }


}
