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

import "./VestingWallet.sol";

/**
 * @title VestingWalletWithReleaseGuard
 * @dev This contract builds on OpenZeppelin's VestingWallet. See comments in VestingWallet for base details.
 *
 * This contract adds the following functionality:
 *   - Add a release guard: only `beneficiary` can release vested funds; no one can force funds upon `beneficiary`
 */
abstract contract VestingWalletWithReleaseGuard is VestingWallet {

    error CallerIsNotBeneficiary();

    /**
     * @dev Throws if called by any account other than the beneficiary.
     */
    modifier onlyBeneficiary() {
        if (beneficiary() != msg.sender) {
            revert CallerIsNotBeneficiary();
        }
        _;
    }

    /**
     * @dev Override of VestingWallet's `release` to enforce that the caller must be the beneficiary.
     */
    function release() public virtual override onlyBeneficiary {
        super.release();
    }

    /**
     * @dev Override of VestingWallet's `release` to enforce that the caller must be the beneficiary.
     */
    function release(address token) public virtual override onlyBeneficiary {
        super.release(token);
    }
}
