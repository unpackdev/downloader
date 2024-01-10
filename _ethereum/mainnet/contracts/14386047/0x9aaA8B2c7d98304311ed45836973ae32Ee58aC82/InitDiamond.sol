// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./LibAppStorage.sol";
import "./LibDistribution.sol";
import "./LibDiamond.sol";

struct Args {
    address metaNFT;
    address stakingContract;
    address uniV3Pos;
    address uniV3Factory;
    address weth;
    address pil;
    uint32 rewardEpoch;
}

contract InitDiamond {
    AppStorage internal s;

    function init(Args memory _args) external {
        s.metaNFT = _args.metaNFT;
        s.stakingContract = _args.stakingContract;
        s.uniV3Pos = _args.uniV3Pos;
        s.uniV3Factory = _args.uniV3Factory;
        s.weth = _args.weth;
        s.pil = _args.pil;
        s.rewardEpoch = _args.rewardEpoch;

        s.bidTimeout = 6 hours;

        LibDiamond.diamondStorage();
    }
}
