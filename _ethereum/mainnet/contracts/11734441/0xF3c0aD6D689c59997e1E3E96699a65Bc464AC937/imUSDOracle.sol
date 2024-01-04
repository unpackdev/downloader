// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./IOracle.sol";
import "./Decimal.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IimUSD.sol";
import "./ICurve.sol";

/* solium-disable-next-line */
contract imUSDOracle is IOracle {

    using SafeMath for uint256;

    address public imUSDAddress = 0x30647a72Dc82d7Fbb1123EA74716aB8A317Eac19;
    address public mUSDCrvPoolAddress = 0x8474DdbE98F5aA3179B3B3F5942D724aFcdec9f6;

    function fetchCurrentPrice()
        external
        view
        returns (Decimal.D256 memory)
    {
        uint256 amountOfmUSDPerimUSD = IimUSD(imUSDAddress).creditsToUnderlying(10 ** 18);

        // Price of 1 mUSD in USD
        uint256 mUSDPrice = ICurve(mUSDCrvPoolAddress).get_virtual_price();

        uint256 result = amountOfmUSDPerimUSD.mul(mUSDPrice).div(10 ** 18);

        require (
            result > 0,
            "CurvePool: cannot report a price of 0"
        );

        return Decimal.D256({
            value: result
        });
    }
}
