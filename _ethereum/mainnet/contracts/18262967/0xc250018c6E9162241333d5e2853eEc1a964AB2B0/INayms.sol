// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable no-empty-blocks

import "./IDiamondCut.sol";
import "./IDiamondLoupe.sol";
import "./IERC165.sol";
import "./IERC173.sol";

import "./IACLFacet.sol";
import "./IUserFacet.sol";
import "./IAdminFacet.sol";
import "./ISystemFacet.sol";
import "./INaymsTokenFacet.sol";
import "./ITokenizedVaultFacet.sol";
import "./ITokenizedVaultIOFacet.sol";
import "./IMarketFacet.sol";
import "./IEntityFacet.sol";
import "./ISimplePolicyFacet.sol";
import "./IGovernanceFacet.sol";

/**
 * @title Nayms Diamond
 * @notice Everything is a part of one big diamond.
 * @dev Every facet should be cut into this diamond.
 */
interface INayms is
    IDiamondCut,
    IDiamondLoupe,
    IERC165,
    IERC173,
    IACLFacet,
    IAdminFacet,
    IUserFacet,
    ISystemFacet,
    INaymsTokenFacet,
    ITokenizedVaultFacet,
    ITokenizedVaultIOFacet,
    IMarketFacet,
    IEntityFacet,
    ISimplePolicyFacet,
    IGovernanceFacet
{

}
