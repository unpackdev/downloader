//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Address.sol";
import "./MerkleProof.sol";
import "./SafeCast.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract AlienSeahorseArmy is ERC721A, Ownable {

  using Strings for uint256;
  using Address for address;
  using SafeCast for uint256;

  struct DutchAuctionConfig {
    uint32 txLimit;
    uint32 dropCeiling;
    uint32 startTime;
    uint32 bottomTime;
    uint32 stepInterval;
    uint256 startPrice;
    uint256 bottomPrice;
    uint256 priceStep;
  }

  uint256 public constant MAX_SUPPLY = 10000;

  string private baseURI;
  string private notRevealedURI;
  bool public revealed = false;

  uint256 public maxPresaleMint = 5;
  uint256 public presalePrice = 0.015 ether;
  bool public presaleIsActive = false;
  bytes32 public whitelistMerkleRoot;

  DutchAuctionConfig public dutchAuctionConfig;

  constructor() ERC721A("Alien Seahorse Army", "ASA") {
    notRevealedURI = "ipfs://QmRSaaJiypncde1W3DAqGVBeRfPMcN2TUBGrUyaYDqWQEG/hidden.json";
  }

  function _verify(
    bytes32[] memory proof,
    bytes32 merkleRoot
        ) internal view returns (bool) {
    return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
  }

  function mintPresale(uint256 amount, bytes32[] calldata proof)
    external
    payable
  {
    require(presaleIsActive, "Presale is not active");
    uint256 mintCount = _getAux(msg.sender) + amount;
    require(mintCount <= maxPresaleMint, "User allotment exceeded");
    require(msg.value == presalePrice * amount, "Insufficient payment");
    require(totalSupply() + amount <= MAX_SUPPLY, "Max limit exceeded");
    require(_verify(proof, whitelistMerkleRoot), "Invalid proof");

    _setAux(msg.sender, uint64(mintCount));

    _safeMint(msg.sender, amount);
  }

  function mintPublicSale(uint256 amount)
    external
    payable
  {

    require((!msg.sender.isContract() && msg.sender == tx.origin), "Contract buys not allowed");

    DutchAuctionConfig memory _config = dutchAuctionConfig;

    require(totalSupply() + amount <= _config.dropCeiling, "Max limit exceeded");

    require(block.timestamp >= _config.startTime, "Sale is not active");
    require(amount <= _config.txLimit, "Transaction limit exceeded");

    uint256 mintPrice = getCurrentAuctionPrice() * amount;
    require(msg.value >= mintPrice, "Insufficient payment");


    // Refund if customer paid more than the cost to mint
    if (msg.value > mintPrice) {
      Address.sendValue(payable(msg.sender), msg.value - mintPrice);
    }

    _safeMint(msg.sender, amount);
  }

  function getCurrentAuctionPrice() public view returns (uint256 currentPrice) {
    DutchAuctionConfig memory _config = dutchAuctionConfig;

    uint256 timestamp = block.timestamp;

    if (timestamp < _config.startTime) {
      currentPrice = _config.startPrice;
    } else if (timestamp >= _config.bottomTime) {
      currentPrice = _config.bottomPrice;
    } else {
      uint256 elapsedIntervals = (timestamp - _config.startTime) /
      _config.stepInterval;
      currentPrice =
      _config.startPrice -
      (elapsedIntervals * _config.priceStep);
    }

    return currentPrice;
  }
  
  function setPresaleIsActive(bool state) external onlyOwner {
    presaleIsActive = state;
  }

  function setMaxPresaleMint(uint256 amount) external onlyOwner {
    maxPresaleMint = amount;
  }

  function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    whitelistMerkleRoot = merkleRoot;
  }

  function reveal(bool state) external onlyOwner {
    revealed = state;
  }

  function gift(uint256 amount, address to) external onlyOwner {
    require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");

    _safeMint(to, amount);
  }

  function setBaseURI(string memory newbaseURI) external onlyOwner {
    baseURI = newbaseURI;
  }

  function configureDutchAuction(
    uint256 txLimit,
    uint256 dropCeiling,
    uint256 startTime,
    uint256 bottomTime,
    uint256 stepInterval,
    uint256 startPrice,
    uint256 bottomPrice,
    uint256 priceStep
  ) external onlyOwner {
    require(dropCeiling <= MAX_SUPPLY, "Drop limit exceeds max supply");
    uint32 _txLimit = txLimit.toUint32();
    uint32 _dropCeiling = dropCeiling.toUint32();
    uint32 _startTime = startTime.toUint32();
    uint32 _bottomTime = bottomTime.toUint32();
    uint32 _stepInterval = stepInterval.toUint32();

    dutchAuctionConfig.txLimit = _txLimit;
    dutchAuctionConfig.dropCeiling = _dropCeiling;
    dutchAuctionConfig.startTime = _startTime;
    dutchAuctionConfig.bottomTime = _bottomTime;
    dutchAuctionConfig.stepInterval = _stepInterval;
    dutchAuctionConfig.startPrice = startPrice;
    dutchAuctionConfig.bottomPrice = bottomPrice;
    dutchAuctionConfig.priceStep = priceStep;
  }

  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Failed to transfer ether");
  }

  function getPresaleMints(address _owner) external view returns (uint64) {
    return _getAux(_owner);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "Nonexistent token");

    if(!revealed) {
      return notRevealedURI;
    }

    return string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
  }
}
