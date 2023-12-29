// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ProofNonReflectionTokenFees.sol";

interface IProofNonReflectionTokenCutter is IERC20, IERC20Metadata {
    struct BaseData {
        string tokenName;
        string tokenSymbol;
        uint256 initialSupply;
        uint256 percentToLP;
        uint256 whitelistPeriod;
        address owner;
        address dev;
        address main;
        address routerAddress;
        address initialProofAdmin;
        address[] whitelists;
        address nftWhitelist;
    }

    struct WhitelistAdd_ {
        address [] whitelists;
    }

    function setBasicData(
        BaseData memory _baseData,
        ProofNonReflectionTokenFees.allFees memory fees
    ) external;

    function addMoreToWhitelist(
        WhitelistAdd_ memory _WhitelistAdd
    ) external;

    function updateWhitelistPeriod(
        uint256 _whitelistPeriod
    ) external;

    function addNFTSnapshot() external;

        function changeFees(
        uint256 initialMainFee,
        uint256 initialMainFeeOnSell,
        uint256 initialLpFee,
        uint256 initialLpFeeOnSell,
        uint256 initialDevFee,
        uint256 initialDevFeeOnSell
    ) external;
}
