//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Multicall.sol";
import "./Ownable.sol";
import "./draft-IERC20Permit.sol";
import "./IBribeMultiAssetPool.sol";
import "./IFeeDistributor.sol";

////////////////////////////////////////////////////////////////////////////////////////////
///
/// @title BribePoolBase
/// @author contact@bribe.xyz
/// @notice
///
////////////////////////////////////////////////////////////////////////////////////////////

abstract contract BribePoolBase is IBribeMultiAssetPool, IFeeDistributor, Ownable, Multicall {
    constructor() Ownable() {}

    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    //  Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20Permit token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}
