// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
import "./HybridFutureVault.sol";
import "./IgOHM.sol";

/**
 * @title Contract for Paladin Future
 * @notice Handles the future mechanisms for palStTokens
 */
contract gOHMFutureVault is HybridFutureVault {
    using SafeMathUpgradeable for uint256;

    IgOHM public constant gOHM = IgOHM(0x0ab87046fBb341D058F17CBC4c1133F25a20a52f);

    /**
     * @notice Getter for the rate of the IBT
     * @return the uint256 rate, IBT x rate must be equal to the quantity of underlying tokens
     */
    function getIBTRate() public view virtual override returns (uint256) {
        return gOHM.index().mul(IBT_UNIT);
    }
}
