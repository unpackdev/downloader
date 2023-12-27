// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./DefaultOperatorFilterer.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

import "./IShikkuboERC721.sol";

contract ShikkuboERC721 is
  IShikkuboERC721,
  ERC721AQueryable,
  PaymentSplitter,
  Ownable,
  ReentrancyGuard,
  DefaultOperatorFilterer
{
  using Strings for uint256;

  MintRules public mintRules;

  string public baseTokenURI;

  bool public revealed;

  address[] private _withdrawAddresses;

  bytes32 private _root;

  mapping(Rarity => string) public rarityImageURI;

  constructor(
    address[] memory _payees,
    uint256[] memory _shares
  ) ERC721A("Shikkubo", "SKKB") PaymentSplitter(_payees, _shares) {
    _withdrawAddresses = _payees;
  }

  /*//////////////////////////////////////////////////////////////
                         Public getters
  //////////////////////////////////////////////////////////////*/

  function totalMinted() external view returns (uint256) {
    return _totalMinted();
  }

  function numberMinted(address _owner) external view returns (uint256) {
    return _numberMinted(_owner);
  }

  function nonFreeAmount(address _owner, uint256 _amount, uint256 _freeAmount) external view returns (uint256) {
    return _calculateNonFreeAmount(_owner, _amount, _freeAmount);
  }

  function rarityOf(uint256 _tokenId) external pure returns (Rarity) {
    return _tokenRarity(_tokenId);
  }

  function rarityDistribution(Rarity _rarity) external pure returns (uint256) {
    return _rarityDistribution(_rarity);
  }

  /*//////////////////////////////////////////////////////////////
                         Minting functions
  //////////////////////////////////////////////////////////////*/

  function whitelistMint(uint256 _amount, bytes32[] memory _proof) external payable {
    _verify(_proof);

    uint256 _nonFreeAmount = _calculateNonFreeAmount(msg.sender, _amount, mintRules.whitelistFreePerWallet);

    if (_nonFreeAmount != 0 && msg.value < mintRules.price * _nonFreeAmount) {
      revert InvalidEtherValue();
    }

    if (_numberMinted(msg.sender) + _amount > mintRules.maxPerWallet) {
      revert MaxPerWalletOverflow();
    }

    if (_totalMinted() + _amount > mintRules.totalSupply) {
      revert TotalSupplyOverflow();
    }

    _safeMint(msg.sender, _amount);
  }

  function mint(uint256 _amount) external payable {
    uint256 _nonFreeAmount = _calculateNonFreeAmount(msg.sender, _amount, mintRules.freePerWallet);

    if (_nonFreeAmount != 0 && msg.value < mintRules.price * _nonFreeAmount) {
      revert InvalidEtherValue();
    }

    if (_numberMinted(msg.sender) + _amount > mintRules.maxPerWallet) {
      revert MaxPerWalletOverflow();
    }

    if (_totalMinted() + _amount > mintRules.totalSupply) {
      revert TotalSupplyOverflow();
    }

    _safeMint(msg.sender, _amount);
  }

  /*//////////////////////////////////////////////////////////////
                          Owner functions
  //////////////////////////////////////////////////////////////*/

  function airdrop(address _to, uint256 _amount) external onlyOwner {
    _safeMint(_to, _amount);
  }

  function setBaseURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setMintRules(MintRules memory _mintRules) external onlyOwner {
    mintRules = _mintRules;
  }

  function setRarityImageURI(string[5] memory _imageURI) external onlyOwner {
    for (uint256 i = 0; i < _imageURI.length; i++) {
      rarityImageURI[Rarity(i)] = _imageURI[i];
    }
  }

  function setRevealed(bool _value) external onlyOwner {
    revealed = _value;
  }

  function withdraw() external onlyOwner {
    for (uint256 i = 0; i < _withdrawAddresses.length; ) {
      address payable withdrawAddress = payable(_withdrawAddresses[i]);

      if (releasable(withdrawAddress) > 0) {
        release(withdrawAddress);
      }

      unchecked {
        ++i;
      }
    }
  }

  function setRoot(bytes32 _newRoot) external onlyOwner {
    _root = _newRoot;
  }

  /*//////////////////////////////////////////////////////////////
                         Internal functions
  //////////////////////////////////////////////////////////////*/

  function _calculateNonFreeAmount(
    address _owner,
    uint256 _amount,
    uint256 _freeAmount
  ) internal view returns (uint256) {
    uint256 _freeAmountLeft = _numberMinted(_owner) >= _freeAmount ? 0 : _freeAmount - _numberMinted(_owner);

    return _freeAmountLeft >= _amount ? 0 : _amount - _freeAmountLeft;
  }

  function _tokenRarity(uint256 _tokenId) internal pure returns (Rarity) {
    uint256 _random = uint256(keccak256(abi.encodePacked(_tokenId))) % 100;

    if (_random < _rarityDistribution(Rarity.COMMON)) {
      return Rarity.COMMON;
    } else if (_random < _rarityDistribution(Rarity.COMMON) + _rarityDistribution(Rarity.UNCOMMON)) {
      return Rarity.UNCOMMON;
    } else if (
      _random <
      _rarityDistribution(Rarity.COMMON) + _rarityDistribution(Rarity.UNCOMMON) + _rarityDistribution(Rarity.RARE)
    ) {
      return Rarity.RARE;
    } else if (
      _random <
      _rarityDistribution(Rarity.COMMON) +
        _rarityDistribution(Rarity.UNCOMMON) +
        _rarityDistribution(Rarity.RARE) +
        _rarityDistribution(Rarity.EPIC)
    ) {
      return Rarity.EPIC;
    } else {
      return Rarity.LEGENDARY;
    }
  }

  function _rarityToString(Rarity _rarity) internal pure returns (string memory) {
    if (_rarity == Rarity.COMMON) {
      return "Common";
    } else if (_rarity == Rarity.UNCOMMON) {
      return "Uncommon";
    } else if (_rarity == Rarity.RARE) {
      return "Rare";
    } else if (_rarity == Rarity.EPIC) {
      return "Epic";
    } else {
      return "Legendary";
    }
  }

  function _rarityDistribution(Rarity _rarity) internal pure returns (uint256) {
    if (_rarity == Rarity.COMMON) {
      return 40;
    } else if (_rarity == Rarity.UNCOMMON) {
      return 30;
    } else if (_rarity == Rarity.RARE) {
      return 20;
    } else if (_rarity == Rarity.EPIC) {
      return 8;
    } else {
      return 2;
    }
  }

  function _verify(bytes32[] memory _proof) private view {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));

    if (!MerkleProof.verify(_proof, _root, leaf)) {
      revert InvalidProof();
    }
  }

  /*//////////////////////////////////////////////////////////////
                          Overriden ERC721A
  //////////////////////////////////////////////////////////////*/

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
    if (revealed) {
      return super.tokenURI(tokenId);
    }

    Rarity _rarity = _tokenRarity(tokenId);

    bytes memory dataURI = abi.encodePacked(
      "{",
      '"name": "',
      symbol(),
      " #",
      tokenId.toString(),
      '",',
      '"image": "',
      rarityImageURI[_rarity],
      '",',
      '"attributes": [{"trait_type": "Rarity", "value": "',
      _rarityToString(_rarity),
      '"}]',
      "}"
    );
    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
  }

  /*//////////////////////////////////////////////////////////////
                        DefaultOperatorFilterer
  //////////////////////////////////////////////////////////////*/

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}
