// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IProposalData.sol";

contract UpdateAllowlistProposalData is IUpdateAllowlistProposalData {
    address private token;
    address private pool;
    bool private newStatus;

    constructor(
        address _token,
        address _pool,
        bool _newStatus
    ) {
        token = _token;
        pool = _pool;
        newStatus = _newStatus;
    }

    function data()
        external
        view
        override
        returns (
            address,
            address,
            bool
        )
    {
        return (token, pool, newStatus);
    }
}
