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
//                   (_  )  dreaming gardens   ` __.:'          
//                                         
// --..,___.--,--'`,---..-.--+--.,,-,,..._.--..-._.-a:f--.
//
// by @eddietree

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract DreamGardensNFT is ERC721Tradable {
  // JSONS
  string private _prerevealMetaURI = "https://gateway.pinata.cloud/ipfs/QmSX9UEjufVvifmszeUJENiCtMLFq8wA7jGhTJFdxeCACU/";
  string private _revealedMetaURI = "https://gateway.pinata.cloud/ipfs/QmRA71NveXF5EFUSds873WqxkVuT8HvvATgz65ev3ea9d5/";
  string private _nightmareMetaURI = "https://gateway.pinata.cloud/ipfs/QmbpWLqDtN3sdFtev4TkWca3tasGmAHgJkpXA21GBkLDke/";
  
  // states
  bool public saleIsActive = false;
  bool public isRevealed = false;

  uint256 public constant MAX_SUPPLY = 128;
  uint256 public constant MAX_PUBLIC_MINT = 16;
  uint256 public constant PRICE_PER_TOKEN = 0.064 ether;

  bool [MAX_SUPPLY] private _nightmareMap;
  mapping(address => uint8) private _allowList;

  constructor(address _proxyRegistryAddress) ERC721Tradable("Dream Gardens NFT", "DREAMGARDEN", _proxyRegistryAddress) public {  
    for(uint i = 0; i < MAX_SUPPLY; i+=1) {
      _nightmareMap[i] = false;
    }
  }

  function setSaleState(bool newState) public onlyOwner {
      saleIsActive = newState;
  }

  function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
      for (uint256 i = 0; i < addresses.length; i++) {
          _allowList[addresses[i]] = numAllowedToMint;
      }
  }

  function allowListNumAvailableToMint(address addr) external view returns (uint8) {
      return _allowList[addr];
  }

  function revealAll() public onlyOwner {
      isRevealed = true;
  }

  ///////////////////// URI

  function setPreRevealURI(string memory _value) public onlyOwner {
    _prerevealMetaURI = _value;
  }

  function setRevealedURI(string memory _value) public onlyOwner {
    _revealedMetaURI = _value;
  }

  function setNightmareURI(string memory _value) public onlyOwner {
    _nightmareMetaURI = _value;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    require(_tokenId >= 1 && _tokenId <= MAX_SUPPLY, "Not valid token range");

    if (!isRevealed) { // prereveal
      return string(abi.encodePacked(_prerevealMetaURI, Strings.toString(_tokenId), ".json"));
    } else if (isNightmare(_tokenId)) { // nightmare
      return string(abi.encodePacked(_nightmareMetaURI, Strings.toString(_tokenId), ".json"));
    } else { // revealed
      return string(abi.encodePacked(_revealedMetaURI, Strings.toString(_tokenId), ".json"));
    }
  }

  ///////////////  nightmare
  function isNightmare(uint256 _tokenId) public view returns (bool) {
    require(_tokenId >= 1 && _tokenId <= MAX_SUPPLY, "Not valid token range");
    return _nightmareMap[_tokenId-1];
  }

  function setNightmareMode(uint256 _tokenId) public  {
    require(_tokenId >= 1 && _tokenId <= MAX_SUPPLY, "Not valid token range");

    address ownerOfToken = ownerOf(_tokenId);
    require(ownerOfToken == msg.sender, "Not the owner");

    // make sure owner owns this token
    if (ownerOfToken == msg.sender) {
      _nightmareMap[_tokenId-1] = true;
    }
  }

  function forceNightmareMode(uint256 _tokenId, bool _nightmareMode) public onlyOwner {
    require(_tokenId >= 1 && _tokenId <= MAX_SUPPLY, "Not valid token range");
    _nightmareMap[_tokenId-1] = _nightmareMode;
  }

  function nightmareCount() public view returns (uint) {
    uint count = 0;

    for(uint i = 0; i < MAX_SUPPLY; i+=1) {
      count += _nightmareMap[i] == true ? 1 : 0;
    }

    return count;
  }

  ///////////////  mint
  function reserveGarden(uint numberOfTokens) public onlyOwner {
    uint256 ts = totalSupply();
    require(ts + numberOfTokens <= MAX_SUPPLY, "Mint would exceed max tokens");

    for (uint256 i = 0; i < numberOfTokens; i++) {
      mintTo(msg.sender);
    }
  }

  function reserveGardenGift(uint numberOfTokens, address addr) public onlyOwner {
    uint256 ts = totalSupply();
    require(ts + numberOfTokens <= MAX_SUPPLY, "Mint would exceed max tokens");

    for (uint256 i = 0; i < numberOfTokens; i++) {
      mintTo(addr);
    }
  }

  function mintGardenAllowlist(uint8 numberOfTokens) public payable {
    uint256 ts = totalSupply();

    require(numberOfTokens > 0, "Need to mint at least 1 token");
    require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
    require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
    require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
    require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

    _allowList[msg.sender] -= numberOfTokens;

    for (uint256 i = 0; i < numberOfTokens; i++) {
        mintTo(msg.sender);
    }
  }

  function mintGarden(uint numberOfTokens) public payable {
    uint256 ts = totalSupply();

    require(saleIsActive, "Sale must be active to mint tokens");
    require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
    require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
    require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

    for (uint256 i = 0; i < numberOfTokens; i++) {
        mintTo(msg.sender);
    }
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}