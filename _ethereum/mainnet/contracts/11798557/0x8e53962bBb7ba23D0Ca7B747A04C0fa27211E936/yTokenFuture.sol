pragma solidity 0.7.6;

import "./RateFuture.sol";
import "./IyToken.sol";

/**
 * @title Contract for yToken Future
 * @author Gaspard Peduzzi
 * @notice Handles the future mechanisms for the Aave platform
 * @dev Implement directly the stream future abstraction as it fits the aToken IBT
 */
contract yTokenFuture is RateFuture {
    /**
     * @notice Getter for the rate of the IBT
     * @return the uint256 rate, IBT x rate must be equal to the quantity of underlying tokens
     */
    function getIBTRate() public view override returns (uint256) {
        return yToken(address(ibt)).getPricePerFullShare();
    }
}
