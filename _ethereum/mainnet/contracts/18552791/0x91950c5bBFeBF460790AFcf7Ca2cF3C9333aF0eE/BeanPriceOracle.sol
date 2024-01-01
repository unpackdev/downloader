// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Constants.sol";
import "./ICustomOracle.sol";
import "./IBeanstalkPrice.sol";

contract BeanPriceOracle is ICustomOracle {
    /**
     * @notice Get latest oracle price of BEAN normalized to 1e18
     * @dev Use beanstalk price (decimals of beanstalk price is 6, so we multiply 10**12)
     * @return price latest BEAN price
     */
    function latestPrice() external view returns (uint256 price) {
        return IBeanstalkPrice(Constants.BEANSTALK_PRICE).price().price * 1e12;
    }
}
