// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <council@enzyme.finance>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "./IExternalPosition.sol";

pragma solidity >=0.6.0 <0.9.0;

/// @title ICompoundDebtPosition Interface
/// @author Enzyme Council <security@enzyme.finance>
interface ICompoundDebtPosition is IExternalPosition {
    enum ExternalPositionActions {
        AddCollateral,
        RemoveCollateral,
        Borrow,
        RepayBorrow,
        ClaimComp
    }

    function getCTokenFromBorrowedAsset(address _borrowedAsset) external view returns (address cToken_);
}
