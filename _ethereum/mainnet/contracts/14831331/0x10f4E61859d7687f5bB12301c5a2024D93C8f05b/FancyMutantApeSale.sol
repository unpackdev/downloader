// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./FancyV2Sale.sol";

contract FancyMutantApeSale is FancyV2Sale {
    constructor(
        IFancy721 _fancy721Contract,
        IFancyBears _fancyBearsContract,
        IHoneyToken _honeyTokenContract,
        IHive _hiveContract
    )
        FancyV2Sale(
            _fancy721Contract,
            _fancyBearsContract,
            _honeyTokenContract,
            _hiveContract
        )
    {}
}
