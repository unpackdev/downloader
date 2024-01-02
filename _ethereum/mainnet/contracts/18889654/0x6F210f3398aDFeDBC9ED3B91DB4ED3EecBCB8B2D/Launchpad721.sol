// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./CountersUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

error EmptyString();
error ArrayLengthMismatch();
error TokenNotPresent();

contract Launchpad721 is Initializable, OwnableUpgradeable, ERC721BurnableUpgradeable, ERC2981Upgradeable {
  // State Variables
  using CountersUpgradeable for CountersUpgradeable.Counter;
  CountersUpgradeable.Counter public tokenIdCounter;

  /// @dev base uri
  string public currentBaseURI;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev Initializes the contract.
   * @param _name NFT name
   * @param _symbol NFT symbol
   * @param _feeNumerator fee for royalty
   * @param _currentBaseURI base uri
   */
  function initialize(string memory _name, string memory _symbol, uint96 _feeNumerator, string memory _currentBaseURI) public initializer {
    if (!(bytes(_currentBaseURI).length > 0 && bytes(_name).length > 0)) revert EmptyString();

    __ERC721_init(_name, _symbol);
    __ERC721Burnable_init();
    __ERC2981_init();
    __Ownable_init_unchained();
    tokenIdCounter.increment();
    currentBaseURI = _currentBaseURI;

    _setDefaultRoyalty(msg.sender, _feeNumerator);
  }

  /**
   * @dev Return the base uri
   */
  function _baseURI() internal view override returns (string memory) {
    return currentBaseURI;
  }

  /**
   * @dev Set Base URI.
   * @param _newBaseURI base uri to be updated.
   *
   * Requirement:
   * - Only default owner can access this function.
   *
   */
  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    if (!(bytes(_newBaseURI).length > 0)) revert EmptyString();

    currentBaseURI = _newBaseURI;
  }

  /**
   * @dev Function to mint nft
   * @param _to Address to which nft has to be minted.
   *
   * Requiremnt:
   * - Only minter cn access this function.
   *
   */
  function mint(address _to) public onlyOwner {
    _safeMint(_to, tokenIdCounter.current());
    tokenIdCounter.increment();
  }

  /**
   * @dev Batch Mint
   * @param _to array of address to mint 1 token each
   */
  function batchMint(address[] calldata _to) external {
    for (uint i; i < _to.length; ) {
      mint(_to[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Batch transfer of NFTs.
   * @param _from Address from which transfer has to be made.
   * @param _to List of address to which NFT has to be transferred.
   * @param _ids List of ids.
   *
   * Requiremnet:
   * - Length of _to and _ids array shouldbe same.
   * _ msg.sender should be the owner or should have approved nfts, only then this can be called.
   */
  function batchTransfer(address _from, address[] calldata _to, uint256[] calldata _ids) external {
    if (_to.length != _ids.length) revert ArrayLengthMismatch();

    for (uint i = 0; i < _ids.length; ) {
      safeTransferFrom(_from, _to[i], _ids[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Function to set Royalty for a particular token.
   * @param _tokenId Token Id to which royalty is set.
   * @param _receiver Royalty receiver.
   * @param _feeNumerator Royalty fee percentage.
   *
   * Requiremnts:
   * - Can only be accessed by owner.
   * - cannot set Royalty for NFT that doesn't exists.
   *
   */
  function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _feeNumerator) external onlyOwner {
    if (!_exists(_tokenId)) revert TokenNotPresent();
    _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
  }

  /**
   * @dev Function to reset default royalty.
   * @param _receiver Royalty receiver.
   * @param _feeNumerator Royalty fee percentage.
   *
   * Requiremnts:
   * - Can only be accessed by owner.
   *
   */
  function setDefaultTokenRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
    _setDefaultRoyalty(_receiver, _feeNumerator);
  }

  function supportsInterface(bytes4 _interfaceId) public view override(ERC721Upgradeable, ERC2981Upgradeable) returns (bool) {
    return super.supportsInterface(_interfaceId);
  }
}
