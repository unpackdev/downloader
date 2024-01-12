// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Counters.sol";

contract EquityPass is ERC721A, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using ECDSA for bytes32;
  using Counters for Counters.Counter;
  using Strings for uint256;

  uint256 public constant MAX_EQUITY_PASS = 222;
  uint256 public MAX_EQUITY_PASS_PER_PURCHASE = 13;
  uint256 public constant EQUITY_PASS_PRESALE_PRICE = 0.10 ether;
  uint256 public constant EQUITY_PASS_PRICE = 0.13 ether;
  uint256 public constant RESERVED_EQUITY_PASS = 13;
  uint256 public MAX_EQUITY_PASS_WHITELIST_CAP = 1;
  
  bytes32 public merkleroot;
  string public tokenBaseURI;
  bool public mintActive = false;
  bool public reservesMinted = false;
  bool public presaleActive = false;
  bool public reveal = false;

  mapping(address => uint256) private whitelistAddressMintCount;

  /**
   * @dev Contract Methods
   */
  constructor(
    uint256 _maxEquityPassPerPurchase
  ) ERC721A("Equity Pass", "EP", _maxEquityPassPerPurchase, MAX_EQUITY_PASS) {}
  /********
   * Mint *
   ********/
    function presaleMint(uint256 _quantity, bytes32[] calldata _merkleProof) external payable nonReentrant {
    require(verifyMerkleProof(keccak256(abi.encodePacked(msg.sender)), _merkleProof), "Invalid whitelist signature");
    require(presaleActive, "Presale is not active");
    require(_quantity <= MAX_EQUITY_PASS_WHITELIST_CAP, "This is above the max allowed mints for presale");
    require(msg.value >= EQUITY_PASS_PRESALE_PRICE.mul(_quantity), "The ether value sent is not correct"); // You can remove this line if presale is free mint
    require(whitelistAddressMintCount[msg.sender].add(_quantity) <= MAX_EQUITY_PASS_WHITELIST_CAP, "This purchase would exceed the maximum you are allowed to mint in the presale");
    require(totalSupply().add(_quantity) <= MAX_EQUITY_PASS - RESERVED_EQUITY_PASS, "This purchase would exceed max supply for presale");

    whitelistAddressMintCount[msg.sender] += _quantity;
    _safeMintEquityPass(_quantity);
  }
  function publicMint(uint256 _quantity) external payable {
    require(mintActive, "Sale is not active.");
    require(_quantity <= MAX_EQUITY_PASS_PER_PURCHASE, "Quantity is more than allowed per transaction.");
    require(msg.value >= EQUITY_PASS_PRICE.mul(_quantity), "The ether value sent is not correct");

    _safeMintEquityPass(_quantity);
  }

  function _safeMintEquityPass(uint256 _quantity) internal {
    require(_quantity > 0, "You must mint at least 1 Equity Pass nft");
    require(totalSupply().add(_quantity) <= MAX_EQUITY_PASS, "This purchase would exceed max supply");
    _safeMint(msg.sender, _quantity);
  }

  /*
   * Note: Mint reserved Equity Pass.
   */

  function mintReservedEquityPass() external onlyOwner {
    require(!reservesMinted, "Reserves have already been minted.");
    require(totalSupply().add(RESERVED_EQUITY_PASS) <= MAX_EQUITY_PASS, "This mint would exceed max supply");
    _safeMint(msg.sender, RESERVED_EQUITY_PASS);

    reservesMinted = true;
  }

  function setPresaleActive(bool _active) external onlyOwner {
    presaleActive = _active;
  }

  function setMintActive(bool _active) external onlyOwner {
    mintActive = _active;
  }

  function setMerkleRoot(bytes32 MR) external onlyOwner {
    merkleroot = MR;
  }

  function setReveal(bool _reveal) external onlyOwner {
    reveal = _reveal;
  }

  function setWhitelistCap(uint256 _cap) external onlyOwner {
    MAX_EQUITY_PASS_WHITELIST_CAP = _cap;
  }

  function setTokenBaseURI(string memory _baseURI) external onlyOwner {
    tokenBaseURI = _baseURI;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    return string(abi.encodePacked(tokenBaseURI));
  }

  /**************
   * Withdrawal *
   **************/

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

    /************
   * Security *
   ************/

  function verifyMerkleProof(bytes32 leaf, bytes32[] memory _merkleProof) private view returns(bool) {
    return MerkleProof.verify(_merkleProof, merkleroot, leaf);
  }
}
