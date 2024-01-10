// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

contract RoyalFoxChamber is EIP712, ERC721Enumerable, Ownable {
  using Strings for uint256;

  uint256 public constant S1_TOTAL = 7777;
  uint256 public constant S1_REWARD = 10;
  uint256 public constant S1_GIFT_PRIZES = 67;
  uint256 public constant PRESALE_PRICE = 0.069 ether;
  uint256 public constant PUBLIC_PRICE = 0.0888 ether;

  bytes32 public constant SEC_TYPEHASH =
    keccak256("Sec(address buyer,uint256 max)");

  // States
  uint256 public saleState = 0; // 0 = NOT LIVE, 1 = PRESALE, 2 = PUBLIC SALE
  uint256 public giftCount = 0;
  address public signerAddress;

  // URIs
  string private _contractMetadataURI;
  string private _baseTokenURI;

  // Keep track of purchases
  mapping(address => uint256) public purchaseCount;

  constructor(address _signerAddress)
    ERC721("Royal Fox Chamber", "RFC")
    EIP712("RFC", "1.0.0")
  {
    signerAddress = _signerAddress;
  }

  /**
   * Main minting function
   */
  function buy(
    uint256 count,
    uint256 max,
    bytes memory sig
  ) external payable {
    require(saleState != 0, "Sale not live");
    require(totalSupply() + count <= S1_TOTAL, "Count exceeds supply");
    require(purchaseCount[msg.sender] + count <= max, "Exceeded qty allowed");
    require(getPrice() * count <= msg.value, "Insufficient eth");
    require(_isValidSignature(msg.sender, max, sig), "Invalid sig");

    purchaseCount[msg.sender] += count;
    for (uint256 i = 0; i < count; i++) {
      _safeMint(msg.sender, totalSupply() + 1);
    }
  }

  /**
   * To mint gifts and rewards before sale starts.
   */
  function reserveMint(address[] calldata receivers) external onlyOwner {
    uint256 count = receivers.length;
    require(totalSupply() + count <= S1_TOTAL, "Count exceeds supply");
    require(
      giftCount + count <= S1_REWARD + S1_GIFT_PRIZES,
      "All gifts minted"
    );

    for (uint256 i = 0; i < count; i++) {
      _safeMint(receivers[i], totalSupply() + 1);
    }
    giftCount += count;
  }

  function getPrice() internal view returns (uint256) {
    if (saleState == 1) {
      return PRESALE_PRICE;
    }
    return PUBLIC_PRICE;
  }

  /**
   * Security, signature check
   */
  function _isValidSignature(
    address _buyer,
    uint256 _max,
    bytes memory signature
  ) internal view returns (bool) {
    bytes32 digest = _hashTypedDataV4(
      keccak256(abi.encode(SEC_TYPEHASH, _buyer, _max))
    );
    return ECDSA.recover(digest, signature) == signerAddress;
  }

  /**
   * State setters and getters
   */
  function setSigner(address _signerAddress) external onlyOwner {
    signerAddress = _signerAddress;
  }

  function setSaleState(uint256 _newState) external onlyOwner {
    saleState = _newState;
  }

  function withdrawAll() external onlyOwner {
    require(address(this).balance > 0, "No balance");
    payable(msg.sender).transfer(address(this).balance);
  }

  function setContractURI(string calldata newURI) external onlyOwner {
    _contractMetadataURI = newURI;
  }

  function contractURI() external view returns (string memory) {
    return _contractMetadataURI;
  }

  function setBaseURI(string calldata newURI) external onlyOwner {
    _baseTokenURI = newURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }
}
