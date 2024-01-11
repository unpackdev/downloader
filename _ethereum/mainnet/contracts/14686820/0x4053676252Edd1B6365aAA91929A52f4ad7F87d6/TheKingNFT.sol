// SPDX-License-Identifier: MIT



//  ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄       ▄    ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄        ▄  ▄▄▄▄▄▄▄▄▄▄▄       ▄▄        ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
// ▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌     ▐░▌  ▐░▌▐░░░░░░░░░░░▌▐░░▌      ▐░▌▐░░░░░░░░░░░▌     ▐░░▌      ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
//  ▀▀▀▀█░█▀▀▀▀ ▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀▀▀      ▐░▌ ▐░▌  ▀▀▀▀█░█▀▀▀▀ ▐░▌░▌     ▐░▌▐░█▀▀▀▀▀▀▀▀▀      ▐░▌░▌     ▐░▌▐░█▀▀▀▀▀▀▀▀▀  ▀▀▀▀█░█▀▀▀▀ 
//      ▐░▌     ▐░▌       ▐░▌▐░▌               ▐░▌▐░▌       ▐░▌     ▐░▌▐░▌    ▐░▌▐░▌               ▐░▌▐░▌    ▐░▌▐░▌               ▐░▌     
//      ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄      ▐░▌░▌        ▐░▌     ▐░▌ ▐░▌   ▐░▌▐░▌ ▄▄▄▄▄▄▄▄      ▐░▌ ▐░▌   ▐░▌▐░█▄▄▄▄▄▄▄▄▄      ▐░▌     
//      ▐░▌     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░░▌         ▐░▌     ▐░▌  ▐░▌  ▐░▌▐░▌▐░░░░░░░░▌     ▐░▌  ▐░▌  ▐░▌▐░░░░░░░░░░░▌     ▐░▌     
//      ▐░▌     ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀      ▐░▌░▌        ▐░▌     ▐░▌   ▐░▌ ▐░▌▐░▌ ▀▀▀▀▀▀█░▌     ▐░▌   ▐░▌ ▐░▌▐░█▀▀▀▀▀▀▀▀▀      ▐░▌     
//      ▐░▌     ▐░▌       ▐░▌▐░▌               ▐░▌▐░▌       ▐░▌     ▐░▌    ▐░▌▐░▌▐░▌       ▐░▌     ▐░▌    ▐░▌▐░▌▐░▌               ▐░▌     
//      ▐░▌     ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄      ▐░▌ ▐░▌  ▄▄▄▄█░█▄▄▄▄ ▐░▌     ▐░▐░▌▐░█▄▄▄▄▄▄▄█░▌     ▐░▌     ▐░▐░▌▐░▌               ▐░▌     
//      ▐░▌     ▐░▌       ▐░▌▐░░░░░░░░░░░▌     ▐░▌  ▐░▌▐░░░░░░░░░░░▌▐░▌      ▐░░▌▐░░░░░░░░░░░▌     ▐░▌      ▐░░▌▐░▌               ▐░▌     
//       ▀       ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀    ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀        ▀▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀        ▀▀  ▀                 ▀      
                                                                                                                                       










pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";



import "./Ownable.sol";

contract Delegated is Ownable{
  mapping(address => bool) internal _delegates;

  constructor(){
    _delegates[owner()] = true;
  }

  modifier onlyDelegates {
    require(_delegates[msg.sender], "Invalid delegate" );
    _;
  }

  //onlyOwner
  function isDelegate( address addr ) external view onlyOwner returns ( bool ){
    return _delegates[addr];
  }

  function setDelegate( address addr, bool isDelegate_ ) external onlyOwner{
    _delegates[addr] = isDelegate_;
  }

  function transferOwnership(address newOwner) public virtual override onlyOwner {
    _delegates[newOwner] = true;
    super.transferOwnership( newOwner );
  }
}

