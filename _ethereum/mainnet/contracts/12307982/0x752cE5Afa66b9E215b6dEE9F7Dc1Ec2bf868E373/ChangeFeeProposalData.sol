// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IProposalData.sol";

contract ChangeFeeProposalData is IChangeFeeProposalData {
    address private token;
    address private pool;
    uint256 private feeDivisor;

    constructor(
        address _token,
        address _pool,
        uint256 _feeDivisor
    ) {
        token = _token;
        pool = _pool;
        feeDivisor = _feeDivisor;
    }

    function data()
        external
        view
        override
        returns (
            address,
            address,
            uint256
        )
    {
        return (token, pool, feeDivisor);
    }
}
