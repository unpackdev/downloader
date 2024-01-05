// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface ICreatePoolProposalData {
    function data()
        external
        view
        returns (
            string memory,
            string memory,

            uint256,
            uint256,
            uint256,
            uint256,
            uint256,

            address
        );
}

interface IChangeFeeProposalData {
    function data()
        external
        view
        returns (
            address,
            address,
            uint256
        );
}

interface IFundProjectProposalData {
    function data()
        external
        view
        returns (
            address,
            string memory,
            uint256
        );
}

interface IUpdateAllowlistProposalData {
    function data()
        external
        view
        returns (
            address,
            address,
            bool
        );
}
