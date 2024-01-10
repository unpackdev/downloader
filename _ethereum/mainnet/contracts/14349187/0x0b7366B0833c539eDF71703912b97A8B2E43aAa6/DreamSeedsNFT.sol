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
//                   (_  )  dream seeds        ` __.:'          
//                                         
// --..,___.--,--'`,---..-.--+--.,,-,,..._.--..-._.-a:f--.
//
// by @eddietree

pragma solidity ^0.8.0;

import "./ERC721TradableBurnable.sol";
import "./Base64.sol";

contract DreamSeedsNFT is ERC721TradableBurnable {

  uint256 public constant MAX_SUPPLY = 1300;
  uint256 public constant PRICE_PER_TOKEN = 0.04 ether;

  // reveal
  bool public isRevealed = false;
  uint256 public maxPublicMintPerTransaction = 4;
  string private _prerevealMetaURI = "https://gateway.pinata.cloud/ipfs/QmPJN5t944PSZK3vLeff8EP2za2bgHd7eafs5U6kbjCmCt";
  string private _revealedMetaURI = "https://gateway.pinata.cloud/ipfs/QmRA71NveXF5EFUSds873WqxkVuT8HvvATgz65ev3ea9d5/";
  
  // sale states
  bool public saleIsActive = false;
  bool public presaleIsActive = false;
  mapping(address => uint8) private _allowList; // for presale minting

  // burnable -- used when minting gardeners or landscapes
  mapping(address => bool) private _allowListBurn;
  bool public dreamSeedsBurnableThruAllowlist = true;

  constructor(address _proxyRegistryAddress) ERC721TradableBurnable("Dream Seeds NFT", "DREAMSEED", _proxyRegistryAddress) {  
  }

  function setSaleState(bool newState) external onlyOwner {
      saleIsActive = newState;
  }

  function setMaxPublicMintPerTransaction(uint256 newState) external onlyOwner {
      maxPublicMintPerTransaction = newState;
  }

  function setPresaleState(bool newState) external onlyOwner {
      presaleIsActive = newState;
  }

  function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
      for (uint256 i = 0; i < addresses.length; i++) {
          _allowList[addresses[i]] = numAllowedToMint;
      }
  }

  function setAllowListBurn(address[] calldata addresses, bool allowBurn) external onlyOwner {
      for (uint256 i = 0; i < addresses.length; i++) {
          _allowListBurn[addresses[i]] = allowBurn;
      }
  }

  function allowListNumAvailableToMint(address addr) external view returns (uint8) {
      return _allowList[addr];
  }

  function allowListBurn(address addr) external view returns (bool) {
      return _allowListBurn[addr];
  }

  function revealAll(bool state) external onlyOwner {
      isRevealed = state;
  }

  ///////////////////// URI
  function setPreRevealURI(string memory _value) external onlyOwner {
    _prerevealMetaURI = _value;
  }

  function setRevealedURI(string memory _value) external onlyOwner {
    _revealedMetaURI = _value;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    require(_tokenId >= 1 && _tokenId <= MAX_SUPPLY, "Not valid token range");

    if (!isRevealed) { // prereveal
      string memory json = Base64.encode(
          bytes(string(
              abi.encodePacked(
                  '{"name": ', '"Dream Seed #',Strings.toString(_tokenId),'",',
                  '"description": "Inside the seed lingers a world of possibility, endless beating hearts of regenerative dreams...",',
                  '"attributes":[{"trait_type":"Status", "value":"Unrevealed"}],',
                  '"image": "', _prerevealMetaURI, '"}' 
              )
          ))
      );
      return string(abi.encodePacked('data:application/json;base64,', json));
    }  else { // revealed
      return string(abi.encodePacked(_revealedMetaURI, Strings.toString(_tokenId), ".json"));
    }
  }

  ///////////////  mint
  function reserveSeed(uint numberOfTokens) external onlyOwner {
    uint256 ts = totalSupply();
    require(ts + numberOfTokens <= MAX_SUPPLY, "Mint would exceed max tokens");

    for (uint256 i = 0; i < numberOfTokens; i++) {
      mintTo(msg.sender);
    }
  }

  function reserveSeedGift(uint numberOfTokens, address addr) external onlyOwner {
    uint256 ts = totalSupply();
    require(ts + numberOfTokens <= MAX_SUPPLY, "Mint would exceed max tokens");

    for (uint256 i = 0; i < numberOfTokens; i++) {
      mintTo(addr);
    }
  }

  function mintSeedAllowlist(uint8 numberOfTokens) external payable {
    uint256 ts = totalSupply();

    require(presaleIsActive, "Presale not active yet!");
    require(numberOfTokens > 0, "Need to mint at least 1 token");
    require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
    require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
    require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

    _allowList[msg.sender] -= numberOfTokens;

    for (uint256 i = 0; i < numberOfTokens; i++) {
        mintTo(msg.sender);
    }
  }

  function mintSeed(uint numberOfTokens) external payable {
    uint256 ts = totalSupply();

    require(saleIsActive, "Sale must be active to mint tokens");
    require(numberOfTokens <= maxPublicMintPerTransaction, "Exceeded max token purchase");
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

  // used externally for phase 2 minting of characters + landscapes
  function burnDreamSeed(uint256 tokenId) external {
    require(dreamSeedsBurnableThruAllowlist == true, "unable to burn");
    require(tokenId >= 1 && tokenId <= MAX_SUPPLY, "Not valid token range");
    require(_allowListBurn[msg.sender], "ERC721Burnable: caller is not owner nor approved");

    _burn(tokenId);
  }

  // will disable burning mechanics once phase 2 is complete
  function permanentlyDisableAllowlistBurn() external onlyOwner {
      dreamSeedsBurnableThruAllowlist = false;
  }
}