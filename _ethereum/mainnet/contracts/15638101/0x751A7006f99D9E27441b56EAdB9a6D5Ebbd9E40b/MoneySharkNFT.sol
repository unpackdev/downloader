// SPDX-License-Identifier: MIT

//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX0NMMMMMMMMMMMMMMMMWXKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0;.lXMMMMMMMMMMMMMMWWd'c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'   :KMMMMMMMMMMMMMWNd. .l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMNx..';. ,OWMMMMMMMMMMMWWd. ''.lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//NXXXXXXXXXNWMMMNXXXXXXXXXXKo..lO0k;.'xXXXXXXXXXXWWWd..d0c.'o0XXXXXXXXXXXXXXXXXXXXXXWMWNXXXXXXXXXXXXW
//:..'''''..'dNW0:..'''''......dNX0NKc......''''..:OXd..dWNk,...''''''''''''''''''...lKx,..'''''...'oX
//' 'oxxxxx:..cd'.,oxxxxx:.  'kWMX0NMXo.  .lxxxxd;..,. .dWMMXo.,dxxxxxxxxxxxxxxxxxxl.....;dxxxxo,  cKM
//' :XMMMMMNx.  .cKMMMMMWx. ;OWMW0kKWMNx. ;KMMMMMXd'.  .dWMMMNooNMMMMMMMMMMMMMMMMMMWx. .lXMMMMXo..lXMM
//' :XMMMMMMWO,.oXMMMMMMWx':OXXXXOk0XKXXx,;KMMMMMMWKxc..dWMMMWxoXMMMMWXKKKKKKKKNWMMMWk;lXMMMMKc..dNMMM
//' :XMMMMMMMWK0NMMMMMMMWx:xKXNWMX0NMWNXKocKMMMMMMMMMNk:xWMMMWxoXMMMMKdlllllll::kWMMMWXNMMMW0:.'kWMMMM
//' :XMMMMMMMMMMMMMMMMMMWx,cokXWMX0NMWKxo;:KMMMMMMMMMMMNNMMMMWxoXMMMMMWWWWWWWWO,.xNMMMMMMMWO,.,OWMMMMM
//' :XMMMMKONMMMMW0KWMMMWx,;ooloxkkkdllol,:KMMMMWXNMMMMMMMMMMWxoXMMMMWNNNNNNNNO' .oXMMMMMNx'.:0MMMMMMM
//' :XMMMMO;cKMMNd,dWMMMWx. ;OXOdc:lx0Xx' ;KMMMMXl:0NWMMMMMMMWxoXMMMMKocc:cccc;.  .xWMMMMO' :KMMMMMMMM
//' ,OWMMMO. ;OKl..cXWMMWx.  .dNMKONWKc.  ;KMMMMX:..,lKWMMMMMWxoXMMMMWXKKKKKKKx,  .dWMMMWk. oWMMMMMMMM
//o'..:d0NO.  ..    'cxKWx.   .cKK0Xk,    ;KMMMMX:    ,kNMMMMWxoXMMMMMMMMMMMWO;   .dNNKkl' .dWMMMMMMMM
//WXkl,..;;.         ..,oc.   ..:xko.   ..;xOOkxo'    .,okOOkd::xOOOOOOOOOkxl,....'cl;..':dONMMMMMMMMM
//MMMMNOo,.      .',,,,,,,,,,cl:,;lc. .;c,,,,,c;.....;:;,,,c;.':;,,:lc,,;c,.':;,,;ll. ,xXWMMMMMMMMMMMM
//MMMMMMMN0o;,. .:l'....... .;;.  ,c. .:,     .,;,,;;,.   .:l::.  .cd,  .cc;:.  .,:..:KWMMMMMMMMMMMMMM
//MMMMMMMMMMWN0c..,;::lool'       ,l:,;l,       ';;..      ':,.  .coo;   .c:.  .:;..oXMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMWO' .cl;,'..   .'    .'''.       .:xd;.      .....  .cd;        .:,..xNMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMNl .c,.  ..',ccol.   .'''.   .:;  .lc.       :l;;c,  .'.   ..   ;c. ;0WMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMX: ,c.  .ldllc:ol.  ,l:,;l,  .lx,       ,,   ,c,,;.   ..  .od;. .,:'.'xNMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMWd..;:.  .... .oo.  ;c. .:,  .coc'    .,xl.   ...   .:d:.,;;';:'  .;;..;OWMMMMMMMMMMMMMM
//MMMMMMMMMMMMMNd'..,,,,,,,,,cl;,,c:.  ;:,,;c'':;,,;:clc;,,,,,,,,,,,cc,'.....;:.  .;,..cKWMMMMMMMMMMMM
//MMMMMMMMMMMMMMWKd:,...............   ....... ...................   .'cxKXx'.':;,,;oo' .dXMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMWNK0OO000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0o';oOXWMMMMKl.........   ,kNMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX0NMMMMMMMMMNk;,,,,,,,,,,,lKMMMMMMMMM

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract MoneySharkNFT is ERC721AQueryable, Ownable, ReentrancyGuard {

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
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
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

  function withdraw() public onlyOwner nonReentrant {
    // This will pay MoneyShark 50% of the initial sale.
    // =============================================================================
    (bool hs, ) = payable(0x986103A2C733E4943Fb006579FcB7291a3F55FA2).call{value: address(this).balance * 50 / 100}('');
    require(hs);
    // =============================================================================

    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
