// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./CrowdfundProxy.sol";
import "./CrowdfundLogic.sol";
import "./ICrowdfund.sol";
import "./ITributaryRegistry.sol";
import "./Governable.sol";

/**
 * @title CrowdfundFactory
 * @author MirrorXYZ
 */
contract CrowdfundFactory is Governable {
    //======== Structs ========

    struct Parameters {
        address payable fundingRecipient;
        uint256 fundingCap;
        uint256 operatorPercent;
        uint256 feePercentage;
    }

    //======== Events ========

    event CrowdfundDeployed(
        address crowdfundProxy,
        string name,
        string symbol,
        address operator
    );

    event Upgraded(address indexed implementation);

    //======== Configuration storage =========

    /*
        Updatable via governance
    */

    address public logic;
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
        address tributaryRegistry_,
        address treasuryConfig_
    ) Governable(owner_) {
        logic = logic_;
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
        TributaryConfig calldata tributaryConfig,
        string calldata name_,
        string calldata symbol_,
        address payable operator_,
        address payable fundingRecipient_,
        uint256 fundingCap_,
        uint256 operatorPercent_
    ) external returns (address crowdfundProxy) {
        require(
            tributaryConfig.feePercentage >= minFeePercentage,
            "fee is too low"
        );

        parameters = Parameters({
            fundingRecipient: fundingRecipient_,
            fundingCap: fundingCap_,
            operatorPercent: operatorPercent_,
            feePercentage: tributaryConfig.feePercentage
        });

        crowdfundProxy = address(
            new CrowdfundProxy{salt: keccak256(abi.encode(symbol_, operator_))}(
                treasuryConfig,
                operator_,
                name_,
                symbol_
            )
        );

        delete parameters;

        emit CrowdfundDeployed(crowdfundProxy, name_, symbol_, operator_);

        ITributaryRegistry(tributaryRegistry).registerTributary(
            crowdfundProxy,
            tributaryConfig.tributary
        );
    }
}
