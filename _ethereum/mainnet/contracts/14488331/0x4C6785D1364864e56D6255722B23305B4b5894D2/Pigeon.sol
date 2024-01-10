// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";

/*
'##::::'##::'#######:::'#######::'########::::::'######:::'#######::'##::::'##::::'###::::'########::
 ##:::: ##:'##.... ##:'##.... ##: ##.... ##::::'##... ##:'##.... ##: ##:::: ##:::'## ##::: ##.... ##:
 ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##:::: ##:::..:: ##:::: ##: ##:::: ##::'##:. ##:: ##:::: ##:
 #########: ##:::: ##: ##:::: ##: ##:::: ##::::. ######:: ##:::: ##: ##:::: ##:'##:::. ##: ##:::: ##:
 ##.... ##: ##:::: ##: ##:::: ##: ##:::: ##:::::..... ##: ##:'## ##: ##:::: ##: #########: ##:::: ##:
 ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##::::'##::: ##: ##:.. ##:: ##:::: ##: ##.... ##: ##:::: ##:
 ##:::: ##:. #######::. #######:: ########:::::. ######::: ##### ##:. #######:: ##:::: ##: ########::
..:::::..:::.......::::.......:::........:::::::......::::.....:..:::.......:::..:::::..::........:::

This city was built on the feathery backs of dreamers, those who left behind
what we knew in search of that which we could only imagine.

When we landed here, what did we find? Alley cat fights, squirrel skirmishes,
years of toil and torment clawing for a place in the pecking order.

Only thing thicker than the sweat and blood shed on this rock is the bond of the HOOD SQUAD.

We may have flown the coop we were raised in, but in ESP we found our chosen flock to soar with.

15 ‘hoods strong across all 5 boros, our strength is in our numbers.

Together, we reach new heights, claiming this gritty, Pigeon shitty
city as our home – but there’s a price to pay for all those who stay.

*/

contract Pigeon is
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
  uint16 public TOTAL_PIGEONS;
  uint16 public WITHHELD_PIGEONS;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  address ROYALTY_RECEIVER;
  uint8 royaltyPercentage;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize() public initializer {
    __ERC721_init("STAPLEVERSE - HOOD SQUAD", "PIGEON");
    __Pausable_init();
    __AccessControl_init();
    __Ownable_init();
    __ERC721Burnable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);

    TOTAL_PIGEONS = 6000;
    WITHHELD_PIGEONS = 1000;
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

  function poopGangWasHere(uint16 batchNumber, uint16 batchSize)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    // 💩 POOP GANG WAS HERE
    address poopGangVault = 0x6946589aFeE2A2Cdd8cEb2B505658c66C55a4Dc5;

    uint16 minTokenId = 5001 + batchSize * batchNumber;
    uint16 maxTokenId = 5000 + batchSize * (batchNumber + 1);

    require(
      minTokenId >= 5001,
      "Minimum token ID is outside allocated range"
    );
    require(
      maxTokenId <= 5500,
      "Maximum token ID is outside allocated range"
    );

    for (
      uint256 poopGangTokenId = minTokenId;
      poopGangTokenId <= maxTokenId;
      poopGangTokenId++
    ) {
      _safeMint(poopGangVault, poopGangTokenId);
    }
  }

  function withdrawWithheldTokens(
    address stapleverseVault,
    uint16 batchNumber,
    uint16 batchSize
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint16 minTokenId = 5601 + batchSize * batchNumber;
    uint16 maxTokenId = 5600 + batchSize * (batchNumber + 1);

    require(
      minTokenId >= 5601,
      "Minimum token ID is outside allocated range"
    );
    require(
      maxTokenId <= 6000,
      "Maximum token ID is outside allocated range"
    );

    for (uint256 tokenId = minTokenId; tokenId <= maxTokenId; tokenId++) {
      _safeMint(stapleverseVault, tokenId);
    }
  }

  function safeMint(address to) public onlyRole(MINTER_ROLE) {
    require(
      _tokenIdCounter.current() < TOTAL_PIGEONS - WITHHELD_PIGEONS,
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
    return (ROYALTY_RECEIVER, (_salePrice * royaltyPercentage) / 100);
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
    require(
      newRoyaltyPercentage <= 100,
      "Royalty percentage cannot be greater than 100"
    );
    royaltyPercentage = newRoyaltyPercentage;
  }

  function setBaseUri(string memory newUri)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    BASE_URI = newUri;
  }

  function tokensAvailable() public view returns (uint256) {
    return TOTAL_PIGEONS - WITHHELD_PIGEONS - _tokenIdCounter.current();
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
