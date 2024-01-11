// contracts/CLv1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";
import "./IERC20.sol";

contract CLv1 {
    IERC20 public WBTC;
    AggregatorV3Interface public PoR_WBTC;

    function setup(IERC20 _wbtc, AggregatorV3Interface _porWBTC) public {
        require(
            address(WBTC) == address(0x0),
            "setup() already executed"
        );
        WBTC = _wbtc;
        PoR_WBTC = _porWBTC;
    }

    function checkLatestRoundDataPoRWBTC()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = PoR_WBTC
            .latestRoundData();
    }

    function verifyPoRWBTC() external view returns (bool result) {
        (, int256 reserveProof, , , ) = checkLatestRoundDataPoRWBTC();
        if (reserveProof >= int256(WBTC.totalSupply())) {
            return result = true;
        }
    }
}
