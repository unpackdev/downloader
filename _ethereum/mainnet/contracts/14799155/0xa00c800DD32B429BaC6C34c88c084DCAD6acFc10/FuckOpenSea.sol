// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./NFTSale.sol";

contract FuckOpenSea is NFTSale {
    string private constant _NAME = "FuckOpenSea";
    string private constant _SYMBOL = "FUCK";
    string private constant _INIT_BASE_URI = "ipfs://QmaGwtjATFRaZgTnjvDBnqDoPhsGGUm1bK3WmqPJzHr2Bn/";

    constructor() NFTSale(_NAME, _SYMBOL, _INIT_BASE_URI) {}
}
