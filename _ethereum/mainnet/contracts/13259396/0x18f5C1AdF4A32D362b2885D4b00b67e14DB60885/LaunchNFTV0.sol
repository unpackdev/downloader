// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SignatureCheckerUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./LaunchNFTStorageV0.sol";
import "./console.sol";

contract LaunchNFTV0 is
  ERC721Upgradeable,
  OwnableUpgradeable,
  LaunchNFTStorageV0
{
  using ECDSAUpgradeable for bytes32;
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using SignatureCheckerUpgradeable for address;

  // reserve batch size
  uint256 public constant reserveBatchNum = 30;

  function __LaunchNFT_init(
    string memory _name,
    string memory _symbol,
    string memory _uri,
    uint256 _price,
    uint256 _whitelistPrice,
    uint256 _maxPurchaseNum,
    uint256 _maxSupply,
    uint256 _reserveNum,
    address _owner,
    address _signer
  ) public initializer {
    __ERC721_init(_name, _symbol);
    __Ownable_init_unchained();
    __LaunchNFT_init_unchained(_uri, _price, _whitelistPrice, _maxPurchaseNum, _maxSupply, _reserveNum, _owner, _signer);
  }

  function __LaunchNFT_init_unchained(
    string memory _uri,
    uint256 _price,
    uint256 _whitelistPrice,
    uint256 _maxPurchaseNum,
    uint256 _maxSupply,
    uint256 _reserveNum,
    address _owner,
    address _signer
  ) public initializer {
    baseURI = _uri;
    price = _price;
    whitelistPrice = _whitelistPrice;
    maxPurchaseNum = _maxPurchaseNum;
    maxSupply = _maxSupply;
    reserveNum = _reserveNum;
    whitelistSigner = _signer;
    transferOwnership(_owner);
  }

  /**
   * @dev Override _baseURI, so that tokenURI could use it as base.
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /**
   * @dev withdraw eth paid in mint and presale
   */
  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /**
   * @dev reserve some NFTs aside
   */
  function reserve() public onlyOwner {
    uint256 toReserve = reserveNum - mintedReserveNum;
    uint256 batch = reserveBatchNum < toReserve ? reserveBatchNum : toReserve;
    uint256 beforeReserve = id.current();
    require(beforeReserve + batch <= maxSupply, "Reserving would exceed max supply");
    for (uint256 i = 0; i < batch; i++) {
      _mint();
    }
    uint256 afterReserve = id.current();
    mintedReserveNum += afterReserve - beforeReserve;
  }

  function flipMintingState() external onlyOwner {
    isMintingActive = !isMintingActive;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setAdmin(address _admin) external onlyOwner {
    transferOwnership(_admin);
  }

  function setSigner(address _signer) external onlyOwner {
    whitelistSigner = _signer;
  }

  /**
   * @dev mint multiple
   */
  function mint(uint256 _num) external payable {
    require(isMintingActive, "Minting must be active");
    require(_num <= maxPurchaseNum, "Cannot mint this many at a time");
    require(id.current() + _num <= maxSupply, "Minting would exceed max supply");
    require(price * _num <= msg.value, "Ether value sent is not correct");

    for(uint i = 0; i < _num; i++) {
      _mint();
    }
  }

  /**
   * @dev whiltelist claim
   */
  function whitelistMint(uint256[] calldata _whitelistIDs, bytes[] calldata _signatures) external payable {
    require(_whitelistIDs.length == _signatures.length, "Batch size mismatch");

    require(id.current() + _whitelistIDs.length <= maxSupply, "Minting would exceed max supply");
    require(whitelistPrice * _whitelistIDs.length <= msg.value, "Ether value sent is not correct");

    for (uint i = 0; i < _whitelistIDs.length; i++) {
      require(!hasMinted[_whitelistIDs[i]], "Whitelist already claimed");
      require(_verify(getMessageHash(_msgSender(), _whitelistIDs[i]), _signatures[i]), "Invalid Signature");
      hasMinted[_whitelistIDs[i]] = true;
      _mint();
    }
  }

  /**
   * @dev set base URI
   */
  function setBaseURI(string memory _uri) public onlyOwner {
    baseURI = _uri;
  }


  function _nextId() internal returns (uint256) {
    id.increment();
    return id.current();
  }

  function _mint() internal {
    if (id.current() < maxSupply) {
      uint256 id = _nextId();
      _safeMint(_msgSender(), id);
    }
  }

  function getMessageHash(
    address _account,
    uint256 _whitelistID
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_account, _whitelistID));
  }

  function _verify(bytes32 hash, bytes calldata signature) internal view returns (bool) {
    console.logBytes32(hash);
    return whitelistSigner.isValidSignatureNow(hash.toEthSignedMessageHash(), signature);
  }
}
