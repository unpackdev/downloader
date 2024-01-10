// SPDX-License-Identifier: MIT
/*
 _ .-') _                            _ .-') _             _  .-')    ('-.       .-') _  .-')    
( (  OO) )                          ( (  OO) )           ( \( -O ) _(  OO)     ( OO ) )( OO ).  
 \     .'_  .-'),-----.  .-'),-----. \     .'_    ,------.,------.(,------.,--./ ,--,'(_)---\_) 
 ,`'--..._)( OO'  .-.  '( OO'  .-.  ',`'--..._)('-| _.---'|   /`. '|  .---'|   \ |  |\/    _ |  
 |  |  \  '/   |  | |  |/   |  | |  ||  |  \  '(OO|(_\    |  /  | ||  |    |    \|  | )  :` `.  
 |  |   ' |\_) |  |\|  |\_) |  |\|  ||  |   ' |/  |  '--. |  |_.' (|  '--. |  .     |/ '..`''.) 
 |  |   / :  \ |  | |  |  \ |  | |  ||  |   / :\_)|  .--' |  .  '.'|  .--' |  |\    | .-._)   \ 
 |  '--'  /   `'  '-'  '   `'  '-'  '|  '--'  /  \|  |_)  |  |\  \ |  `---.|  | \   | \       / 
 `-------'      `-----'      `-----' `-------'    `--'    `--' '--'`------'`--'  `--'  `-----'  
*/
//We look forward to seeing you on discord, twitter, the metaverse and hopefully IRL!//

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract DoodFrens is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public frenlistClaimed;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  bool public paused = true;
  bool public frenlistMintEnabled = false;
  bool public revealed = false;

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
    ownerMint(10);
  }

  address payable public addr1 = payable(0xE57d07AB12Af84c88Ebc547ce9034fD4B02738c8);   //Fren1
  address payable public addr2 = payable(0x55339Bd437EAd8fd454640d5CE1Bee59Bdf748e9);   //Fren2
  address payable public addr3 = payable(0x535158f9F969880C4A0C02758Ef04ad22aCcF14C);   //Fren3

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

function ownerMint(uint256 _mintAmount) internal onlyOwner{
  _safeMint(_msgSender(), _mintAmount);
 }

  function frenlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify frenlist requirements

    require(frenlistMintEnabled, 'The frenlist sale is not enabled!');
    require(!frenlistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    frenlistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) external mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) external view returns (uint256[] memory) {
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

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) external onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) external onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setFrenlistMintEnabled(bool _state) external onlyOwner {
    frenlistMintEnabled = _state;
  }

    function setAddr(address _addr1, address _addr2, address _addr3) external onlyOwner{
    require(_addr1 != address(0) && _addr2 != address(0) && _addr3 != address(0), "DF");
    addr1 = payable(_addr1);
    addr2 = payable(_addr2);
    addr3 = payable(_addr3);
  }
  // Withdraw function
  function withdraw()
    external
    onlyOwner
  {
    require(address(this).balance != 0, "Balance is zero");
    uint balance = address(this).balance;
    payable(addr1).transfer(balance*2/100);
    payable(addr2).transfer(balance*20/100);
    payable(addr3).transfer(address(this).balance);
  }
  
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
