// SPDX-License-Identifier: MIT
//                                                                                 
//                 &BB#&                                                           
//                P!7!!!?5#                                #GP5G                   
//                ?J555?!~!?G                          &GJ7!7??7#                  
//               &7Y5PBBGY!~~7P                      GJ!~7YGB557P                  
//                7J5PBBBBGJ!~~?B  #BBBGGGGGBGB#& &P7~~75BBBB55?P                  
//                J755GBBBBBP7!~!?7!!~!JJJJJ?~!!!?7~~!YGBBBBG557B                  
//                G~J55BBBBBBG!!!~!!!!!!YJJY7!!!!!!!7PBBBBBB55J7                   
//                 J~J55GBBBP7!!!!!!!!!!JJJY7!!!!!!!7GBBBBBP5Y!G                   
//                 &?~?55PY?!!!!!!!!!!!!JJJY7!!!!!!!!!JPBBP5Y!J                    
//                   Y!!7!~!!!!!!!!!!!!!JJJY7!!!!!!!!!~!?JJ?!?&                    
//                   #7~!!!!!!!!!!~~~!!!JJJY!!!~~^~~!!!!!~!!!#                     
//                  B7!!!!!!!!^:.     :!JJJY7^. ... .:^!!!!!!Y                     
//                 &?!!!!!~^.  .^!77!^ :JJJY7 :?5PP5?~. :!!!!~P                    
//                 5!!!!^.  :!YGBBBBBBJ.JJJ5!!GBBBBBBBP?^ :~!!7&                   
//                 ~~~:. .^JGBBBBB###BBJJJJYYBBB###BBBBBBJ^ :~!?&                  
//                #... .~5BBBBBBB& #~5#GJJJJYB#5~# &BBBBBBG?. . 5                  
//                P  .!5BBBBBBBBBB&&BB#Y?JJY75BBB&&BBBBBBBBBP~  ~                  
//                Y !5BBBBBBBBBBBBBBBBP!?JJY7!PBBBBBBBBBBBBBBBJ..#                 
//                G5BBBBBBBBBBBBBBBBBP!~JJJY7~!5BBBBBBBBBBBBBBB5^B                 
//                  &###BBBBBBBBBBBBJ!!!JJJY7!!!JGBBBBBBBBBBBBB##                  
//                         B55PGGBG?~!!~JJJJ7~!!~!5PP55YYJ5B                       
//                      #P?!!!!7?J?~!!7JPPPPP?!!!~7J7!!!!!!!?5#                    
//                   &GJ!~~!!!!!!7?77!G&&&&&&&J!77?7!!!!!!!!!~!?G&                 
//                 #57~~!!!!!!!!!!!7?7?J5PPPY?!7777!!!!!!!!!!!!~~75&               
//               #J!~!!!!!!!!!!!7!~^:....... ....:^~!7!!!!!!!!!!!!~7P              
//              5!~!!!!!!!!!!77!^:..................:^!7!!!!!!!!!!!!~?#            
//            &?~!!!!!!!!!!!7~^........................^!7!!!!!!!!!!!~!B           
//            J~!!!!!!!!!!7!^:..........................:^7!!!!!!!!!!!~!#          
//           P!!77777777!!?~^::::::::::::::::::::::::::::^~?!7777777777!Y
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract RaccoonRoyale is ERC721A, Ownable, RoyaltiesV2Impl, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  // Ukraine gets 5% from the the first resale, 2% from the next resale
  // then 1% for the third resale
  address UkraineDonations = address(0x165CD37b4C644C2921454429E7F9358d18A45e14);
  uint96 minterRoyaltyRate = 300; // 3%
  uint96 flipperRoyaltyRate = 100; // 1%
  mapping(uint256 => address)  minters;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  } 

  function _mint(address to, uint256 quantity, bytes memory _data, bool safe) internal override {    
    if (to == address(0)) revert MintToZeroAddress();
    if (quantity == 0) revert MintZeroQuantity();

    uint256 startTokenId = _currentIndex; 
    uint256 updatedIndex = startTokenId;
    uint256 end = updatedIndex + quantity;

    LibPart.Part[] memory _royalties;

    for(uint i = updatedIndex; i < end; i ++){
      // initialize royalties so the first round of royalties goes to UkraineDonations
      _royalties = new LibPart.Part[](3);
      _royalties[0].value = minterRoyaltyRate;
      _royalties[0].account = payable(UkraineDonations); 
      _royalties[1].value = flipperRoyaltyRate;
      _royalties[1].account = payable(UkraineDonations); 
      _royalties[2].value = flipperRoyaltyRate;
      _royalties[2].account = payable(UkraineDonations); 

      minters[i] = msg.sender;

      _saveRoyalties(i, _royalties);

      updatedIndex++;          
      }
    super._mint(to, quantity, _data, safe);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }
  // Supports royalties for IERC2981 and Rarible
  function supportsInterface(bytes4 interfaceId)public view virtual override(ERC721A) returns(bool) {
    if(interfaceId == 0xcad96cca)
      {return true;}

    if(interfaceId == 0x2a55205a)
      {return true;}

    return super.supportsInterface(interfaceId);        
  }
  
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  } 
  // override the transfer functions so they can shift the royalties
  function transferFrom(address from,address to,uint256 tokenId) public override{  
    super.transferFrom(from, to, tokenId);
    shiftRoyalties(tokenId, to);
  }
  function safeTransferFrom(address from,address to,uint256 tokenId) public override{  
    super.safeTransferFrom(from, to, tokenId);
    shiftRoyalties(tokenId, to);
  }
  function safeTransferFrom(address from,address to,uint256 tokenId,bytes memory _data) public override{  
    super.safeTransferFrom(from, to, tokenId,_data);
    shiftRoyalties(tokenId, to);
  }

  // Now with Raccoon Royalties!
  function shiftRoyalties(uint256 _tokenId, address _to)internal{
    // don't shift royalties if transfering to owner
    if(_msgSender() != _to){
      LibPart.Part [] memory _royalties = this.getRaribleV2Royalties(_tokenId);
      // after first sale...
      if(_royalties[0].account != minters[_tokenId]){
        // ... minter gets the prime spot (index 0)
        royalties[_tokenId][0].account = payable(minters[_tokenId]);
      }
      else{
        // after every other sale...
        // ... minter stays in index 0, index 2 gets address from index 1
        royalties[_tokenId][2].account = _royalties[1].account;
        // ... then index 1 gets _to address
        royalties[_tokenId][1].account = payable(_msgSender());
      }
    }
  }
}
