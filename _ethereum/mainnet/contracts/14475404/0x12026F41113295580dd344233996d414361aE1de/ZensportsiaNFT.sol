// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./ERC721Manageable.sol";
import "./RoyaltyBase.sol";

contract ZensportsiaNFT is
  Initializable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  RoyaltyBase,
  ERC721Manageable
{
  // Upgrade functions
  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _baseTokenURI
  ) public initializer {
    __Ownable_init();
    __ERC721_init_unchained(_name, _symbol);
    _setBaseURI(_baseTokenURI);
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  function upgrade(string memory _baseTokenURI) public onlyOwner {
    _setBaseURI(_baseTokenURI);
  }

  function mint(uint256 _numberOfItems) external payable override nonReentrant {
    if (isPresale()) {
      _presaleMint(_numberOfItems);
    } else if (isPubsale()) {
      _publicMint(_numberOfItems);
    } else {
      revert("MINTING NOT ALLOWED");
    }
  }

  function mintForTeam(address[] calldata _accounts, uint256[] calldata _allocations)
    external
    override
    onlyOwner
  {
    require(_accounts.length > 0 && _accounts.length == _allocations.length, "INVALID ARGUMENTS");
    uint256 totalAllocations = 0;
    for (uint256 i = 0; i < _allocations.length; i++) {
      totalAllocations = totalAllocations + _allocations[i];
    }
    require(totalAllocations <= salePlans.teamAllocation, "TEAM ALLOCATION EXCEEDED");

    uint256 mintId = 0;
    for (uint256 j = 0; j < _allocations.length; j++) {
      address account = _accounts[j];
      whitelists[account] = true;
      for (uint256 k = 0; k < _allocations[j]; k++) {
        mintId = mintId + 1;
        _mint(account, mintId);
      }
    }
  }

  function mintForTeam2(
    address[] calldata _accounts,
    uint256[] calldata _allocations,
    uint256 _offset
  ) external onlyOwner {
    uint256 mintId = _offset;
    for (uint256 j = 0; j < _allocations.length; j++) {
      address account = _accounts[j];
      for (uint256 k = 0; k < _allocations[j]; k++) {
        mintId = mintId + 1;
        _mint(account, mintId);
      }
    }
  }

  function isPresale() public view returns (bool) {
    uint256 duration = 1 days;
    return
      block.timestamp >= salePlans.startTime && block.timestamp <= salePlans.startTime + duration;
  }

  function isPubsale() public view returns (bool) {
    uint256 duration = 1 days;
    return block.timestamp >= salePlans.startTime + 2 * duration;
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    // Save original nft creators for royalty calculation
    if (from == address(0)) {
      creators[tokenId] = to;
    }
  }
}
