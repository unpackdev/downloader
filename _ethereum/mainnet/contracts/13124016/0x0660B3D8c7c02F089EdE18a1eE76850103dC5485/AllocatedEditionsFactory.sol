// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./ITributaryRegistry.sol";
import "./Governable.sol";
import "./AllocatedEditionsProxy.sol";
import "./AllocatedEditionsStorage.sol";
import "./IERC2309.sol";

/**
 * @title AllocatedEditionsFactory
 * @author MirrorXYZ
 */
contract AllocatedEditionsFactory is Governable, IERC2309 {
    //======== Structs ========

    struct Parameters {
        // NFT Metadata
        bytes nftMetaData;
        // Edition Data
        uint256 allocation;
        uint256 quantity;
        uint256 price;
        // Admint Data
        bytes adminData;
    }

    //======== Events ========

    event AllocatedEditionDeployed(
        address allocatedEditionProxy,
        string name,
        string symbol,
        address operator
    );

    //======== Mutable storage =========

    /// @notice Gets set within the block, accessed from the proxy and then deleted.
    Parameters public parameters;

    /// @notice Minimum fee percentage collected by the treasury when withdrawing funds.
    uint256 public minFeePercentage = 250;

    /// @notice Contract logic for the edition deployed. 
    address public logic;

    address public tributaryRegistry;

    address public treasuryConfig;

    /// @notice Base URI with NFT data
    string baseURI;

    /// @notice OpenSea Proxy Registry
    address public proxyRegistry;

    //======== Constructor =========
    constructor(
        address owner_,
        address logic_,
        address tributaryRegistry_,
        address treasuryConfig_,
        string memory baseURI_,
        address proxyRegistry_
    ) Governable(owner_) {
        logic = logic_;
        tributaryRegistry = tributaryRegistry_;
        treasuryConfig = treasuryConfig_;
        baseURI = baseURI_;
        proxyRegistry = proxyRegistry_;
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

    function setProxyRegistry(address newProxyRegistry)
        public
        onlyGovernance
    {
        proxyRegistry = newProxyRegistry;
    }

    //======== Proxy Deployments =========

    /// @notice Creates an edition by deploying a new proxy.
   function createEdition(
        AllocatedEditionsStorage.NFTMetadata memory metadata,
        AllocatedEditionsStorage.EditionData memory editionData,
        AllocatedEditionsStorage.AdminData memory adminData
    ) external returns (address allocatedEditionsProxy) {
        require(
            adminData.feePercentage >= minFeePercentage,
            "fee is too low"
        );

        require(editionData.allocation < editionData.quantity, "allocation must be less than quantity");

        parameters = Parameters({
            // NFT Metadata
            nftMetaData: abi.encode(
                metadata.name,
                metadata.symbol,
                baseURI,
                metadata.contentHash
            ),
            // Edition Data
            allocation: editionData.allocation,
            quantity: editionData.quantity,
            price: editionData.price,
            // Admin Data
            adminData: abi.encode(
                adminData.operator,
                adminData.tributary,
                adminData.fundingRecipient,
                adminData.feePercentage,
                treasuryConfig
            )
        });

        // deploys proxy
        allocatedEditionsProxy = address(
            new AllocatedEditionsProxy{
                salt: keccak256(abi.encode(metadata.symbol, adminData.operator))
            }(adminData.operator, proxyRegistry)
        );

        delete parameters;

        emit AllocatedEditionDeployed(
            allocatedEditionsProxy,
            metadata.name,
            metadata.symbol,
            adminData.operator
        );

        ITributaryRegistry(tributaryRegistry).registerTributary(
            allocatedEditionsProxy,
            adminData.tributary
        );
    }
}
