// SPDX-License-Identifier: MIT

//                                                                                                                     .....                            
//          .lkkOx'                                                                                                   'kXKXk.                           
//          cNWNWMx.                                                                                                  .;kWM0'                           
//         '0M0ckMNc     .'''...,;,.  .',;'.     .'''',;;,.      .',;;'.      .''''..'''. .''''.  .'''.      .,::;..    :NM0;.,;'.       ';:c:'.        
//        .dWNc :XM0'   ;KWWWXKXWMWXxd0NWMWKl.  ,0WWWWWWWWXk;  .lKNNWWWKd.    lNWWNXXNNNx.cNWWNl ,0WNWK,   ;kXWWWWN0Ol  :NMNKXWMWKl.   :ONNKKNNO:       
//        cNMNkoxXMWd.  .;OMMNd;;oXMMKo;;kWMN:  .cKMM0c,,oKMNc  'cc::l0MWo    .lKMM0loO0l..lKMMo .,xWMX;  cNMXo;,:dkkc  :NMNkc:xNMN:  lNMKo::dXMN:      
//       '0MN0OOO0NMNc    oMMO'  .kMMd   ;XMWc   .kMWl    oWMk..cx000OXMMd     .kMMo       .OMMo   :NMX; .kMWo          :NM0'  '0MWc .kMMX0000KXXl      
//      .xWWx.   .dWM0;  .dMM0;. .kMMk.  ,KMWo.  .kMWx'..;0MWo.lWMk;';OMMx.    ,OMMd..     .kMMx.  oWMXc  oWMO;. .cdo, .lNMK:. .OMWo..oWMO:'.';;'.      
//     ,0WMMNx. .oXWMWNc;ONMMWXo..kMMN0; ;KMWNx. .kMMMNKKWWXo. :XMKxxONMMNO'  cXWMMNKd.     ;KWW0xONMMWXc .lXWNK0XWNk''kNWMWXo.'0MMNk'.oXWN0O0KKc       
//     .cllll:.  ,lllll'.clllll,  ;lllc. .:lll:. .kMWOlool;.    .codocclllc.  'llllll;       .;lol::clll'   .:lddoc'  .:lllll, .;lll:.  .:ldddl;.       
//                                              'oKMWkc'                                                                                                
//                                             .dNNNNNNo                                                                                                
//                                              ........                                                                                                
     

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract AMPARUCHE is ERC721, Ownable, ReentrancyGuard {

  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    require(!whitelistClaimed[msg.sender], "Address already claimed!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    whitelistClaimed[msg.sender] = true;
    _mintLoop(msg.sender, _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
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

  address public constant xCubannerd      = 0x3B18F8Eff8e7089E42986d164CF926C61c115730;
  address public constant xRiogerz = 0x93cab57f541bFA06c6d0DC177bc2327dAb0FF5d6;
  address public constant xAisa    = 0x7c46c536308e723d9A6381496a4412ee356687BB;
  address public constant xCmondeja    = 0x18D27558F6cD5c041946966407cA4A9F4e2592c6;
  address public constant xAnna    = 0x5267E6A4C7992395Cf89f270FC5a037BdC91915B;


  function withdraw()
    public
    onlyOwner
    nonReentrant
  {
    uint total = address(this).balance;
    uint Cubannerd = total * 4 / 100;
    uint Aisa = total * 4 / 100;
    uint Cmondeja = total * 4 / 100;
    uint Anna = total * 4 / 100;
    Address.sendValue(payable(xCubannerd), Cubannerd);
    Address.sendValue(payable(xAisa), Aisa);
    Address.sendValue(payable(xCmondeja), Cmondeja);
    Address.sendValue(payable(xAnna), Anna);
    Address.sendValue(payable(xRiogerz), address(this).balance);
  }


  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
