//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Staked.sol";
import "./Delegatable.sol";
import "./ERC721Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

abstract contract ERC721Staked is
  IERC721Staked,
  ERC721Upgradeable,
  Delegatable,
  ReentrancyGuardUpgradeable
{
  uint256 public constant DEFAULT_LOCK_DURATION = 60 * 60 * 24 * 7; // 7 days

  uint256 public constant MINT_ROLE = 1;
  uint256 public constant BURN_ROLE = 2;
  uint256 public constant TRANSFER_ROLE = 4;
  uint256 public constant LOCK_ROLE = 8;

  mapping(uint256 => uint256) public lockDurations;
  mapping(uint256 => Lease) private leases;

  struct Lease {
    address provenance;
    uint48 lockExpiration;
  }

  function __ERC721Staked_init(string memory name_, string memory symbol_)
    internal
    initializer
  {
    __ERC721_init(name_, symbol_);
    __Ownable_init_unchained();
    __Delegatable_init_unchained();
    __ReentrancyGuard_init_unchained();
  }

  function __ERC721Staked_init_unchained() internal initializer {}

  /*
  WRITE FUNCTIONS
  */

  function mint(address to, uint256 tokenId)
    external
    virtual
    override
    onlyDelegate(MINT_ROLE)
    nonReentrant
  {
    _safeMint(to, tokenId);
  }

  function burn(uint256 tokenId)
    external
    virtual
    override
    onlyDelegate(BURN_ROLE)
  {
    _burn(tokenId);
  }

  function setLockDuration(uint256 tokenId, uint256 lockDuration)
    external
    virtual
    override
    onlyDelegate(LOCK_ROLE)
  {
    lockDurations[tokenId] = lockDuration;
  }

  function revoke(uint256 tokenId) external virtual override {
    address provenance = leases[tokenId].provenance;
    require(provenance == msg.sender, "Caller is not provenance");
    _transfer(ownerOf(tokenId), provenance, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    address sender = _msgSender();
    require(
      _isApprovedOrOwner(sender, tokenId) || hasRoles(sender, TRANSFER_ROLE),
      "ERC721: transfer caller is not owner nor approved"
    );

    _transfer(from, to, tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    // don't set lease on mint to save gas, getLease will handle lease
    // ownership
    if (from == address(0)) {
      return;
    }

    Lease memory lease = getLease(tokenId);
    // prevent lease owner from unstaking locked tokens
    require(
      msg.sender == from || block.timestamp >= uint256(lease.lockExpiration),
      "Token is locked in lease"
    );

    if (to == address(0)) {
      // remove lease on burn
      delete leases[tokenId];
    } else if (from != to) {
      if (from == lease.provenance) {
        // set lease lock on transfer from provenance to another
        uint256 lockDuration = getLockDuration(tokenId);
        leases[tokenId] = Lease(
          lease.provenance,
          uint48(block.timestamp + lockDuration)
        );
      } else if (to == lease.provenance) {
        // remove lock on transfer from another to provenance
        leases[tokenId] = Lease(lease.provenance, 0);
      }
    }
  }

  /*
  READ FUNCTIONS
  */

  function getLease(uint256 tokenId) public view returns (Lease memory lease) {
    lease = leases[tokenId];
    // lease provenance is null and token exist only on initial mint
    if (lease.provenance == address(0) && _exists(tokenId)) {
      lease.provenance = ownerOf(tokenId);
    }
  }

  function getLockDuration(uint256 tokenId)
    public
    view
    returns (uint256 lockDuration)
  {
    lockDuration = lockDurations[tokenId];
    if (lockDuration == 0) {
      lockDuration = DEFAULT_LOCK_DURATION;
    }
  }
}
