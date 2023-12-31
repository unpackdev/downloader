// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./BondedToken.sol";

contract BondedPION is BondedToken {
    function initialize(
        address _token,
        address _treasury
    ) external initializer {
        BondedToken._initialize(
            _token,
            _treasury,
            "Bonded PION NFT",
            "bonPION"
        );
    }
}
