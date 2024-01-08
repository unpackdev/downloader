// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./MarzLand.sol";

contract MarzMint {
    address private marz;

    constructor(address _marz) {
        marz = _marz;
    }

    function claim(address to, uint256[] calldata plotIds) external {
        MarzLand _marz = MarzLand(marz);

        for (uint256 i = 0; i < plotIds.length; i++) {
            if (!_marz.exists(plotIds[i])) {
                _marz.claimTo(to, plotIds[i]);
            }
        }
    }

    function claimBlock(address to, uint256 start, uint256 width, uint256 height) external {
        MarzLand _marz = MarzLand(marz);

        for (uint256 i = 0; i < height; i++) {
            for (uint256 j = 0; j < width; j++) {
                uint256 plotId = start + (i * 200) + j;
                if (!_marz.exists(plotId)) {
                    _marz.claimTo(to, plotId);
                }
            }
        }
    }
}
