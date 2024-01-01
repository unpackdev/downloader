// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ProofFactoryFees.sol";

interface IProofFactoryTokenCutter is IERC20, IERC20Metadata {
    struct BaseData {
        string tokenName;
        string tokenSymbol;
        uint256 initialSupply;
        uint256 percentToLP;
        address owner;
        address devWallet;
        address reflectionToken;
        address routerAddress;
        address initialProofAdmin;
        uint256 antiSnipeDuration;
    }

    function setBasicData(
        BaseData memory _baseData,
        ProofFactoryFees.allFees memory fees
    ) external;

    function pair() external view returns (address);

    function swapTradingStatus() external;

    function updateProofFactory(address _newFactory) external;

    function changeIsTxLimitExempt(
        address holder,
        bool exempt
    ) external;

    event DistributorFail(string message);
}
