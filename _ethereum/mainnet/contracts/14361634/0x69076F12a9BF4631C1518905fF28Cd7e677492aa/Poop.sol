// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";

/*
'########:::'#######:::'#######::'########::::::'######::::::'###::::'##::: ##::'######:::
 ##.... ##:'##.... ##:'##.... ##: ##.... ##::::'##... ##::::'## ##::: ###:: ##:'##... ##::
 ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##:::: ##:::..::::'##:. ##:: ####: ##: ##:::..:::
 ########:: ##:::: ##: ##:::: ##: ########::::: ##::'####:'##:::. ##: ## ## ##: ##::'####:
 ##.....::: ##:::: ##: ##:::: ##: ##.....:::::: ##::: ##:: #########: ##. ####: ##::: ##::
 ##:::::::: ##:::: ##: ##:::: ##: ##::::::::::: ##::: ##:: ##.... ##: ##:. ###: ##::: ##::
 ##::::::::. #######::. #######:: ##:::::::::::. ######::: ##:::: ##: ##::. ##:. ######:::
..::::::::::.......::::.......:::..:::::::::::::......::::..:::::..::..::::..:::......::::

Ah sh!t. Look what we have here. Fresh meat.

You think you have what it takes to be part of the POOP GANG?

Reckless abandon? Nihilistic tendencies? Look, we’ve seen the other side.

Grand promises of salvation and glory. It’s all crap.

Toss what you know and change the world with us.

Forget about the HOOD SQUAD, tied up in that loyalty bullsh!t.

We’re here to let loose and wreak havoc.

We’re disintegrating this concrete jungle one acid dropping at a time,
erasing the corrupt capitalist agenda that’s been building here for ages.

Ready to rip one? LFG!

*/

contract Poop is
  Initializable,
  ERC721Upgradeable,
  PausableUpgradeable,
  AccessControlUpgradeable,
  ERC721BurnableUpgradeable,
  OwnableUpgradeable
{
  using CountersUpgradeable for CountersUpgradeable.Counter;

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  CountersUpgradeable.Counter private _tokenIdCounter;
  string BASE_URI;
  uint16 public TOTAL_POOP;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  address ROYALTY_RECEIVER;
  uint8 royaltyPercentage;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize() public initializer {
    __ERC721_init("STAPLEVERSE - POOP GANG", "POOP");
    __Pausable_init();
    __AccessControl_init();
    __Ownable_init();
    __ERC721Burnable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);

    TOTAL_POOP = 5000;
    royaltyPercentage = 10;
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function mintInitialToken() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _safeMint(_msgSender(), 0);
  }

  function safeMint(address to) public onlyRole(MINTER_ROLE) {
    require(
      _tokenIdCounter.current() < TOTAL_POOP,
      "There are no more tokens available"
    );
    _tokenIdCounter.increment();
    uint256 tokenId = _tokenIdCounter.current();
    _safeMint(to, tokenId);
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (ROYALTY_RECEIVER, _salePrice * royaltyPercentage / 100);
  }

  function setRoyaltyReceiver(address newReceiver)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    ROYALTY_RECEIVER = newReceiver;
  }

  function setRoyaltyPercentage(uint8 newRoyaltyPercentage)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(newRoyaltyPercentage <= 100, "Royalty percentage cannot be greater than 100");
    royaltyPercentage = newRoyaltyPercentage;
  }

  function tokensAvailable() public view returns (uint256) {
    return TOTAL_POOP - _tokenIdCounter.current();
  }

  function setBaseUri(string memory newUri)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    BASE_URI = newUri;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _baseURI() internal view override returns (string memory) {
    return BASE_URI;
  }

  // The following functions are overrides required by Solidity.

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return
      interfaceId == _INTERFACE_ID_ERC2981 ||
      super.supportsInterface(interfaceId);
  }
}

// FUTURE PRIMITIVE ✍️
