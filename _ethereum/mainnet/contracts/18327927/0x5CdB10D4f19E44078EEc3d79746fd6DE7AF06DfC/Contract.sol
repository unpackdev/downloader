// Specifies the version of Solidity, using semantic versioning.
// SPDX-License-Identifier: UNLICENSED
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;
pragma experimental ABIEncoderV2;

contract Contract {
    struct ContractInfo {
        string contractId;
        string signedAt;
    }

    string public contractId;
    string public signedAt;
    ContractInfo[] public contractInfo;

    function addContract(string memory _contractId, string memory _signedAt) public {
        contractId = _contractId;
        signedAt = _signedAt;
        contractInfo.push(ContractInfo(_contractId, _signedAt));    
      }

    function getContracts() public view returns (ContractInfo[] memory) {
        return contractInfo;
    }
}