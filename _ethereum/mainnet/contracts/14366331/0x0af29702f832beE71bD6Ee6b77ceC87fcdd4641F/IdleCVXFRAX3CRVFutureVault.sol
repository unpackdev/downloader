// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./HybridFutureVault.sol";
import "./IIdleCDO.sol";

/**
 * @title Contract for IDLE Finance Future
 * @notice Handles the future mechanisms for IDLE Finance ibt
 */
contract IDLECVXFRAX3CRVFutureVault is HybridFutureVault {
    IIdleCDO public constant IDLECDO_CVXFRAX3CRV = IIdleCDO(0x4CCaf1392a17203eDAb55a1F2aF3079A8Ac513E7);

    /**
     * @notice Getter for the rate of the IBT
     * @return the uint256 rate, IBT x rate must be equal to the quantity of underlying tokens
     */
    function getIBTRate() public view virtual override returns (uint256) {
        return IDLECDO_CVXFRAX3CRV.virtualPrice(address(ibt));
    }
}
