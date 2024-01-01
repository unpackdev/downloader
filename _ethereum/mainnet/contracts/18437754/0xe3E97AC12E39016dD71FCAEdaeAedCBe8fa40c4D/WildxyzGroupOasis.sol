// SPDX-License-Identifier: GPL-3.0-or-later

// ░██╗░░░░░░░██╗░██╗░██╗░░░░░░██████╗░░██╗░░██╗░██╗░░░██╗░███████╗
// ░██║░░██╗░░██║░██║░██║░░░░░░██╔══██╗░╚██╗██╔╝░╚██╗░██╔╝░╚════██║
// ░╚██╗████╗██╔╝░██║░██║░░░░░░██║░░██║░░╚███╔╝░░░╚████╔╝░░░░███╔═╝
// ░░████╔═████║░░██║░██║░░░░░░██║░░██║░░██╔██╗░░░░╚██╔╝░░░██╔══╝░░
// ░░╚██╔╝░╚██╔╝░░██║░███████╗░██████╔╝░██╔╝╚██╗░░░░██║░░░░███████╗
// ░░░╚═╝░░░╚═╝░░░╚═╝░╚══════╝░╚═════╝░░╚═╝░░╚═╝░░░░╚═╝░░░░╚══════╝

// It ain't much, but it's honest work.

pragma solidity ^0.8.17;

import "./IOasis.sol";

import "./WildxyzGroup.sol";

abstract contract WildxyzGroupOasis is WildxyzGroup {

  uint256 public groupId_Oasis;

  /// @notice Oasis NFT address.
  IOasis public oasis;

  mapping(address => uint256) public addressTotalOasisSupply; // oasis specific total minted

  uint256 public maxPerOasis;

  mapping(uint256 => uint8) private oasisPassMints;

  // setup

  function _setupGroupOasis(uint256 _startTime, uint256 _endTime, uint256 _price, uint256 _reserveSupply, IOasis _oasis, uint256 _maxPerOasis) internal {
    groupId_Oasis = _createGroup('Oasis', _startTime, _endTime, _price, _reserveSupply);
    
    oasis = _oasis;
    maxPerOasis = _maxPerOasis;
  }

  // callback to override to implement minting/purchase logic

  function _processUseOasisCallback(address _receiver) internal virtual returns (uint256 tokenId) {}

  // internal helpers

  function _getOasisMintAllowance(address _oasisOwner, uint256 _oasisBalance) internal view returns (uint256 quantity) {
    for (uint256 i = 0; i < _oasisBalance; i++) {
      uint256 oasisId = oasis.tokenOfOwnerByIndex(_oasisOwner, i);
      quantity += (maxPerOasis > oasisPassMints[oasisId] ? maxPerOasis - oasisPassMints[oasisId] : 0);
    }
  }

  function _processUseOasis(address _receiver, address _requester, uint256 _amount) internal virtual returns (uint256[] memory tokenIds, uint256[] memory oasisIds) {
    uint256 oasisBalance = oasis.balanceOf(_requester);

    if (_getOasisMintAllowance(_requester, oasisBalance) == 0) revert ZeroOasisAllowance(_receiver);

    uint256 mintsLeft = _amount;
    uint256 totalMinted = 0;

    tokenIds = new uint256[](_amount);
    oasisIds = new uint256[](_amount);

    for (uint256 i = 0; i < oasisBalance; i++) {
      uint256 oasisId = oasis.tokenOfOwnerByIndex(_requester, i);
      uint256 tokenAllowance = maxPerOasis - oasisPassMints[oasisId];

      if (tokenAllowance == 0) {
        // Oasis pass been fully minted
        continue;
      }

      uint8 quantityMintedWithOasis = uint8(Math.min(tokenAllowance, mintsLeft));

      oasisPassMints[oasisId] += quantityMintedWithOasis;
      mintsLeft -= quantityMintedWithOasis;

      for (uint256 j = 0; j < quantityMintedWithOasis; j++) {
        uint256 tokenId = _processUseOasisCallback(_receiver);

        tokenIds[totalMinted + j] = tokenId;
        oasisIds[totalMinted + j] = oasisId;
      }

      totalMinted += quantityMintedWithOasis;
    }

    if (mintsLeft != 0) revert NotEnoughOasisMints(_requester);
  }

  function _addOasisTotalSupply(address _receiver, uint256 _amount) internal virtual {
    // just in case they move their oasis and try to get into a different group
    _addAddressTotalSupply(_receiver, _amount);

    addressTotalOasisSupply[_receiver] += _amount;
  }

  // overrides
  
  function getUserGroupAllowance(address _user, uint256 _groupId) public view virtual override returns (uint256) {
    uint256 supplyRemaining = _remainingSupply();
    if (supplyRemaining == 0) {
      return 0;
    }

    uint256 oasisBalance = oasis.balanceOf(_user);

    if (oasisBalance > 0 || _groupId == groupId_Oasis) {
      // Y = # oasis * S (S = maxPerOasis)
      if (oasisBalance > 0) {
        // if user owns oasis, count max allowance as num. oasis * maxPerOasis
        return Math.min(_getOasisMintAllowance(_user, oasisBalance), supplyRemaining);
      }

      return 0;
    }

    // Y = R (R = maxPerAddress)
    return Math.min(maxPerAddress - addressTotalSupply[_user], supplyRemaining);
  }

  function getUserGroupTotalSupply(address _user, uint256 _groupId) public view virtual override returns (uint256) {
    if (_groupId == groupId_Oasis) {
      return addressTotalOasisSupply[_user];
    } else {
      return addressTotalSupply[_user];
    }
  }

  // only admin functions

  function setMaxPerOasis(uint256 _maxPerOasis) public onlyAdmin {
    maxPerOasis = _maxPerOasis;
  }
}