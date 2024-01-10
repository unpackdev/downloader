// SPDX-License-Identifier: MIT
//                _                                  
//               (`  ).                   _           
//              (     ).              .:(`  )`.       
// )           _(       '`.          :(   .    )      
//         .=(`(      .   )     .--  `.  (    ) )      
//        ((    (..__.:'-'   .+(   )   ` _`  ) )                 
// `.     `(       ) )       (   .  )     (   )  ._   
//   )      ` __.:'   )     (   (   ))     `-'.-(`  ) 
// )  )  ( )       --'       `- __.'         :(      )) 
// .-'  (_.'          .')                    `(    )  ))
//                   (_  )  dream gardener     ` __.:'          
//                                         
// --..,___.--,--'`,---..-.--+--.,,-,,..._.--..-._.-a:f--.
//
// by @eddietree

pragma solidity ^0.8.0;

import "./Base64.sol";
import "./DreamSeedProduct.sol";

contract DreamGardenersNFT is DreamSeedProduct {

  enum GardenerType { 
    DREAM, // 0 
    NIGHTMARE // 1
  }

  struct GardenerData { 
    GardenerType gardenerType;
    uint16 index; // index depending on type
  }

  struct GardenerSupplyData { 
    string metaURI;
    uint16 minted;
    uint16 numRevealed;
  }

  address public contractDreamGardens;
  GardenerData[] public gardeners; 
  GardenerSupplyData[2] public supplyData; 

  bytes4 constant sigOwnerOfGarden = bytes4(keccak256("ownerOf(uint256)"));
  bytes4 constant sigIsNightmare = bytes4(keccak256("isNightmare(uint256)"));

  constructor(address _proxyRegistryAddress) ERC721TradableBurnable("Dream Gardeners NFT", "DREAMGARDENER", _proxyRegistryAddress) {  

    _prerevealMetaURI = "https://gateway.pinata.cloud/ipfs/QmayQ94oBm5FStyLd8WfX99cq4CK9JorKt2hiwU5uNwDKN";
    
    // DREAM
    supplyData[uint8(GardenerType.DREAM)] = (GardenerSupplyData(
    {
      metaURI: "https://gateway.pinata.cloud/ipfs/QmRA71NveXF5EFUSds873WqxkVuT8HvvATgz65ev3ea9d5/", 
      minted: 0, 
      numRevealed:0
    }));

    // NIGHTMARE
    supplyData[uint8(GardenerType.NIGHTMARE)] = (GardenerSupplyData(
    {
        metaURI: "https://gateway.pinata.cloud/ipfs/QmRA71NveXF5EFUSds873WqxkVuT8HvvATgz65ev3ea9d5/", 
        minted: 0, 
        numRevealed:0
    }));
  }

  function setContractDreamGardens(address newAddress) external onlyOwner {
      contractDreamGardens = newAddress;
  }

  function setRevealedURI(GardenerType gardenerType, string memory _value) external onlyOwner {
    supplyData[uint(gardenerType)].metaURI = _value;
  }

  function setNumRevealed(GardenerType gardenerType, uint16 numRevealed) external onlyOwner {
    supplyData[uint(gardenerType)].numRevealed = numRevealed;
  }

  function getSupplyInfo(GardenerType gardenerType) external view returns (string memory, uint16, uint16) {
    return ( supplyData[uint(gardenerType)].metaURI, supplyData[uint(gardenerType)].minted, supplyData[uint(gardenerType)].numRevealed);
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    require(_tokenId >= 1 && _tokenId <= MAX_SUPPLY, "Not valid token range");

    GardenerData memory gardenerData = gardeners[_tokenId-1];
    GardenerType gardenerType = gardenerData.gardenerType;
    uint16 typeIndex = gardenerData.index; // index within category

    bool isRevealed = typeIndex < supplyData[uint(gardenerType)].numRevealed;
    if (!isRevealed) { // prereveal

      string memory gardenerTypeStr = string(gardenerType == GardenerType.DREAM ? "Warden of the Light" : "Guardian of Shadows");

      string memory json = Base64.encode(
          bytes(string(
              abi.encodePacked(
                  '{"name": ', '"', gardenerTypeStr ,' #',Strings.toString(_tokenId),'",',
                  '"description": "Summoning...",',
                  '"attributes":[{"trait_type":"Status", "value":"Unrevealed"}, {"trait_type":"Type", "value":"',gardenerTypeStr,'"}],',
                  '"image": "', _prerevealMetaURI, '"}' 
              )
          ))
      );
      return string(abi.encodePacked('data:application/json;base64,', json));
    }  else { // revealed
      uint16 jsonIndex = typeIndex+1;
      return string(abi.encodePacked(supplyData[uint(gardenerType)].metaURI, Strings.toString(jsonIndex), ".json"));
    }
  }

  function isOwnerOfGarden(address ownerAddress, uint256 gardenTokenId) private returns (bool) {
    // check ownership of dream garden
    bytes memory data = abi.encodeWithSelector(sigOwnerOfGarden, gardenTokenId);
    (bool success, bytes memory returnedData) = contractDreamGardens.call(data);
    require(success);
    address addressSeedOwner =  abi.decode(returnedData, (address));
    return addressSeedOwner == ownerAddress;
  }

  function isGardenNightmare(uint256 gardenTokenId) private returns (bool) {
    bytes memory data = abi.encodeWithSelector(sigIsNightmare, gardenTokenId);
    (bool success, bytes memory returnedData) = contractDreamGardens.call(data);
    require(success);

    return abi.decode(returnedData, (bool));
  }

  // mints
  function reserveGardener(uint numberOfTokens, GardenerType gardenerType) external onlyOwner {
    for (uint256 i = 0; i < numberOfTokens; i++) {
      _mintTo(msg.sender, gardenerType);
    }
  }

  function _mintTo(address receiver, GardenerType gardenerType) private {
    require(totalSupply() < MAX_SUPPLY, "Purchase would exceed max tokens");

    uint16 index = supplyData[uint(gardenerType)].minted;
    supplyData[uint(gardenerType)].minted += 1;
    gardeners.push(GardenerData(gardenerType, index));

    mintTo(receiver);
  }

  function mintGardener(uint256 gardenTokenId, uint256 seedTokenId) external {
    require(mintIsActive, "Must be active to mint tokens");
    require(isOwnerOfGarden(msg.sender, gardenTokenId), "doesn't own garden!");

    // destroy seed
    burnDreamSeed(seedTokenId);

    // mint gardener
    GardenerType gardenerType = isGardenNightmare(gardenTokenId) ? GardenerType.NIGHTMARE : GardenerType.DREAM;
    _mintTo(msg.sender, gardenerType);
  }
}