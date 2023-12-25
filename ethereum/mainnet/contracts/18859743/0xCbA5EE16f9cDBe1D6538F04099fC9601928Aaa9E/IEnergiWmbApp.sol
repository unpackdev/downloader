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

interface IEnergiWmbApp {
  function sendMessage(
    address _from,
    address _to,
    uint256 _amount,
    address _tokenAddress,
    uint256 _chainId,
    uint256 _gasLimit
  ) external;

  function receiveMessege(
    address _from,
    address _to,
    uint256 _amount,
    address _tokenAddress
  ) external;

  function setEnergyWanBridgeAddress(address _newEnergyWanBridgeAddress) external;

  function pause() external;

  function unpause() external;

  function getEnergyWanBridgeAddress() external view returns (address);

  function getEstimatedFees(uint256 _chainId, uint256 _gasLimit) external view returns (uint256);
}
