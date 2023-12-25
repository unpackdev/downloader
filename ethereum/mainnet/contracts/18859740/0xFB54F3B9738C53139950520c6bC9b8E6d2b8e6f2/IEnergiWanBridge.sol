// Copyright 2023 Energi Core

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
//       match requirement.

pragma solidity 0.8.20;

interface IEnergiWanBridge {
  function deposit(address _tokenAddress, uint256 _amount, address _to, uint256 _chainId) external;

  function receiveTokens(
    address _from,
    address _to,
    uint256 _amount,
    address _tokenAddress,
    uint256 _chainId
  ) external;

  function updateTokenLockPeriod(uint256 _newTokenLockPeriod) external;

  function initialize(address energiWmbAppAddress_) external;

  function addToken(address _tokenAddress, bool _isBlacklisted, uint256 _minAmount) external;

  function blacklistToken(address _tokenAddress, bool _blacklist) external;

  function updateTokenMaxAmount(address _tokenAddress, uint256 _newMaxAmount) external;

  function updateEnergiWmbApp(address _newEnergiWmbApp) external;

  function updateMinAmountOfToken(address _tokenAddress, uint256 _newMinAmount) external;

  function addSupportedChainId(uint256 _chainId, bool _isSupported) external;

  function pause() external;

  function unpause() external;

  function getEnergiWmbApp() external view returns (address);

  function getVaultIds() external view returns (uint256);

  function getTokenLockPeriod() external view returns (uint256);

  function getIsTokenBlacklisted(address _tokenAddress) external view returns (bool);
}
