// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ProofReflectionFactoryFees.sol";

interface IProofReflectionTokenCutter is IERC20, IERC20Metadata {
    struct BaseData {
        string tokenName;
        string tokenSymbol;
        uint256 initialSupply;
        uint256 percentToLP;
        address owner;
        address devWallet;
        address routerAddress;
        address initialProofAdmin;
        uint256 antiSnipeDuration;
    }

    function setBasicData(
        BaseData memory _baseData,
        ProofReflectionFactoryFees.allFees memory fees
    ) external;

    function changeIsTxLimitExempt(
        address holder,
        bool exempt
    ) external;
}
