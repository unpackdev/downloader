// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./ITributaryRegistry.sol";
import "./InitializedGovernable.sol";
import "./DroppableEditionsProxy.sol";
import "./DroppableEditionsStorage.sol";
import "./IERC2309.sol";

/**
 * @title DroppableEditionsFactory
 * @author MirrorXYZ
 */
contract DroppableEditionsFactory is InitializedGovernable, IERC2309 {
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

    event DroppableEditionDeployed(
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

    /// @notice OpenSea Proxy Registry
    address public proxyRegistry;

    //======== Constructor =========
    constructor(
        address owner_,
        address logic_,
        address tributaryRegistry_,
        address treasuryConfig_,
        address proxyRegistry_
    ) InitializedGovernable(owner_, owner_) {
        logic = logic_;
        tributaryRegistry = tributaryRegistry_;
        treasuryConfig = treasuryConfig_;
        proxyRegistry = proxyRegistry_;
    }

    //======== Configuration =========

    /// @notice Updates minimum fee percentage
    function setMinimumFeePercentage(uint256 newMinFeePercentage)
        public
        onlyGovernance
    {
        minFeePercentage = newMinFeePercentage;
    }

    /// @notice Updates logic
    function setLogic(address newLogic) public onlyGovernance {
        logic = newLogic;
    }

    /// @notice Updates treasury config
    function setTreasuryConfig(address newTreasuryConfig)
        public
        onlyGovernance
    {
        treasuryConfig = newTreasuryConfig;
    }

    /// @notice Updates tributary registry
    function setTributaryRegistry(address newTributaryRegistry)
        public
        onlyGovernance
    {
        tributaryRegistry = newTributaryRegistry;
    }

    /// @notice Updates proxy registry
    function setProxyRegistry(address newProxyRegistry)
        public
        onlyGovernance
    {
        proxyRegistry = newProxyRegistry;
    }

    //======== Proxy Deployments =========

    /// @notice Creates an edition by deploying a new proxy.
   function createEdition(
        DroppableEditionsStorage.NFTMetadata memory metadata,
        DroppableEditionsStorage.EditionData memory editionData,
        DroppableEditionsStorage.AdminData memory adminData
    ) external returns (address allocatedEditionsProxy) {
        require(
            adminData.feePercentage >= minFeePercentage,
            "fee is too low"
        );

        require(
            editionData.allocation <= editionData.quantity,
            "allocation must be less than quantity"
        );

        parameters = Parameters({
            // NFT Metadata
            nftMetaData: abi.encode(
                metadata.name,
                metadata.symbol,
                metadata.baseURI,
                metadata.contentHash
            ),
            // Edition Data
            allocation: editionData.allocation,
            quantity: editionData.quantity,
            price: editionData.price,
            // Admin Data
            adminData: abi.encode(
                adminData.operator,
                adminData.merkleRoot,
                adminData.tributary,
                adminData.fundingRecipient,
                adminData.feePercentage,
                treasuryConfig
            )
        });

        // deploys proxy
        allocatedEditionsProxy = address(
            new DroppableEditionsProxy{
                salt: keccak256(abi.encode(metadata.symbol, adminData.operator, adminData.merkleRoot))
            }(adminData.operator, governor, proxyRegistry)
        );

        delete parameters;

        emit DroppableEditionDeployed(
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
