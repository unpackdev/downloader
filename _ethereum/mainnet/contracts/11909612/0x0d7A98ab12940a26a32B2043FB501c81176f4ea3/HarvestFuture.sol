pragma solidity 0.7.6;

import "./RateFuture.sol";
import "./IiFarm.sol";

/**
 * @title Contract for yToken Future
 * @author Gaspard Peduzzi
 * @notice Handles the future mechanisms for iFarm
 * @dev Implement directly the stream future abstraction as it fits the iFarm IBT
 */
contract HarvestFuture is RateFuture {
    /**
     * @notice Getter for the rate of the IBT
     * @return the uint256 rate, IBT x rate must be equal to the quantity of underlying tokens
     */
    function getIBTRate() public view override returns (uint256) {
        return iFarm(address(ibt)).getPricePerFullShare();
    }
}
