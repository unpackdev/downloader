// SPDX-License-Identifier: MIT
// Copyright (c) 2023 SolidifyLabs
pragma solidity >=0.8.0 <0.9.0;

import "./Address.sol";
import "./OperatorFilterer.sol";
import "./OperatorFilterRegistry.sol";
import "./Constants.sol";
import "./ERC721ACommon.sol";

address constant BLUR_SUBSCRIPTION = 0x9dC5EE2D52d014f8b81D662FA8f4CA525F27cD6b;

/**
 * @notice Extends OpenSea's DefaultOperatorFilterer, using BLUR_SUBSCRIPTION if available.
 */
abstract contract DefaultOperatorFilterer is OperatorFilterer {
    constructor() OperatorFilterer(_defaultSubscription(), true) {}

    /**
     * @notice Returns the default subscription address.
     * @dev The blur subscription is used if it is registered, otherwise the canonical OS subscription is used.
     */
    function _defaultSubscription() private view returns (address) {
        if (
            CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS.code.length > 0
            // Using OperatorFilterRegistry instead of IOperatorFilterRegistry as the function on the interface is
            // not view.
            && OperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS).isRegistered(BLUR_SUBSCRIPTION)
        ) {
            return BLUR_SUBSCRIPTION;
        }

        return CANONICAL_CORI_SUBSCRIPTION;
    }
}

/**
 * @notice ERC721ACommon extension that adds Opensea's operator filtering.
 */
abstract contract ERC721ACommonOperatorFilterOS is ERC721ACommon, DefaultOperatorFilterer {
    using Address for address;

    /**
     * @notice Calling the operator filter registry with given calldata.
     * @dev The registry contract did not foresee role-based contract access
     * control - only the contract itself, or its (EIP-173) owner is allowed to
     * change subscription settings. To work around this, we enforce
     * authorisation here and forward arbitrary calldata to the registry.
     * Use with care!
     */
    function callOperatorFilterRegistry(bytes calldata cdata)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
        returns (bytes memory)
    {
        return address(OPERATOR_FILTER_REGISTRY).functionCall(cdata);
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        virtual
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
