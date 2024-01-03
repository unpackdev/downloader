pragma solidity >=0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

import "./IERC20.sol";

library TraderDiscount {
    function calculateDiscount(uint tokenAmount) internal pure returns (uint k)  {
        k = 4;
        tokenAmount = tokenAmount / (10 ** 18);
        if (tokenAmount < 1 ) {
            k = 10;
        } else if (tokenAmount >= 1 && tokenAmount <= 5) {
            k = 9;
        } else if (tokenAmount > 5 && tokenAmount <= 10) {
            k = 8;
        } else if (tokenAmount > 10 && tokenAmount <= 20) {
            k = 7;
        } else if (tokenAmount > 20 && tokenAmount <= 50) {
            k = 6;
        } else if (tokenAmount > 50 && tokenAmount <= 100) {
            k = 5;
        }
    }
}
