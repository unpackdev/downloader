// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

import "./Racer.sol";

contract RacerRedeemer is AccessControlEnumerable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    uint256 public constant KEY = 1;
    mapping(address => uint256) public quantityRedeemed;

    uint256 internal _meltTokensPerRacer = 1000;
    uint256 private MAX_BATCH_SIZE = 100;
    address[] private _redeemers;

    Racer internal RACER;

    constructor(address racerAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        RACER = Racer(racerAddress);
    }

    function redeemRacers(
        address[] memory redeemerList,
        uint256[] memory dnaList
    ) public onlyRole(MANAGER_ROLE) {
        require(
            redeemerList.length <= MAX_BATCH_SIZE,
            "Max batch size exceeded"
        );
        require(
            redeemerList.length == dnaList.length,
            "input arrays must be same length"
        );
        for (uint256 i = 0; i < redeemerList.length; i++) {
            if (quantityRedeemed[redeemerList[i]] == 0) {
                _redeemers.push(redeemerList[i]);
            }
            uint256 meltTokens = _meltTokensPerRacer * 10**18;
            RACER.newToken(dnaList[i], redeemerList[i], meltTokens);
            quantityRedeemed[redeemerList[i]]++;
        }
    }

    function setTokensPerRacer(uint256 numWholeTokens)
        public
        onlyRole(MANAGER_ROLE)
    {
        _meltTokensPerRacer = numWholeTokens;
    }

    function setMaxBatchSize(uint256 batchSize) public onlyRole(MANAGER_ROLE) {
        MAX_BATCH_SIZE = batchSize;
    }

    function getRedeemersQuantitiesInRange(uint256 startIndex, uint256 endIndex)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        return (
            getRedeemersInRange(startIndex, endIndex),
            getRedeemedQuantitiesInRange(startIndex, endIndex)
        );
    }

    function getRedeemersInRange(uint256 startIndex, uint256 endIndex)
        public
        view
        returns (address[] memory)
    {
        require(startIndex < _redeemers.length, "start index too high");
        uint256 maxIndex = endIndex > _redeemers.length - 1
            ? _redeemers.length - 1
            : endIndex;
        uint256 minIndex = startIndex < maxIndex ? startIndex : 0;
        uint256 size = maxIndex - minIndex + 1;
        address[] memory redeemers = new address[](size);
        for (uint256 i = minIndex; i < size + minIndex; i++) {
            redeemers[i - minIndex] = _redeemers[i];
        }

        return redeemers;
    }

    function getRedeemedQuantitiesInRange(uint256 startIndex, uint256 endIndex)
        public
        view
        returns (uint256[] memory)
    {
        uint256 maxIndex = endIndex > _redeemers.length - 1
            ? _redeemers.length - 1
            : endIndex;
        uint256 minIndex = startIndex < maxIndex ? startIndex : 0;
        uint256 size = maxIndex - minIndex + 1;
        uint256[] memory quantities = new uint256[](size);
        for (uint256 i = minIndex; i < size + minIndex; i++) {
            quantities[i - minIndex] = quantityRedeemed[_redeemers[i]];
        }
        return quantities;
    }
}
