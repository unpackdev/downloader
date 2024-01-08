// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./CrowdfundWithPodiumEditionsProxy.sol";
import "./CrowdfundWithPodiumEditionsLogic.sol";
import "./ICrowdfundWithPodiumEditions.sol";
import "./ITributaryRegistry.sol";
import "./Governable.sol";

/**
 * @title CrowdfundWithPodiumEditionsFactory
 * @author MirrorXYZ
 */
contract CrowdfundWithPodiumEditionsFactory is Governable {
    //======== Structs ========

    struct Parameters {
        address payable fundingRecipient;
        uint256 fundingCap;
        uint256 operatorPercent;
        string name;
        string symbol;
        uint256 feePercentage;
        uint256 podiumDuration;
    }

    //======== Events ========

    event CrowdfundDeployed(
        address crowdfundProxy,
        string name,
        string symbol,
        address operator
    );

    //======== Configuration storage =========

    /*
        Updatable via governance
    */

    address public logic;
    address payable public editions;
    address public tributaryRegistry;
    address public treasuryConfig;
    uint256 public minFeePercentage = 250;

    //======== Runtime mutable storage =========

    // Gets set within the block, and then deleted.
    Parameters public parameters;

    //======== Constructor =========

    constructor(
        address owner_,
        address logic_,
        address payable editions_,
        address tributaryRegistry_,
        address treasuryConfig_
    ) Governable(owner_) {
        logic = logic_;
        editions = editions_;
        tributaryRegistry = tributaryRegistry_;
        treasuryConfig = treasuryConfig_;
    }

    //======== Configuration =========

    function setMinimumFeePercentage(uint256 newMinFeePercentage)
        public
        onlyGovernance
    {
        minFeePercentage = newMinFeePercentage;
    }

    function setEditions(address payable newEditions) public onlyGovernance {
        editions = newEditions;
    }

    function setLogic(address newLogic) public onlyGovernance {
        logic = newLogic;
    }

    function setTreasuryConfig(address newTreasuryConfig)
        public
        onlyGovernance
    {
        treasuryConfig = newTreasuryConfig;
    }

    function setTributaryRegistry(address newTributaryRegistry)
        public
        onlyGovernance
    {
        tributaryRegistry = newTributaryRegistry;
    }

    //======== Deploy function =========
    struct TributaryConfig {
        address tributary;
        uint256 feePercentage;
    }

    function createCrowdfund(
        ICrowdfundWithPodiumEditions.EditionTier[] calldata tiers,
        TributaryConfig calldata tributaryConfig,
        string calldata name_,
        string calldata symbol_,
        address payable operator_,
        address payable fundingRecipient_,
        uint256 fundingCap_,
        uint256 operatorPercent_,
        uint256 podiumDuration_
    ) external returns (address crowdfundProxy) {
        require(
            tributaryConfig.feePercentage >= minFeePercentage,
            "fee is too low"
        );

        parameters = Parameters({
            name: name_,
            symbol: symbol_,
            fundingRecipient: fundingRecipient_,
            fundingCap: fundingCap_,
            operatorPercent: operatorPercent_,
            feePercentage: tributaryConfig.feePercentage,
            podiumDuration: podiumDuration_
        });

        crowdfundProxy = address(
            new CrowdfundWithPodiumEditionsProxy{
                salt: keccak256(abi.encode(symbol_, operator_))
            }(treasuryConfig, operator_)
        );

        delete parameters;

        emit CrowdfundDeployed(crowdfundProxy, name_, symbol_, operator_);

        ITributaryRegistry(tributaryRegistry).registerTributary(
            crowdfundProxy,
            tributaryConfig.tributary
        );

        ICrowdfundWithPodiumEditions(editions).createEditions(
            tiers,
            payable(crowdfundProxy),
            crowdfundProxy
        );
    }
}
