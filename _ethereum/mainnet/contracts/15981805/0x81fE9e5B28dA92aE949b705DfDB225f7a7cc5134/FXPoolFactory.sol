// SPDX-License-Identifier: MIT

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
pragma experimental ABIEncoderV2;

pragma solidity ^0.7.3;

import "./FXPool.sol";
import "./IVault.sol";
import "./Ownable.sol";

contract FXPoolFactory is Ownable {
    struct FXPoolData {
        address poolAddress;
        bytes32 poolId;
    }

    /// @dev Event emitted after fx pool creation
    /// @param caller fxpool creator
    /// @param id fxpool id for the factory not poolId in balancer
    /// @param fxpool fxpool address
    event NewFXPool(address indexed caller, bytes32 indexed id, address indexed fxpool);

    mapping(bytes32 => FXPoolData[]) public pools;

    /// @dev get the current active fxpool address, last index
    /// @param _assets array for assets to register. this must be in vault's order
    function getActiveFxPool(address[] memory _assets) external view returns (address) {
        // must follow balancer vault's ordering
        bytes32 fxPoolId = keccak256(abi.encode(_assets[0], _assets[1]));
        return (pools[fxPoolId][pools[fxPoolId].length - 1].poolAddress);
    }

    /// @dev get the current active fxpool address
    /// @param _assets array for assets to register. this must be in vault's order
    function getFxPools(address[] memory _assets) external view returns (FXPoolData[] memory) {
        // must follow balancer vault's ordering
        bytes32 fxPoolId = keccak256(abi.encode(_assets[0], _assets[1]));
        return (pools[fxPoolId]);
    }

    /// @dev deploy new curve
    /// @param _name BPT name
    /// @param _symbol BPT symbol
    /// @param _percentFee todo
    /// @param vault balancer vault
    /// @param _assetsToRegister array for assets to register. this must be in vault's order
    function newFXPool(
        string memory _name,
        string memory _symbol,
        uint256 _percentFee,
        IVault vault,
        address[] memory _assetsToRegister
    ) public onlyOwner returns (bytes32) {
        // must follow balancer vault's ordering
        bytes32 fxPoolId = keccak256(abi.encode(_assetsToRegister[0], _assetsToRegister[1]));

        // New curve
        FXPool fxpool = new FXPool(_assetsToRegister, vault, _percentFee, _name, _symbol);
        bytes32 balancerPoolId = fxpool.getPoolId();

        FXPoolData memory newFxPoolData;
        newFxPoolData.poolAddress = address(fxpool);
        newFxPoolData.poolId = balancerPoolId;

        pools[fxPoolId].push(newFxPoolData);

        fxpool.transferOwnership(msg.sender);

        emit NewFXPool(msg.sender, balancerPoolId, address(fxpool));

        return balancerPoolId;
    }
}
