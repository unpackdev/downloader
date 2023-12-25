//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ISharesManagerV1.sol";

/**
 * @title UnderlyingToSupplyRatio
 * @dev A helper contract that uses Liquid Collective's SharesManagerV1 to calculate
 * the ratio between the total underlying supply of a token and the total supply of
 * the token. This contract assists in determining the proportion of the token's
 * supply that is backed by underlying assets, providing insights into the token's
 * collateralization level.
 *
 * @notice This contract does not perform modifications to the underlying supply or
 * total supply of tokens but serves as a utility for obtaining the supply ratio.
 *
 * @dev To use this contract, call the `getSupplyRatio` function to
 * retrieve the calculated ratio between underlying supply and total supply.
 */
contract UnderlyingToSupplyRatio {
    // SafeMath for uint
    using SafeMath for uint;

    // State Variables
    ISharesManagerV1 internal aProxy;

    constructor(address _aProxyAddress) {
        aProxy = ISharesManagerV1(_aProxyAddress); // get instance of TUPProxy interface
    }

    /**
     * @dev Compute the ratio between the total underlying supply of a token and the
     * total supply of the token using Liquid Collective's SharesManagerV1.
     * @return ratioTimesMillion (uint256) the ratio of `underlyingSupply` to `totalSupply` times million for precision.
     * @notice Retrieve the ratio of `underlyingSupply` to `totalSupply` times million for precision.
     */
    function getSupplyRatio() public view returns (uint256 ratioTimesMillion) {
        if (aProxy.totalSupply() == 0) {
            revert("Total Supply Cannot Be 0!");
        }
        uint256 totalSupply = aProxy.totalSupply();
        uint256 totalUnderlyingSupply = (aProxy.totalUnderlyingSupply()).mul(10**6); // mul by 1 mil
        
        // Using SafeMath
        ratioTimesMillion = (totalUnderlyingSupply.div(totalSupply));
        
        return ratioTimesMillion;
    }
}
