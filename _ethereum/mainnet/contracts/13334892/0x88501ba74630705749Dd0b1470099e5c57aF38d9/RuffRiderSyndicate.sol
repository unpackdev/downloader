// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./ECDSA.sol";

contract RuffRiderSyndicate is Ownable, ERC721Enumerable {
  using SafeMath for uint256;
  using ECDSA for bytes32;

  uint256 public constant mintPrice = 0.08 ether;
  uint256 public constant mintLimit = 20;
  uint public constant presaleMintLimitPerAddress = 3;

  uint256 public supplyLimit = 10000;
  bool public saleActive = false;
  bool public presaleActive = false;

  string public baseUri;

  mapping(address => uint) private presaleMinted;

  address private _devAddress = 0xDDbaaF86604Ab0e9470660C463F060A0ddeC6858;
  uint private _devPercent = 10;

  address public whiteListSigner;
  bool public whiteListSignerSet = false;

  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private PRESALE_TYPEHASH = keccak256("presale(address buyer)");

  constructor() ERC721("Ruff Riders Syndicate", "RRS") {
    uint256 chainId;
      assembly {
        chainId := chainid()
      }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("Ruff Riders Syndicate")),
        keccak256(bytes("1")),
        chainId,
        address(this))
    );
  }

  function _baseURI() internal view override returns (string memory) {
    return baseUri;
  }

  function baseURI() public view returns (string memory) {
    return baseUri;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseUri = newBaseUri;
  }
  
  function toggleSaleActive() external onlyOwner {
    if (presaleActive) {
      assert(saleActive == false);
      presaleActive = false;
    }
    saleActive = !saleActive;
  }

  function togglePresaleActive() external onlyOwner {
    if (saleActive) {
      assert(presaleActive == false);
      saleActive = false;
    }
    presaleActive = !presaleActive;
  }
  
  function setWhiteListSigner(address signer) external onlyOwner {
    whiteListSignerSet = true;
    whiteListSigner = signer;
  }

  function mintPresale(bytes memory signature, uint numberOfTokens) external payable {
    require(presaleActive, "Presale is not active.");
    require(whiteListSignerSet == true, "White list signer not yet set");
    require(numberOfTokens <= mintLimit, "Too many tokens for one transaction.");
    require(msg.value >= mintPrice.mul(numberOfTokens), "Insufficient payment.");
    require((presaleMinted[msg.sender] + numberOfTokens) <= presaleMintLimitPerAddress, "Over presale mint limit for this address");
    
    bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PRESALE_TYPEHASH, msg.sender))));

    address signer = digest.recover(signature);

    require(signer != address(0), "ECDSA: invalid signature");
    require(signer == whiteListSigner, "mintPresale: invalid signature");

    presaleMinted[msg.sender] = presaleMinted[msg.sender] + numberOfTokens;
    _mint(numberOfTokens);
  }

  function mint(uint numberOfTokens) external payable {
    require(saleActive, "Sale is not active.");
    require(numberOfTokens <= mintLimit, "Too many tokens for one transaction.");
    require(msg.value >= mintPrice.mul(numberOfTokens), "Insufficient payment.");

    _mint(numberOfTokens);
  }

  function _mint(uint numberOfTokens) private {
    require(totalSupply().add(numberOfTokens) <= supplyLimit, "Not enough tokens left.");

    uint256 newId = totalSupply();
    for(uint i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(msg.sender, newId);
    }
  }

  function reserve(uint256 numberOfTokens) external onlyOwner {
    _mint(numberOfTokens);
  }

  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw.");
    
    uint devShare = address(this).balance.mul(_devPercent).div(100);
    
    (bool success, ) = _devAddress.call{value: devShare}("");
    require(success, "Withdrawal for dev failed.");

    (success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Withdrawal for owner failed.");
  }

  function tokensOwnedBy(address wallet) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for(uint i = 0; i < tokenCount; i++){
      ownedTokenIds[i] = tokenOfOwnerByIndex(wallet, i);
    }

    return ownedTokenIds;
  }
}