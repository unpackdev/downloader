// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

import "./ERC721AQueryable.sol";

contract ERC721Drop is ERC721AQueryable, Ownable, ReentrancyGuard {
  error InvalidEtherValue();
  error MaxPerWalletOverflow();
  error TotalSupplyOverflow();
  error InvalidProof();

  struct MintRules {
    uint256 supply;
    uint256 maxPerWallet;
    uint256 freePerWallet;
    uint256 price;
  }

  modifier onlyWhitelist(bytes32[] calldata _proof, uint256 _freeQuantity) {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, _freeQuantity))));

    if (!MerkleProof.verify(_proof, _merkleRoot, leaf)) {
      revert InvalidProof();
    }
    _;
  }

  MintRules public mintRules;
  string public baseTokenURI;

  bytes32 private _merkleRoot;

  constructor() ERC721A("Hidzuka", "Card") {}

  /*//////////////////////////////////////////////////////////////
                         External getters
  //////////////////////////////////////////////////////////////*/

  function totalMinted() external view returns (uint256) {
    return _totalMinted();
  }

  function numberMinted(address _owner) external view returns (uint256) {
    return _numberMinted(_owner);
  }

  /*//////////////////////////////////////////////////////////////
                         Minting functions
  //////////////////////////////////////////////////////////////*/

  function mint(
    uint256 _quantity,
    uint256 _freeQuantity,
    bytes32[] calldata _proof
  ) external payable onlyWhitelist(_proof, _freeQuantity) {
    _customMint(_quantity, _freeQuantity);
  }

  function mint(uint256 _quantity) external payable {
    _customMint(_quantity, mintRules.freePerWallet);
  }

  /*//////////////////////////////////////////////////////////////
                      Owner functions
  //////////////////////////////////////////////////////////////*/

  function airdrop(address _to, uint256 _amount) external onlyOwner {
    if (_totalMinted() + _amount > mintRules.supply) {
      revert TotalSupplyOverflow();
    }

    _safeMint(_to, _amount);
  }

  function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setMintRules(MintRules calldata _mintRules) external onlyOwner {
    mintRules = _mintRules;
  }

  function withdraw() external onlyOwner nonReentrant {
    payable(msg.sender).transfer(address(this).balance);
  }

  function setMerkleRoot(bytes32 _root) external onlyOwner {
    _merkleRoot = _root;
  }

  /*//////////////////////////////////////////////////////////////
                      Internal functions
  //////////////////////////////////////////////////////////////*/

  function _customMint(uint256 _quantity, uint256 _freeQuantity) internal {
    uint256 _paidQuantity = _calculatePaidQuantity(msg.sender, _quantity, _freeQuantity);

    if (_paidQuantity != 0 && msg.value < mintRules.price * _paidQuantity) {
      revert InvalidEtherValue();
    }

    if (_numberMinted(msg.sender) + _quantity > mintRules.maxPerWallet) {
      revert MaxPerWalletOverflow();
    }

    if (_totalMinted() + _quantity > mintRules.supply) {
      revert TotalSupplyOverflow();
    }

    _safeMint(msg.sender, _quantity);
  }

  function _calculatePaidQuantity(
    address _owner,
    uint256 _quantity,
    uint256 _freeQuantity
  ) internal view returns (uint256) {
    uint256 _alreadyMinted = _numberMinted(_owner);
    uint256 _freeQuantityLeft = _alreadyMinted >= _freeQuantity ? 0 : _freeQuantity - _alreadyMinted;

    return _freeQuantityLeft >= _quantity ? 0 : _quantity - _freeQuantityLeft;
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
}
