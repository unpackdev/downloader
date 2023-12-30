// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

interface IOptIn {
    struct OptInStatus {
        bool isOptedIn;
        bool permaBoostActive;
        address optedInTo;
        uint32 optOutPeriod;
    }

    function getOptInStatusPair(address accountA, address accountB)
        external
        view
        returns (OptInStatus memory, OptInStatus memory);

    function getOptInStatus(address account)
        external
        view
        returns (OptInStatus memory);

    function isOptedInBy(address _sender, address _account)
        external
        view
        returns (bool, uint256);
}
