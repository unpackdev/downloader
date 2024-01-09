// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*


 ▄▄·  ▄▄▄·  ▐ ▄ ·▄▄▄▄  ▪  ·▄▄▄▄       ▄▄·  ▄▄▄·  ▄▄· ▄▄▄▄▄▪       ▄▄· ▄▄▄  ▄▄▄ .▄▄▌ ▐ ▄▌
▐█ ▌▪▐█ ▀█ •█▌▐███▪ ██ ██ ██▪ ██     ▐█ ▌▪▐█ ▀█ ▐█ ▌▪•██  ██     ▐█ ▌▪▀▄ █·▀▄.▀·██· █▌▐█
██ ▄▄▄█▀▀█ ▐█▐▐▌▐█· ▐█▌▐█·▐█· ▐█▌    ██ ▄▄▄█▀▀█ ██ ▄▄ ▐█.▪▐█·    ██ ▄▄▐▀▀▄ ▐▀▀▪▄██▪▐█▐▐▌
▐███▌▐█ ▪▐▌██▐█▌██. ██ ▐█▌██. ██     ▐███▌▐█ ▪▐▌▐███▌ ▐█▌·▐█▌    ▐███▌▐█•█▌▐█▄▄▌▐█▌██▐█▌
·▀▀▀  ▀  ▀ ▀▀ █▪▀▀▀▀▀• ▀▀▀▀▀▀▀▀•     ·▀▀▀  ▀  ▀ ·▀▀▀  ▀▀▀ ▀▀▀    ·▀▀▀ .▀  ▀ ▀▀▀  ▀▀▀▀ ▀▪

                        Candid Cacti Crew | 2022  | version 7.0 | ERC 721 - No Enum

