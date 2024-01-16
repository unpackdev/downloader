// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ICompetitionPool {
    struct Bet {
        address competionContract;
        uint256[] betIndexs;
    }

    struct Pool {
        Type competitonType;
        bool existed;
    }

    enum Type {
        Regular,
        P2P,
        Guarantee
    }

    function fee() external view returns(uint256);

    function tokenAddress() external view returns(address);

    function refundable(address _betting) external view returns (bool);

    function isCompetitionExisted(address _pool) external returns (bool);

    function getMaxTimeWaitForRefunding() external view returns (uint256);
}
