// SPDX-License-Identifier: UNLICENCED

pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";

import "./Ownable.sol";

import "./ECDSA.sol";
import "./Address.sol";

contract BabyTaiga is ERC721Enumerable, Ownable {

  bool public isWhitelistMintingOpened;
  bool public isPublicMintingOpened;
  uint8 public constant MAXFREEMINT = 2;
  uint16 public maxPerAddress = 3;
  uint16 public constant MAXCOLLECTIONSIZE = 5555;
  address public whiteListSigner;

  uint96 public price = 0.1 * 10**18;
  address public freeMintSigner;

  string public baseURI;

  mapping(address => uint16) private freeMints;
  mapping(address => uint16) private mints;

  event WhitelistMintFlipped(bool wlMint);
  event PublicMintFlipped(bool publicMint);
  event Freeminted(address to, uint16 count);
  event PriceUpdated(uint96 newPrice);
  event Withdrawn();
  event MaxPerAddressUpdate(uint16 newMax);
  event WhiteListSignerUpdated(address signer);
  event FreeMintSignerUpdated(address signer);
  event BaseURIUpdated(string newURI);

  constructor(
    address _whiteListSigner,
    address _freeMintSigner,
    address owner,
    string memory _uri) ERC721(
    "Baby Taigas",
    "BABYTAIGA") {
      require(owner != address(0), "Please provide a valid owner");
      require(_whiteListSigner != address(0), "Please provide a valid whitelist signer");
      require(_freeMintSigner != address(0), "Please provide a valid freemint signer");
      require(_whiteListSigner != _freeMintSigner, "I should use 2 different keys");
      whiteListSigner = _whiteListSigner;
      freeMintSigner = _freeMintSigner;
      baseURI = _uri;
      transferOwnership(owner);
  }

  //
  // Public Access
  //

  function mint(uint16 count) external payable {
    require(msg.value >= count * price,"Insufficiant amount sent");
    require(isPublicMintingOpened, "Public minting is closed");

    _batchMint(msg.sender, count);
  }

  function wlMint(uint16 count, bytes memory signedMessage) external payable {
    require(msg.value >= count * price,"Insufficiant amount sent");
    require(isWhitelistMintingOpened, "Whitelist minting is closed");
    require(getSigner(signedMessage) == whiteListSigner, "Address not approved");

    _batchMint(msg.sender, count);
  }

  function freeMint(uint16 count, bytes memory signedMessage) external {
    require(getSigner(signedMessage) == freeMintSigner, "Address not approved");

    require(freeMints[msg.sender] + count <= MAXFREEMINT, "Freemint maximum excedeed");
    unchecked {
      freeMints[msg.sender] += count;
    }

    _batchMint(msg.sender, count);
    emit Freeminted(msg.sender, count);
  }

  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(owner);
    uint256[] memory result = new uint256[](tokenCount);
    for (uint256 index; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(owner, index);
    }
    return result;
  }

  //
  // Owner Access
  //

  function flipWhiteListMint() external onlyOwner{
    isWhitelistMintingOpened = !isWhitelistMintingOpened;
    emit WhitelistMintFlipped(isWhitelistMintingOpened);
  }

  function flipPublicMint() external onlyOwner {
    isPublicMintingOpened = !isPublicMintingOpened;
    emit PublicMintFlipped(isPublicMintingOpened);
  }

  function setPrice(uint96 newPrice) external onlyOwner{
    price = newPrice;
    emit PriceUpdated(newPrice);
  }

  function updateMaxPerAddress(uint16 newMax) external onlyOwner {
    maxPerAddress = newMax;
    emit MaxPerAddressUpdate(newMax);
  }

  function ownerMint(address to, uint16 count) external onlyOwner {
    _batchMint(to, count);
  }

  function updateWhitelistSigner(address newAddress) external onlyOwner {
    require(newAddress != freeMintSigner, "whiteListSigner and freeMintSigner must be different");
    whiteListSigner = newAddress;
    emit WhiteListSignerUpdated(newAddress);
  }

  function updateFreeMintSigner(address newAddress) external onlyOwner {
    require(newAddress != whiteListSigner, "whiteListSigner and freeMintSigner must be different");
    freeMintSigner = newAddress;
    emit FreeMintSignerUpdated(newAddress);
  }

  function withdraw() external onlyOwner{
    Address.sendValue(payable(owner()), address(this).balance);
    emit Withdrawn();
  }

  function setBaseURI(string calldata _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
    emit BaseURIUpdated(_newBaseURI);
  }

  //
  // Internal functions
  //

  function _batchMint(address to,uint16 count) private {
    require(totalSupply() + count <= MAXCOLLECTIONSIZE, "Collection is sold out");
    require(mints[msg.sender] + count <= maxPerAddress, "Maximum limit reached on this address");
    unchecked {
      mints[msg.sender] += count;
    }

    for(uint i; i<count; i++) {
      _mint(to, totalSupply()+1);
    }
  }

  function getSigner(bytes memory signedMessage) view private returns (address signer) {
    bytes memory bMessage = abi.encode(msg.sender);
    bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", bMessage));
    signer = ECDSA.recover(hash, signedMessage);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
}