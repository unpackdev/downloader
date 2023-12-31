/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


interface IPriceFeedsExt {
  function latestAnswer() external view returns (int256);
}

contract DollarPegFeed is IPriceFeedsExt {
    function latestAnswer()
        external
        view
        returns (int256)
    {
        int256 rate = IPriceFeedsExt(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).latestAnswer();
        require(rate != 0 && (rate >> 128) == 0, "price error");
        return 1e26 / rate;
    }
}