*/

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract CandidCactiCrew is ERC721, Ownable {
  using Strings for uint256;
  using ECDSA for bytes32;

  uint256 public constant MAX = 5000;
  uint256 public constant PRESALE_PRICE = 0.04 ether;
  uint256 public constant SALE_PRICE = 0.05 ether;
  uint256 public constant MAX_PER_TXN = 10;
  uint256 public constant TIMEOUT = 45;
  uint256 public tokensMinted;

  string private _contractURI = "https://api.candidcacti.world/metadata/contract.json";
  string private _tokenBaseURI = "https://api.candidcacti.world/metadata/";
  string public statsproof;
  string public scriptproof;

  address private _signerAddress;
  bool public presaleLive = false;
  bool public saleLive = false;

  constructor(address signerAddress) ERC721("Candid Cacti Crew", "CandidCactiCrew") {
    _signerAddress = signerAddress;
  }

  //**** Mint/Purchase functions ****//

  /**
   * @dev checks hash and signature
   */
  function matchAddressSigner(bytes32 hash, bytes memory signature) private view returns (bool) {
    return _signerAddress == hash.recover(signature);
  }

  /**
   * @dev generates hash
   */
  function hashTransaction(
    address sender,
    uint256 tokenQuantity,
    uint256 timeStamp
  ) private pure returns (bytes32) {
    bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(sender, tokenQuantity, timeStamp))));

    return hash;
  }

  /**
   * @dev Public Sales Buy/Mint function
   */
  function Buy(
    uint256 tokenQuantity,
    uint256 timeStamp,
    bytes memory signature
  ) external payable {
    address wallet = msg.sender;
    uint256 tokenQty = tokenQuantity;
    uint256 totalMinted = tokensMinted;

    require(saleLive, "SALE_NOT_STARTED");
    require(totalMinted + tokenQty <= MAX, "OUT_OF_STOCK");
    require(tokenQty <= MAX_PER_TXN, "EXCEED_MAX_PER_TXN");
    require(SALE_PRICE * tokenQty <= msg.value, "INSUFFICIENT_ETH");
    require(matchAddressSigner(hashTransaction(wallet, tokenQty, timeStamp), signature), "SIGNATURE_ERR");
    require(block.timestamp <= timeStamp + TIMEOUT, "TIMED_OUT");

    tokensMinted += tokenQty;

    for (uint256 i = 0; i < tokenQty; i++) {
      totalMinted++;
      _mint(wallet, totalMinted);
    }
    delete wallet;
    delete tokenQty;
    delete totalMinted;
  }

  /**
   * @dev Pre-Sale Buy/Mint function
   */
  function presaleBuy(
    uint256 tokenQuantity,
    uint256 timeStamp,
    bytes memory signature
  ) external payable {
    address wallet = msg.sender;
    uint256 tokenQty = tokenQuantity;
    uint256 totalMinted = tokensMinted;

    require(presaleLive, "PRE_SALE_NOT_ACTIVE");
    require(totalMinted + tokenQty <= MAX, "OUT_OF_STOCK");
    require(tokenQty <= MAX_PER_TXN, "EXCEED_MAX_PER_TXN");
    require(PRESALE_PRICE * tokenQty <= msg.value, "INSUFFICIENT_ETH");
    require(matchAddressSigner(hashTransaction(wallet, tokenQty, timeStamp), signature), "SIGNATURE_ERR");
    require(block.timestamp <= timeStamp + TIMEOUT, "TIMED_OUT");

    tokensMinted += tokenQty;

    for (uint256 i = 0; i < tokenQty; i++) {
      totalMinted++;
      _mint(wallet, totalMinted);
    }
    delete wallet;
    delete tokenQty;
    delete totalMinted;
  }

  /**
   * @dev gift Claim
   */

  function giftClaim(
    uint256 tokenQuantity,
    uint256 timeStamp,
    bytes memory signature
  ) external {
    address wallet = msg.sender;
    uint256 tokenQty = tokenQuantity;
    uint256 totalMinted = tokensMinted;

    require(totalMinted + tokenQty <= MAX, "OUT_OF_STOCK");
    require(matchAddressSigner(hashTransaction(wallet, tokenQty, timeStamp), signature), "SIGNATURE_ERR");
    require(block.timestamp <= timeStamp + TIMEOUT, "TIMED_OUT");

    tokensMinted += tokenQty;

    for (uint256 i = 0; i < tokenQty; i++) {
      totalMinted++;
      _mint(wallet, totalMinted);
    }
    delete wallet;
    delete tokenQty;
    delete totalMinted;
  }

  /**
   * @dev giveaways
   */
  function giveaway(address[] calldata receivers) external onlyOwner {
    uint256 totalMinted = tokensMinted;
    uint256 giftAddresses = receivers.length;

    require(totalMinted + giftAddresses <= MAX, "OUT_OF_STOCK");

    tokensMinted += giftAddresses;

    for (uint256 i = 0; i < giftAddresses; i++) {
      totalMinted++;
      _mint(receivers[i], totalMinted);
    }
    delete giftAddresses;
    delete totalMinted;
  }

  //**** Owner functions ****//

  /**
   * @dev withdraw
   */
  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  /**
   * @dev toggle Presale
   */
  function togglePresale() external onlyOwner {
    presaleLive = !presaleLive;
  }

  /**
   * @dev toggle sale
   */
  function toggleSale() external onlyOwner {
    saleLive = !saleLive;
  }

  /**
   * @dev change Signer Add 
   */
  function setSignerAddress(address signerAddress) external onlyOwner {
    _signerAddress = signerAddress;
  }

  /**
   * @dev set Provenance hash
   */
  function setProvenanceHash(string calldata hash) external onlyOwner {
    statsproof = hash;
  }

  /**
   * @dev set Meta Generator Script hash
   */
  function setScriptHash(string calldata hash) external onlyOwner {
    scriptproof = hash;
  }

  /**
   * @dev set Contract URI
   */
  function setContractURI(string calldata URI) external onlyOwner {
    _contractURI = URI;
  }

  /**
   * @dev set Base URI
   */
  function setBaseURI(string calldata URI) external onlyOwner {
    _tokenBaseURI = URI;
  }

  //**** View functions ****//
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "Cannot query non-existent token");
    string memory json = ".json";
    return string(abi.encodePacked(_tokenBaseURI, tokenId.toString(), json));
  }

  function baseURI() public view returns (string memory) {
    return _tokenBaseURI;
  }

  /**
   * @dev totalSupply()
   */
  function totalSupply() public view virtual returns (uint256) {
    return tokensMinted;
  }
}
