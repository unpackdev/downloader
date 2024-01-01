// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";


contract WomanSeekersNewDawn is ERC721AQueryable,  Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  bytes32 public freeMerkleRoot;

  address public lastWarGame;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  mapping(address => uint256) freeMintClaimed;


  uint256 public freeMintLimit = 333;
  uint256 public freeMintLimitPerUser = 3;
  uint256 public WlLimit = 450;

  bool public paused = false;
  bool public whitelistMintEnabled = true;
  bool public revealed = true;

 constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
    setUriPrefix("ipfs://QmXnJvCDMn1uwjRM2WhNZzmk3fQmuNep58VcDW9CR1c6vi/");
  }

  function setWlLimit(uint _value) public onlyOwner{
    WlLimit = _value;
  }
   
  
  function setFreeMintLimit(uint _value) public onlyOwner{
    freeMintLimit = _value;
  }

   function setFreeMintLimitPerUser(uint _value) public onlyOwner{
    freeMintLimitPerUser = _value;
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
    require(totalSupply() + _mintAmount <= WlLimit, "Whitelist sale is over"); 
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    _safeMint(_msgSender(), _mintAmount);
  }




  function freeMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(totalSupply() + _mintAmount <= freeMintLimit, "freeMint is over"); 
    require(freeMintClaimed[msg.sender] + _mintAmount <= freeMintLimitPerUser, "freeMintLimitPerUser exceed"); 

    freeMintClaimed[msg.sender] += _mintAmount;
  
    _safeMint(_msgSender(), _mintAmount);
  }

 


    function setFreeMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    freeMerkleRoot = _merkleRoot;
  }



  uint discountRate = 3;



    function setDiscountRate(uint256 _value) public onlyOwner {
    discountRate = _value;
  }


  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');


    uint discount = _mintAmount / discountRate;
        
    require(msg.value == cost * (_mintAmount - discount), 'Insufficient funds!');


    _safeMint(_msgSender(), _mintAmount);
  }
  

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  
  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721Metadata) returns (string memory) {
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

  function withdraw() public onlyOwner nonReentrant {
  
    (bool os, ) = payable(0x41ab17408FB62762a1339aeABebE102691c27c25).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

   function setNotTransferable(uint _tokenId, bool _value) public  {
        notTransferable[_tokenId] = _value;
    }

     function viewNotTransferable(uint256 _tokenId) public view returns (bool) {
      return notTransferable[_tokenId];
     }

        uint256 public gameDiscount = 30;
        function setDiscount(uint _value) public onlyOwner {
          gameDiscount = _value;

        }
         function mintFromGame(uint256 _mintAmount) public mintCompliance(_mintAmount)  {
          require(msg.sender == lastWarGame, "not game address tx sender");
           _safeMint(tx.origin, _mintAmount);

         }

      function setlastWarGame(address _lastWarGame) public onlyOwner {
        lastWarGame = _lastWarGame;
      }





 }