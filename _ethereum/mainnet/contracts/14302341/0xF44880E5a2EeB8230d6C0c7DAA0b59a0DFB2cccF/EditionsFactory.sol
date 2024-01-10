// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./Clones.sol";
import "./IEditionsFactory.sol";
import "./IEditions.sol";

interface ITributaryRegistry {
    function registerTributary(address producer, address tributary) external;
}

/**
 * @title EditionsFactory
 * @notice The EditionsFactory contract is used to deploy edition clones.
 * @author MirrorXYZ
 */
contract EditionsFactory is Ownable, IEditionsFactoryEvents, IEditionsFactory {
    /// @notice Address that holds the implementation for Crowdfunds
    address public implementation;

    /// @notice Mirror tributary registry
    address public tributaryRegistry;

    constructor(
        address owner_,
        address implementation_,
        address tributaryRegistry_
    ) Ownable(owner_) {
        implementation = implementation_;
        tributaryRegistry = tributaryRegistry_;
    }

    // ======== Admin function =========
    function setImplementation(address implementation_)
        external
        override
        onlyOwner
    {
        require(implementation_ != address(0), "must set implementation");

        emit ImplementationSet(implementation, implementation_);

        implementation = implementation_;
    }

    function setTributaryRegistry(address tributaryRegistry_)
        external
        override
        onlyOwner
    {
        require(
            tributaryRegistry_ != address(0),
            "must set tributary registry"
        );

        emit TributaryRegistrySet(tributaryRegistry, tributaryRegistry_);

        tributaryRegistry = tributaryRegistry_;
    }

    // ======== Deploy function =========

    /// @notice Deploys a new edition (ERC721) clone, and register tributary.
    /// @param owner_ the clone owner
    /// @param tributary the tributary receive tokens in behalf of the clone fees
    /// @param name_ the name for the edition clone
    /// @param symbol_ the symbol for the edition clone
    /// @param description_ the description for the edition clone
    /// @param contentURI_ the contentURI for the edition clone
    /// @param animationURI_ the animationURI for the edition clone
    /// @param contractURI_ the contractURI for the edition clone
    /// @param edition_ the parameters for the edition sale
    /// @param nonce additional entropy for the clone salt parameter
    /// @param paused_ the pause state for the edition sale
    function create(
        address owner_,
        address tributary,
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory contentURI_,
        string memory animationURI_,
        string memory contractURI_,
        IEditions.Edition memory edition_,
        uint256 nonce,
        bool paused_
    ) external override returns (address clone) {
        clone = Clones.cloneDeterministic(
            implementation,
            keccak256(abi.encode(owner_, name_, symbol_, nonce))
        );

        IEditions(clone).initialize(
            owner_,
            name_,
            symbol_,
            description_,
            contentURI_,
            animationURI_,
            contractURI_,
            edition_,
            paused_
        );

        emit EditionsDeployed(owner_, clone, implementation);

        if (tributaryRegistry != address(0)) {
            ITributaryRegistry(tributaryRegistry).registerTributary(
                clone,
                tributary
            );
        }
    }

    function predictDeterministicAddress(address implementation_, bytes32 salt)
        external
        view
        override
        returns (address)
    {
        return
            Clones.predictDeterministicAddress(
                implementation_,
                salt,
                address(this)
            );
    }
}
