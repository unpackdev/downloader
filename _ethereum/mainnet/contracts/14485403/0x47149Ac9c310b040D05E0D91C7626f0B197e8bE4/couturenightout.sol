// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract CoutureNightOut is ERC721, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using ECDSA for bytes32;
  using Counters for Counters.Counter;
  using Strings for uint256;

  uint256 public MAX_COUTURE_NIGHT_OUT;
  uint256 public MAX_COUTURE_NIGHT_OUT_PER_PURCHASE;
  uint256 public MAX_COUTURE_NIGHT_OUT_WHITELIST_CAP;
  uint256 public Courture_Night_Out_PRICE = 0.03 ether;
  uint256 public constant RESERVED_Couture_Night_Out = 75;

  string public tokenBaseURI;
  string public unrevealedURI;
  bool public presaleActive = false;
  bool public mintActive = false;
  bool public reservesMinted = false;

  mapping(address => uint256) private whitelistAddressMintCount;

  Counters.Counter public tokenSupply;

  constructor(
    uint256 _maxCoutureNightOut,
    uint256 _maxCoutureNightOutPerPurchase,
    uint256 _maxCoutureNightOutWhitelistCap
  ) ERC721("CoutureNightOut", "CNO") {
    MAX_COUTURE_NIGHT_OUT = _maxCoutureNightOut;
    MAX_COUTURE_NIGHT_OUT_PER_PURCHASE = _maxCoutureNightOutPerPurchase;
    MAX_COUTURE_NIGHT_OUT_WHITELIST_CAP = _maxCoutureNightOutWhitelistCap;
  }

  function setPrice(uint256 _newPrice) external onlyOwner {
    Courture_Night_Out_PRICE = _newPrice;
  }

  function setTokenBaseURI(string memory _baseURI) external onlyOwner {
    tokenBaseURI = _baseURI;
  }

  function setUnrevealedURI(string memory _unrevealedUri) external onlyOwner {
    unrevealedURI = _unrevealedUri;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    bool revealed = bytes(tokenBaseURI).length > 0;

    if (!revealed) {
      return unrevealedURI;
    }

    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(tokenBaseURI, _tokenId.toString()));
  }
  function presaleMint(uint256 _quantity, bytes calldata _whitelistSignature) external payable nonReentrant {
    require(presaleActive, "Presale is not active");
    require(verifyOwnerSignature(keccak256(abi.encode(msg.sender)), _whitelistSignature), "Invalid whitelist signature");
    require(_quantity <= MAX_COUTURE_NIGHT_OUT_WHITELIST_CAP, "You can only mint a maximum of 10 for presale");
    require(whitelistAddressMintCount[msg.sender].add(_quantity) <= MAX_COUTURE_NIGHT_OUT_WHITELIST_CAP, "This purchase would exceed the maximum Couture Night Out you are allowed to mint in the presale");

    whitelistAddressMintCount[msg.sender] += _quantity;
    _safeMintCoutureNightOut(_quantity);
  }

  function publicMint(uint256 _quantity) external payable nonReentrant {
    require(mintActive, "Sale is not active.");
    require(_quantity <= MAX_COUTURE_NIGHT_OUT_PER_PURCHASE, "Quantity is more than allowed per transaction.");

    _safeMintCoutureNightOut(_quantity);
  }

  function _safeMintCoutureNightOut(uint256 _quantity) internal {
    require(_quantity > 0, "You must mint at least 1 Couture Night Out");
    require(tokenSupply.current().add(_quantity) <= MAX_COUTURE_NIGHT_OUT, "This purchase would exceed max supply of Couture Night Out");
    require(msg.value >= Courture_Night_Out_PRICE.mul(_quantity), "The ether value sent is not correct");

    for (uint256 i = 0; i < _quantity; i++) {
      uint256 mintIndex = tokenSupply.current();

      if (mintIndex < MAX_COUTURE_NIGHT_OUT) {
        tokenSupply.increment();
        _safeMint(msg.sender, mintIndex);
      }
    }
  }

  function mintReservedCoutureNightOut() external onlyOwner {
    require(!reservesMinted, "Reserves have already been minted.");
    require(tokenSupply.current().add(RESERVED_Couture_Night_Out) <= MAX_COUTURE_NIGHT_OUT, "This mint would exceed max supply of Couture Night Out");

    for (uint256 i = 0; i < RESERVED_Couture_Night_Out; i++) {
      uint256 mintIndex = tokenSupply.current();

      if (mintIndex < MAX_COUTURE_NIGHT_OUT) {
        tokenSupply.increment();
        _safeMint(msg.sender, mintIndex);
      }
    }

    reservesMinted = true;
  }

  function setPresaleActive(bool _active) external onlyOwner {
    presaleActive = _active;
  }

  function setMintActive(bool _active) external onlyOwner {
    mintActive = _active;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(0x4964Aa2bffF9e7e25084e599FaC6ED7fFDf65617).transfer((balance*25)/100);
    payable(0x8d73bf04be285616bA8784864cDC634463EB06f9).transfer((balance*75)/100);
  }

  function verifyOwnerSignature(bytes32 hash, bytes memory signature) private view returns(bool) {
    return hash.toEthSignedMessageHash().recover(signature) == owner();
  }
}