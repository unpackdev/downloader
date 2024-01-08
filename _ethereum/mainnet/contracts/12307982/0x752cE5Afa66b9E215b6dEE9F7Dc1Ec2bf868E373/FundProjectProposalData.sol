// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IProposalData.sol";

contract FundProjectProposalData is IFundProjectProposalData {
    address private receiver;
    string private descriptionUrl;
    uint256 private ethAmount;

    constructor(
        address _receiver,
        string memory _descriptionUrl,
        uint256 _ethAmount
    ) {
        receiver = _receiver;
        descriptionUrl = _descriptionUrl;
        ethAmount = _ethAmount;
    }

    function data()
        external
        view
        override
        returns (
            address,
            string memory,
            uint256
        )
    {
        return (receiver, descriptionUrl, ethAmount);
    }
}
