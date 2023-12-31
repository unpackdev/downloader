// SPDX-License-Identifier: GPL-3.0-or-later
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
pragma solidity ^0.8.13;

import "./EnhancedVestingWallet.sol";

/**
 * @title EnhancedVestingWalletFactory
 * @dev Factory for EnhancedVestingWallet. See EnhancedVestingWallet.sol for details.
 */
contract EnhancedVestingWalletFactory {

    event VestingWalletCreated(
        address indexed walletAddress,
        address indexed ownerAddress,
        address indexed beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds
    );

    mapping(address => bool) private _isFromFactory;

    /**
     * @dev Creates a new EnhancedVestingWallet.
     */
    function create(
        address ownerAddress,
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds
    ) public virtual returns (address) {
        EnhancedVestingWallet wallet = new EnhancedVestingWallet(
            ownerAddress,
            beneficiaryAddress,
            startTimestamp,
            durationSeconds,
            cliffDurationSeconds
        );
        
        // Log publicly
        emit VestingWalletCreated(
            address(wallet),
            ownerAddress,
            beneficiaryAddress,
            startTimestamp,
            durationSeconds,
            cliffDurationSeconds
        );
        
        // Log locally
        _isFromFactory[address(wallet)] = true;
        
        return address(wallet);
    }

    /**
     * @dev Returns `true` if given `wallet` was created by this factory.
     */
    function isWalletFromFactory(address wallet) external view returns (bool) {
        return _isFromFactory[wallet];
    }
}
