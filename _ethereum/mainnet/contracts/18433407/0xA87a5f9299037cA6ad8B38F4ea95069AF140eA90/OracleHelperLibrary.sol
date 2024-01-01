// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library OracleHelperLibrary {
    struct SecurityParams {
        uint32[] secondsAgos;
        int24 maxDeviation;
    }

    function mevSecurityParams(uint24 fee) external pure returns (bytes memory) {
        if (fee <= 100) {
            uint32[] memory secondsAgos001 = new uint32[](3);
            secondsAgos001[0] = 10;
            secondsAgos001[1] = 30;
            secondsAgos001[2] = 60;
            int24 maxDeviation001 = 20;
            return abi.encode(SecurityParams({secondsAgos: secondsAgos001, maxDeviation: maxDeviation001}));
        }

        if (fee <= 500) {
            uint32[] memory secondsAgos005 = new uint32[](2);
            secondsAgos005[0] = 10;
            secondsAgos005[1] = 60;
            int24 maxDeviation005 = 50;
            return abi.encode(SecurityParams({secondsAgos: secondsAgos005, maxDeviation: maxDeviation005}));
        }

        if (fee <= 3000) {
            uint32[] memory secondsAgos03 = new uint32[](2);
            secondsAgos03[0] = 10;
            secondsAgos03[1] = 60;
            int24 maxDeviation03 = 100;
            return abi.encode(SecurityParams({secondsAgos: secondsAgos03, maxDeviation: maxDeviation03}));
        }

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = 10;
        secondsAgos[1] = 60;
        int24 maxDeviation = 200;
        return abi.encode(SecurityParams({secondsAgos: secondsAgos, maxDeviation: maxDeviation}));
    }
}
