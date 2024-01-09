// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./IERC721MerkleDropFactory.sol";
import "./Ownable.sol";
import "./Clones.sol";
import "./ITributaryRegistry.sol";

interface IERC721MerkleDrop {
    function initialize(
        address owner_,
        bool paused_,
        bytes32 merkleRoot_,
        uint256 claimDeadline_,
        address recipient_,
        address token_,
        address tokenOwner_,
        uint256 startTokenId_,
        uint256 endTokenId_
    ) external;
}

/**
 * @title ERC721MerkleDropFactory
 * @author MirrorXYZ
 */
contract ERC721MerkleDropFactory is IERC721MerkleDropFactory, IOwnableEvents {
    //======== Immutable Variables =========

    /// @notice Address that holds the clone logic
    address public immutable logic;

    /// @notice Address that holds the tributary registry
    address public immutable tributaryRegistry;

    //======== Constructor =========

    constructor(address logic_, address tributaryRegistry_) {
        logic = logic_;
        tributaryRegistry = tributaryRegistry_;
    }

    //======== Deploy function =========

    function create(
        address owner_,
        address tributary_,
        bool paused_,
        bytes32 merkleRoot_,
        uint256 claimDeadline_,
        address recipient_,
        address token_,
        address tokenOwner_,
        uint256 startTokenId_,
        uint256 endTokenId_
    ) external override returns (address clone) {
        clone = Clones.cloneDeterministic(
            logic,
            keccak256(abi.encode(owner_, merkleRoot_, token_))
        );

        IERC721MerkleDrop(clone).initialize(
            owner_,
            paused_,
            merkleRoot_,
            claimDeadline_,
            recipient_,
            token_,
            tokenOwner_,
            startTokenId_,
            endTokenId_
        );

        emit ERC721MerkleDropCloneDeployed(clone, owner_, merkleRoot_, token_);

        ITributaryRegistry(tributaryRegistry).registerTributary(
            clone,
            tributary_
        );
    }

    function predictDeterministicAddress(address logic_, bytes32 salt)
        external
        view
        override
        returns (address)
    {
        return Clones.predictDeterministicAddress(logic_, salt, address(this));
    }
}
