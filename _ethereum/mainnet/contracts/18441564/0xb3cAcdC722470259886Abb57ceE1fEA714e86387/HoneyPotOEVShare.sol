// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./BoundedUnionSourceAdapter.sol";
import "./BaseController.sol";
import "./ChainlinkDestinationAdapter.sol";
import "./IAggregatorV3Source.sol";
import "./IMedian.sol";
import "./IPyth.sol";

contract HoneyPotOEVShare is BaseController, BoundedUnionSourceAdapter, ChainlinkDestinationAdapter {
    constructor(
        address chainlinkSource,
        address chronicleSource,
        address pythSource,
        bytes32 pythPriceId,
        uint8 decimals
    )
        BoundedUnionSourceAdapter(
            IAggregatorV3Source(chainlinkSource),
            IMedian(chronicleSource),
            IPyth(pythSource),
            pythPriceId,
            0.1e18
        )
        BaseController()
        ChainlinkDestinationAdapter(decimals)
    {}
}
