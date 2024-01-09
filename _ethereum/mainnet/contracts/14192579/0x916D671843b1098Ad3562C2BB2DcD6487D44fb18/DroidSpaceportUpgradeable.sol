// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

interface IDroidInvaders {
  function ownerOf(uint256 tokenId) external returns (address);

  function batchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds
  ) external;
}

contract DroidSpaceportUpgradeable is OwnableUpgradeable, UUPSUpgradeable {
  IDroidInvaders private droidInvadersContract;

  address[] internal _owners;

  bool public allowStaking;
  bool public allowUnstaking;

  function initialize(address _droidInvadersContract) public initializer {
    __Ownable_init();
    droidInvadersContract = IDroidInvaders(_droidInvadersContract);

    allowStaking = true;
    allowUnstaking = true;

    _owners = new address[](5500);
  }

  function unstake(uint256[] calldata _tokenIds) external {
    require(allowUnstaking, "Unstaking paused");
    require(_tokenIds.length > 0, "tokenIds must not be empty");

    for (uint256 i; i < _tokenIds.length; i++) {
      require(ownerOf(_tokenIds[i]) == _msgSender(), "Not token owner");

      _owners[_tokenIds[i]] = address(0);
    }

    droidInvadersContract.batchTransferFrom(
      address(this),
      _msgSender(),
      _tokenIds
    );
  }

  function stakeOf(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
      return new uint256[](0);
    }

    uint256[] memory tokensId = new uint256[](tokenCount);

    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensId;
  }

  function stake(uint256[] calldata _tokenIds) external {
    require(allowStaking, "Staking paused");
    require(_tokenIds.length > 0, "tokenIds must not be empty");

    for (uint256 i; i < _tokenIds.length; i++) {
      require(
        droidInvadersContract.ownerOf(_tokenIds[i]) == _msgSender(),
        "Not token owner"
      );

      _owners[_tokenIds[i]] = _msgSender();
    }

    droidInvadersContract.batchTransferFrom(
      _msgSender(),
      address(this),
      _tokenIds
    );
  }

  function balanceOf(address _owner) public view virtual returns (uint256) {
    require(_owner != address(0), "Zero address not allowed");

    uint256 count;

    for (uint256 i; i < _owners.length; ++i) {
      if (_owner == _owners[i]) {
        ++count;
      }
    }

    return count;
  }

  function ownerOf(uint256 _tokenId) public view virtual returns (address) {
    address owner = _owners[_tokenId];

    require(owner != address(0), "Token not staked");

    return owner;
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index)
    public
    view
    virtual
    returns (uint256 _tokenId)
  {
    require(_index < balanceOf(_owner), "Owner index out of bounds");

    uint256 count;

    for (uint256 i; i < _owners.length; i++) {
      if (_owner == _owners[i]) {
        if (count == _index) {
          return i;
        } else {
          count++;
        }
      }
    }

    revert("Owner index out of bounds");
  }

  function flipAllowStaking() external onlyOwner {
    allowStaking = !allowStaking;
  }

  function flipAllowUnstaking() external onlyOwner {
    allowUnstaking = !allowUnstaking;
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {} // solhint-disable-line no-empty-blocks
}
