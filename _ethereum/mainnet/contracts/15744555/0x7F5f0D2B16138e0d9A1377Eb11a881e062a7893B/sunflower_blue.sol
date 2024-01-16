// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

/// @custom:security-contact admin@infinit3.io
contract CharlieGrinSunflowerBlue is
  Initializable,
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  ERC721BurnableUpgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable
{
  string public baseTokenURI;
  uint256 public MAX_SUPPLY;
  string public contractURI;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize() public initializer {
    __ERC721_init("Charlie Grin Sunflower (Blue)", "GRIN");
    __ERC721Enumerable_init();
    __ERC721Burnable_init();
    __Ownable_init();
    __UUPSUpgradeable_init();

    MAX_SUPPLY = 200;
    baseTokenURI = "https://metadata.infinit3.io/metadata/57/";
    contractURI = "https://metadata.infinit3.io/metadata/57/contract";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    baseTokenURI = baseURI;
  }

  function setContractURI(string memory URI) public onlyOwner {
    contractURI = URI;
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function mint() public onlyOwner {
    require(totalSupply() < MAX_SUPPLY);
    for (uint256 i = 1; i <= MAX_SUPPLY; i++) {
      _safeMint(msg.sender, i);
    }
  }
}