contract TheKingNFT is ERC721A, Delegated , ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  string public uriPrefix = 'ipfs://QmdDQcjVQMd94UoNX33xHiEjXhanbToZJnKaAnPNjScuvX/';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri = "https://mint.ronniecolemannft.com/hide.json";
  uint256 public cost = .1 ether;
  uint256 public maxSupply = 1410;
  uint256 public maxMintAmountPerTx = 5;
  uint256 public expenseAmount = 10 ether;


  bool private expensed = false;
  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  event PaymentReleased(address to, uint256 amount);
  event nftMinted(address to, uint256 amount);
  address public cardAddress;
  address public ronnie1 = 0xb50E6500f6964b729D785173adFF96398120f66C;
  address public ronnie2 = 0x8130657CAFB14d90ccf11DA570B33FD79Bd0e5d4;
  address public ronnie3 = 0x950528c87829e54e9CF5689E444bee708580b53E; 
  address public nftBrands = 0xE19aBD85A10Aa5321796506c2A80c3BC35eD8B00;


  
  constructor(
 

  ) ERC721A("The King NFT Series", "KING") {
    setHiddenMetadataUri(hiddenMetadataUri);
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
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    _safeMint(_msgSender(), _mintAmount);
  }
  

  function preSaleMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    _safeMint(_msgSender(), _mintAmount);
  }



  function mintCard(uint256 _mintAmount, address _receiver) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
          require(!paused, 'The contract is paused!');
           require(msg.sender == cardAddress, "This function is for cards only");
    _safeMint(_receiver, _mintAmount);
    emit nftMinted(_receiver, _mintAmount);
  }

  function web3payMint(uint256 _mintAmount, address _receiver) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
          require(!paused, 'The contract is paused!');
    _safeMint(_receiver, _mintAmount);
    emit nftMinted(_receiver, _mintAmount);
  }



  function devMint(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
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
  function setCardAddress(address _cardAddress) public onlyOwner {
    cardAddress = _cardAddress;
  } 

  function setCost(uint256 _cost) public onlyDelegates {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyDelegates {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyDelegates {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyDelegates {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyDelegates {
    uriSuffix = _uriSuffix;
  }

  function pause() public onlyDelegates {
    paused = true;
  }


  function live() public onlyDelegates {
    paused = false;
  }



  function setMerkleRoot(bytes32 _merkleRoot) public onlyDelegates {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyDelegates {
    whitelistMintEnabled = _state;
  }

 function getBalance() external view returns (uint256) {
    return address(this).balance;
  }
  
function depositETH() public payable {
}

function setExpenseAmount(uint256 _amount) external onlyDelegates {
  require(_amount <= 10100000000000000000, "too much!" );
  expenseAmount  = _amount;

}
  function withdrawExpenses() public onlyDelegates nonReentrant {
     /// can only be called once 
       
        require(!expensed, "can only expense one time!");
        require(address(this).balance >= 10 ether , "not enough yet...");
        
          (bool nftb, ) = payable(0xE19aBD85A10Aa5321796506c2A80c3BC35eD8B00).call{value: expenseAmount}('');
          require(nftb);
          expensed = true;
            emit PaymentReleased(nftBrands, expenseAmount);

  }

  function withdraw() public onlyDelegates nonReentrant {

    uint256 wallet1 =  address(this).balance * 574 /  1000; //  Wallet 1: 57.4%
    uint256 wallet2 =  address(this).balance * 205 /  1000; // Wallet 2:20.5%
    uint256 wallet3 =  address(this).balance * 41 /  1000; // Wallet 3:4.1%
    uint256 wallet4 =  address(this).balance * 180 /  1000; // nftb : 18%


      (bool wa, ) = payable(ronnie1).call{value: wallet1}('');
      require(wa);
      (bool wd, ) = payable(nftBrands).call{value: wallet4}('');
      require(wd);
      (bool wb, ) = payable(ronnie2).call{value:wallet2}('');
      require(wb);
      (bool wc, ) = payable(ronnie3).call{value: wallet3}('');
      require(wc);


      emit PaymentReleased(ronnie1, wallet1);
      emit PaymentReleased(ronnie2, wallet2);
      emit PaymentReleased(ronnie3, wallet3);
      emit PaymentReleased(nftBrands, wallet4);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}