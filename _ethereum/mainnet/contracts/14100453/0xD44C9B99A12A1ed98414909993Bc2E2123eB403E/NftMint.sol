// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// NFT contract to inherit from.
import "./ERC721.sol";

// Helper functions OpenZeppelin provides.
import "./Counters.sol";
import "./Strings.sol";
import "./Base64.sol";


import "./console.sol";

// Our contract inherits from ERC721, which is the standard NFT contract!
contract NftMint is ERC721 {

  struct CharacterAttributes {
    uint characterIndex;
    string name;
    string imageURI;
    string videoURI;    
  }

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  CharacterAttributes[] defaultCharacters;

  // mapping(uint256 => CharacterAttributes) public nftHolderAttributes;
  // event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);

  // uint256 private seed;
  address private owner;
  uint private totalSupply;

  constructor()
    ERC721("Brush Gold Pass Club", "BGPC")
  {
    owner = msg.sender;
    // seed = (block.timestamp + block.difficulty) % 100;
    totalSupply = 10000;//total;

    defaultCharacters.push(CharacterAttributes({
      characterIndex: 0, //i,
      name: "BGPC", //characterNames[i],
      imageURI: "QmcZBqzPZFyEvjBgzsDoMnFDVNn58zc1EB8MB6wNeZ7HrP", //characterImageURIs[i],
      videoURI: "QmbLw2gvs6cwa5pfSRdoy3agthtFo2QCLctbYYgFLHnqQx" //characterVideoURIs[i]
    }));

    _tokenIds.increment();
  }
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "', defaultCharacters[0].name, ' #', Strings.toString(_tokenId),
            '", "description": "", '
            '"image": "ipfs://', defaultCharacters[0].imageURI, '",',
            '"external_url": "https://www.bgpc.io",',
            '"animation_url": "ipfs://', defaultCharacters[0].videoURI, '",',
            '"attributes": [ ',
            '{ "trait_type": "Pass Level", "value": "Gold"}, { "trait_type": "Builder", "value": "Bigtone"}]}'
          )
        )
      )
    );
    string memory output = string(
        abi.encodePacked("data:application/json;base64,", json)
    );    
    return output;
  }


  function mintNftTo(address _toAddr, uint32 count) external {
    require(count > 0 && count <= 100, "Count Error");
    require(owner == msg.sender, "Only Contract Owner can mint!");
    require(_toAddr != address(0), "Address Error");
    for (uint32 i = 0; i < count; i++) {
      uint256 newItemId = _tokenIds.current();
      if (newItemId > totalSupply) {
        return;
      }
      _safeMint(_toAddr, newItemId);
      // Increment the tokenId for the next person that uses it.
      _tokenIds.increment();
      // emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }
  }
  function mintNft(uint32 count) external {
    require(count > 0 && count <= 100, "Count Error");
    require(owner == msg.sender, "Only Contract Owner can mint!");
    for (uint32 i = 0; i < count; i++) {
      uint256 newItemId = _tokenIds.current();
      if (newItemId > totalSupply) {
        return;
      }

      _safeMint(msg.sender, newItemId);
      // Increment the tokenId for the next person that uses it.
      _tokenIds.increment();
      // emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }
  }
  function burn(uint _tokenId) external {    
    require(msg.sender == ERC721.ownerOf(_tokenId), "Only owner can burn");
    _burn(_tokenId);
  }
}