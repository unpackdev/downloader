// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
░░░░░░░ ░░   ░░  ░░░░░  ░░░░░░   ░░░░░░  ░░     ░░     ░░     ░░  ░░░░░  ░░░░░░  
▒▒      ▒▒   ▒▒ ▒▒   ▒▒ ▒▒   ▒▒ ▒▒    ▒▒ ▒▒     ▒▒     ▒▒     ▒▒ ▒▒   ▒▒ ▒▒   ▒▒ 
▒▒▒▒▒▒▒ ▒▒▒▒▒▒▒ ▒▒▒▒▒▒▒ ▒▒   ▒▒ ▒▒    ▒▒ ▒▒  ▒  ▒▒     ▒▒  ▒  ▒▒ ▒▒▒▒▒▒▒ ▒▒▒▒▒▒  
     ▓▓ ▓▓   ▓▓ ▓▓   ▓▓ ▓▓   ▓▓ ▓▓    ▓▓ ▓▓ ▓▓▓ ▓▓     ▓▓ ▓▓▓ ▓▓ ▓▓   ▓▓ ▓▓   ▓▓ 
███████ ██   ██ ██   ██ ██████   ██████   ███ ███       ███ ███  ██   ██ ██   ██ 
*/

/// @title Shadow War NFT Project
/// @author Maerlin KirienzoETH @patriotsdivision
/// @notice This contract mints Agents (NFTs) for the Shadow War project.
import "./ERC721AQueryable.sol";
import "./CreatorTokenBase.sol";
import "./OwnableBasic.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";

contract SWAgents is OwnableBasic, ERC721AQueryable, CreatorTokenBase, ERC2981 {
    /// @dev Represents the price of each tier.
    struct PriceByTier {
        uint64 tier1;
        uint64 tier2;
        uint64 tier3;
    }

    /// @dev Represent each tier of a supply type.
    struct SupplyType {
        uint24 tier1;
        uint24 tier2;
        uint24 tier3;
    }

    /// @dev Represents the unpacked value of _packedTieredSupplyTypes, all tiers for all supplies.
    struct UnpackedSupplyData {
        /// @dev Global max supply of each tier in the collection.
        uint24 tier1MaxSupply;
        uint24 tier2MaxSupply;
        uint24 tier3MaxSupply;
        /// @dev Maximum supply that can be reached during the public sale.
        uint24 tier1MaxPublicSupply;
        uint24 tier2MaxPublicSupply;
        uint24 tier3MaxPublicSupply;
        /// @dev Current supply of the collection.
        uint24 tier1CurrentSupply;
        uint24 tier2CurrentSupply;
        uint24 tier3CurrentSupply;
    }

    /// @notice Base URI for the Agents' metadata.
    string private _uri;
    /// @notice Suffix for the Agents' metadata URI, typically a file extension.
    string private _uriSuffix = ".json";
    /// @notice URI for the hidden metadata before the reveal.
    string private _hiddenMetadataUri;

    /// @notice Cost to mint an NFT for each tier.
    PriceByTier public tiersCost;

    /// @notice Packed supply data.
    uint216 private _packedTieredSupplyTypes;

    /// @notice Flag indicating if minting is paused.
    bool public paused = true;
    /// @notice Flag indicating if presale is active.
    bool public presale = false;
    /// @notice Flag indicating if Agents' metadata has been revealed.
    bool public revealed = false;

    /// @notice The root of the Merkle tree for the whitelist phase.
    bytes32 public whitelistMerkleRoot;
    /// @notice The root of the Merkle tree for the public phase.
    bytes32 public publicMerkleRoot;

    /// @notice Maximum number of Agents an address can mint in the public phase.
    uint256 public maxAgentsMintedPerAddress;
    /// @notice Maximum number of Agents an address can mint in the WL phase.
    uint256 public maxAgentsMintedPerAddressForWL;
    /// @notice Index to use to get data from _agentsMintedPerAddress
    uint8 private _mintTrackerActiveIndex;
    /// @notice Keeps track of how many Agents each address has minted during the public phase.
    mapping(uint8 => mapping(address => uint256))
        private _agentsMintedPerAddress;
    /// @notice Keeps track of how many Agents each address has minted during the WL phase.
    mapping(address => uint256) public agentsMintedPerAddressForWL;

    /// @notice Mapping to track approved contract operators.
    mapping(address => bool) public approvedOperators;

    /// @dev Emitted when a batch of metadata needs to be updated.
    /// This event is useful for marketplaces that can listen and automatically update
    /// the metadata for tokens within the specified range.
    /// @param fromTokenId The starting token ID of the metadata update batch.
    /// @param toTokenId The ending token ID of the metadata update batch.
    event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);

    /// @notice Constructs the SWAgents contract.
    /// @param _name Name of the ERC721 token.
    /// @param _symbol Symbol of the ERC721 token.
    /// @param _tiersCost Cost to mint an Agent per tier.
    /// @param _tiersMaxSupply Maximum supply of Agents that can be minted per tier.
    /// @param _maxTiersSupplyForPublicPhase Maximum supply of Agents that can be minted per tier in the public phase.
    /// @param _maxAgentsMintedPerAddress Maximum number of Agents an address can mint in the public phase.
    /// @param _maxAgentsMintedPerAddressForWL Maximum number of Agents an address can mint in the WL phase.
    constructor(
        string memory _name,
        string memory _symbol,
        PriceByTier memory _tiersCost,
        SupplyType memory _tiersMaxSupply,
        SupplyType memory _maxTiersSupplyForPublicPhase,
        uint256 _maxAgentsMintedPerAddress,
        uint256 _maxAgentsMintedPerAddressForWL
    ) CreatorTokenBase() ERC721A(_name, _symbol) {
        tiersCost = _tiersCost;
        maxAgentsMintedPerAddress = _maxAgentsMintedPerAddress;
        _packedTieredSupplyTypes = _packAllSupplyTypes(
            _packSupplyTypeData(
                _tiersMaxSupply.tier1,
                _tiersMaxSupply.tier2,
                _tiersMaxSupply.tier3
            ),
            _packSupplyTypeData(
                _maxTiersSupplyForPublicPhase.tier1,
                _maxTiersSupplyForPublicPhase.tier2,
                _maxTiersSupplyForPublicPhase.tier3
            ),
            _packSupplyTypeData(0, 0, 0)
        );
        maxAgentsMintedPerAddressForWL = _maxAgentsMintedPerAddressForWL;
        _setDefaultRoyalty(msg.sender, 500);
    }

    /// @dev Pack the data of every tier in a uint72 value.
    function _packSupplyTypeData(
        uint24 _tier1,
        uint24 _tier2,
        uint24 _tier3
    ) private pure returns (uint72) {
        return (uint72(_tier1) << 48) | (uint72(_tier2) << 24) | uint72(_tier3);
    }

    /// @dev Pack the data of every supply type in a uint216 value.
    function _packAllSupplyTypes(
        uint72 _maxSupplyPerTier,
        uint72 _maxPublicSupplyPerTier,
        uint72 _currentSupplyPerTier
    ) private pure returns (uint216) {
        return
            (uint216(_maxSupplyPerTier) << 144) |
            (uint216(_maxPublicSupplyPerTier) << 72) |
            uint216(_currentSupplyPerTier);
    }

    /// @notice Returns the data for all tiers of all supply types.
    /// @dev Unpack _packedTieredSupplyTypes which consists of 9 uint24 values packed together.
    function _getAllSupplyData()
        private
        view
        returns (UnpackedSupplyData memory)
    {
        uint216 _packedData = _packedTieredSupplyTypes;
        return
            UnpackedSupplyData(
                uint24(_packedData >> 192),
                uint24(_packedData >> 168),
                uint24(_packedData >> 144),
                uint24(_packedData >> 120),
                uint24(_packedData >> 96),
                uint24(_packedData >> 72),
                uint24(_packedData >> 48),
                uint24(_packedData >> 24),
                uint24(_packedData)
            );
    }

    /// @notice Mints the specified amount of Agents.
    /// @param _amountForTier1 The number of Agents to be minted in tier 1.
    /// @param _amountForTier2 The number of Agents to be minted in tier 2.
    /// @param _amountForTier3 The number of Agents to be minted in tier 3.
    /// @param _to The address that will receive the NFTs.
    /// @param _merkleProof The Merkle proof verifying address is allowed to mint in this phase.
    function mint(
        uint16 _amountForTier1,
        uint16 _amountForTier2,
        uint16 _amountForTier3,
        address _to,
        bytes32[] calldata _merkleProof
    ) public payable {
        require(!paused, "The contract is paused!");
        require(
            msg.value ==
                _calculateCost(
                    _amountForTier1,
                    _amountForTier2,
                    _amountForTier3
                ),
            "Incorrect funds!"
        );
        uint256 _amountToMint = _amountForTier1 +
            _amountForTier2 +
            _amountForTier3;
        uint8 __mintTrackerActiveIndex = _mintTrackerActiveIndex;
        require(
            _agentsMintedPerAddress[__mintTrackerActiveIndex][msg.sender] +
                _amountToMint <=
                maxAgentsMintedPerAddress,
            "Max mints per address exceeded!"
        );

        bytes32 leaf = keccak256(abi.encodePacked((msg.sender)));
        require(
            MerkleProof.verify(_merkleProof, publicMerkleRoot, leaf),
            "Invalid proof"
        );

        _updateSupplyByTier(
            _amountForTier1,
            _amountForTier2,
            _amountForTier3,
            true
        );
        _agentsMintedPerAddress[__mintTrackerActiveIndex][
            msg.sender
        ] += _amountToMint;
        _safeMint(_to, _amountToMint);
    }

    /// @notice Mints Agents for whitelisted addresses.
    /// @dev This function can only be called once per address.
    /// @param _amountForTier1 The number of Agents to be minted in tier 1.
    /// @param _amountForTier2 The number of Agents to be minted in tier 2.
    /// @param _amountForTier3 The number of Agents to be minted in tier 3.
    /// @param _to The address that will receive the NFTs.
    /// @param _merkleProof The Merkle proof verifying address is whitelisted.
    function whitelistMint(
        uint16 _amountForTier1,
        uint16 _amountForTier2,
        uint16 _amountForTier3,
        address _to,
        bytes32[] calldata _merkleProof
    ) public payable {
        require(presale, "Presale is not active.");
        require(
            msg.value ==
                _calculateCost(
                    _amountForTier1,
                    _amountForTier2,
                    _amountForTier3
                ),
            "Incorrect funds!"
        );
        uint256 _amountToMint = _amountForTier1 +
            _amountForTier2 +
            _amountForTier3;
        require(
            agentsMintedPerAddressForWL[msg.sender] + _amountToMint <=
                maxAgentsMintedPerAddressForWL,
            "Max mints per address exceeded!"
        );

        bytes32 leaf = keccak256(abi.encodePacked((msg.sender)));
        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Invalid proof"
        );

        _updateSupplyByTier(
            _amountForTier1,
            _amountForTier2,
            _amountForTier3,
            false
        );
        agentsMintedPerAddressForWL[msg.sender] += _amountToMint;
        _safeMint(_to, _amountToMint);
    }

    /// @notice Mint tokens for a specific address without constraints.
    /// @param _amountForTier1 The number of Agents to be minted in tier 1.
    /// @param _amountForTier2 The number of Agents to be minted in tier 2.
    /// @param _amountForTier3 The number of Agents to be minted in tier 3.
    /// @param _to The address to mint tokens to.
    function mintForAddress(
        uint16 _amountForTier1,
        uint16 _amountForTier2,
        uint16 _amountForTier3,
        address _to
    ) public onlyOwner {
        _updateSupplyByTier(
            _amountForTier1,
            _amountForTier2,
            _amountForTier3,
            true
        );
        _safeMint(_to, _amountForTier1 + _amountForTier2 + _amountForTier3);
    }

    /// @dev Return the cost of the mint for the provided amount of tiers.
    function _calculateCost(
        uint16 _amountForTier1,
        uint16 _amountForTier2,
        uint16 _amountForTier3
    ) private view returns (uint256) {
        PriceByTier memory _tiersCost = tiersCost;
        return
            (_tiersCost.tier1 * _amountForTier1) +
            (_tiersCost.tier2 * _amountForTier2) +
            (_tiersCost.tier3 * _amountForTier3);
    }

    /// @dev Check and update the supply for each tier.
    /// @param _isPublicPhase If true, should check the max supply for the public phase as well.
    function _updateSupplyByTier(
        uint16 _amountForTier1,
        uint16 _amountForTier2,
        uint16 _amountForTier3,
        bool _isPublicPhase
    ) private {
        UnpackedSupplyData memory _unpackedSupplyData = _getAllSupplyData();

        // Should be safe from overflow attack because storage supply is uint24 and parameters are uint16
        unchecked {
            _unpackedSupplyData.tier1CurrentSupply += _amountForTier1;
            _unpackedSupplyData.tier2CurrentSupply += _amountForTier2;
            _unpackedSupplyData.tier3CurrentSupply += _amountForTier3;

            if (_isPublicPhase) {
                require(
                    _unpackedSupplyData.tier1CurrentSupply <=
                        _unpackedSupplyData.tier1MaxPublicSupply &&
                        _unpackedSupplyData.tier2CurrentSupply <=
                        _unpackedSupplyData.tier2MaxPublicSupply &&
                        _unpackedSupplyData.tier3CurrentSupply <=
                        _unpackedSupplyData.tier3MaxPublicSupply,
                    "Public max supply for tier exceeded"
                );
            }

            require(
                _unpackedSupplyData.tier1CurrentSupply <=
                    _unpackedSupplyData.tier1MaxSupply &&
                    _unpackedSupplyData.tier2CurrentSupply <=
                    _unpackedSupplyData.tier2MaxSupply &&
                    _unpackedSupplyData.tier3CurrentSupply <=
                    _unpackedSupplyData.tier3MaxSupply,
                "Max supply for tier exceeded"
            );

            _packedTieredSupplyTypes = _packAllSupplyTypes(
                _packSupplyTypeData(
                    _unpackedSupplyData.tier1MaxSupply,
                    _unpackedSupplyData.tier2MaxSupply,
                    _unpackedSupplyData.tier3MaxSupply
                ),
                _packSupplyTypeData(
                    _unpackedSupplyData.tier1MaxPublicSupply,
                    _unpackedSupplyData.tier2MaxPublicSupply,
                    _unpackedSupplyData.tier3MaxPublicSupply
                ),
                _packSupplyTypeData(
                    _unpackedSupplyData.tier1CurrentSupply,
                    _unpackedSupplyData.tier2CurrentSupply,
                    _unpackedSupplyData.tier3CurrentSupply
                )
            );
        }
    }

    /// @notice Returns the max supply for each tier.
    function maxTiersSupply()
        external
        view
        returns (SupplyType memory)
    {
        UnpackedSupplyData memory _packedSupplyByTiers = _getAllSupplyData();
        return
            SupplyType(
                _packedSupplyByTiers.tier1MaxSupply,
                _packedSupplyByTiers.tier2MaxSupply,
                _packedSupplyByTiers.tier3MaxSupply
            );
    }

    /// @notice Returns the max supply for the public mint phase.
    function maxTiersSupplyForPublicPhase()
        external
        view
        returns (SupplyType memory)
    {
        UnpackedSupplyData memory _packedSupplyByTiers = _getAllSupplyData();
        return
            SupplyType(
                _packedSupplyByTiers.tier1MaxPublicSupply,
                _packedSupplyByTiers.tier2MaxPublicSupply,
                _packedSupplyByTiers.tier3MaxPublicSupply
            );
    }

    /// @notice Returns the current supply in each tier.
    function tiersCurrentSupply() external view returns (SupplyType memory) {
        UnpackedSupplyData memory _packedSupplyByTiers = _getAllSupplyData();
        return
            SupplyType(
                _packedSupplyByTiers.tier1CurrentSupply,
                _packedSupplyByTiers.tier2CurrentSupply,
                _packedSupplyByTiers.tier3CurrentSupply
            );
    }

    /// @notice Returns the Token URI with Metadata for specified Token Id.
    /// @param _tokenId The Token Id to query.
    /// @return The URI string of the specified Token Id.
    function tokenURI(
        uint256 _tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return _hiddenMetadataUri;
        }

        string memory _currentBaseURI = _baseURI();
        return
            bytes(_currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        _currentBaseURI,
                        _toString(_tokenId),
                        _uriSuffix
                    )
                )
                : "";
    }

    /// @notice Returns the Base URI without the suffix for specified Token Id.
    /// @return The URI string of the specified Token Id.
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    /// @notice Update the revealed state of the contract.
    /// @dev This function can only be called by the contract owner.
    /// @param _state The new desired revealed state. If `true`, it means the metadata
    /// for the tokens have been revealed and should be visible.
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;

        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    /// @notice Check if an address is approved to operate on behalf of the owner.
    /// @param _owner The owner's address.
    /// @param operator The operator's address to check.
    /// @return Whether the operator is approved.
    function isApprovedForAll(
        address _owner,
        address operator
    ) public view override(ERC721A, IERC721A) returns (bool) {
        // If operator is in pre-approved list, return true
        if (approvedOperators[operator]) return true;

        return super.isApprovedForAll(_owner, operator);
    }

    /// @notice Set the maximum number of agents that can be minted per tier during the public phase.
    /// @param _tier1Supply The new max supply for tier 1.
    /// @param _tier2Supply The new max supply for tier 2.
    /// @param _tier3Supply The new max supply for tier 3.
    function setMaxTiersSupplyForPublicPhase(
        uint24 _tier1Supply,
        uint24 _tier2Supply,
        uint24 _tier3Supply
    ) public onlyOwner {
        UnpackedSupplyData memory _tiersSupply = _getAllSupplyData();

        require(
            _tier1Supply <= _tiersSupply.tier1MaxSupply &&
                _tier2Supply <= _tiersSupply.tier2MaxSupply &&
                _tier3Supply <= _tiersSupply.tier3MaxSupply,
            "Public max supply cannot be greater than the global max supply"
        );

        _packedTieredSupplyTypes = _packAllSupplyTypes(
            _packSupplyTypeData(
                _tiersSupply.tier1MaxSupply,
                _tiersSupply.tier2MaxSupply,
                _tiersSupply.tier3MaxSupply
            ),
            _packSupplyTypeData(_tier1Supply, _tier2Supply, _tier3Supply),
            _packSupplyTypeData(
                _tiersSupply.tier1CurrentSupply,
                _tiersSupply.tier2CurrentSupply,
                _tiersSupply.tier3CurrentSupply
            )
        );
    }

    /// @notice Set the maximum number of agents that can be minted per address during the public phase.
    /// @param _maxAgentsMintedPerAddress The new maximum number of agents.
    function setMaxAgentsMintedPerAddress(
        uint256 _maxAgentsMintedPerAddress
    ) public onlyOwner {
        maxAgentsMintedPerAddress = _maxAgentsMintedPerAddress;
    }

    /// @notice Returns the amount of NFTs minted by an address during the public phase.
    /// @param _address The address to check.
    function agentsMintedPerAddress(
        address _address
    ) public view returns (uint256) {
        return _agentsMintedPerAddress[_mintTrackerActiveIndex][_address];
    }

    /// @notice Reset the mapping of agentsMintedPerAddress
    function resetAgentsMintedPerAddress() external onlyOwner {
        unchecked {
            ++_mintTrackerActiveIndex;
        }
    }

    /// @notice Set the maximum number of agents that can be minted per address during the WL phase.
    /// @param _maxAgentsMintedPerAddressForWL The new maximum number of agents.
    function setMaxAgentsMintedPerAddressForWL(
        uint256 _maxAgentsMintedPerAddressForWL
    ) public onlyOwner {
        maxAgentsMintedPerAddressForWL = _maxAgentsMintedPerAddressForWL;
    }

    /// @notice Set the hidden metadata URI.
    /// @param _newHiddenMetadataUri The new hidden metadata URI.
    function setHiddenMetadataUri(
        string calldata _newHiddenMetadataUri
    ) public onlyOwner {
        _hiddenMetadataUri = _newHiddenMetadataUri;
    }

    /// @notice Set the base URI for token metadata.
    /// @param _newUri The new base URI.
    function setUri(string calldata _newUri) public onlyOwner {
        _uri = _newUri;
    }

    /// @notice Set the URI suffix for token metadata.
    /// @param _newUriSuffix The new URI suffix.
    function setUriSuffix(string calldata _newUriSuffix) public onlyOwner {
        _uriSuffix = _newUriSuffix;
    }

    /// @notice Pause or unpause the contract.
    /// @param _state The new pause state.
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    /// @notice Set the presale state of the contract.
    /// @param _bool The new presale state.
    function setPresale(bool _bool) public onlyOwner {
        presale = _bool;
    }

    /// @notice Set the Merkle root for the whitelist phase.
    /// @param _newMerkleRoot The new Merkle root.
    function setWhitelistMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        whitelistMerkleRoot = _newMerkleRoot;
    }

    /// @notice Set the Merkle root for the public phase.
    /// @param _newMerkleRoot The new Merkle root.
    function setPublicMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        publicMerkleRoot = _newMerkleRoot;
    }

    /// @notice Set a new price for each tier.
    /// @param _tier1Price New price for tier1.
    /// @param _tier2Price New price for tier2.
    /// @param _tier3Price New price for tier3.
    function setPrices(
        uint64 _tier1Price,
        uint64 _tier2Price,
        uint64 _tier3Price
    ) public onlyOwner {
        tiersCost = PriceByTier(_tier1Price, _tier2Price, _tier3Price);
    }

    /// @notice Withdraws the ETH from the contract to the owner.
    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }

    /// @notice Add an address to the list of approved operators.
    /// @param _address The address to add.
    function addApprovedOperator(address _address) external onlyOwner {
        approvedOperators[_address] = true;
    }

    /// @notice Remove an address from the list of approved operators.
    /// @param _address The address to remove.
    function removeApprovedOperator(address _address) external onlyOwner {
        approvedOperators[_address] = false;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return
            interfaceId == type(ICreatorToken).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            ERC721A.supportsInterface(interfaceId);
    }

    /// @dev Set the royalty receiver and fee
    function setDefaultRoyalty(
        address receiver,
        uint96 fee
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, fee);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////// ERC721C specific functions ////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @dev Ties the erc721a _beforeTokenTransfers hook to more granular transfer validation logic
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        unchecked {
            for (uint256 i = 0; i < quantity; ++i) {
                _validateBeforeTransfer(from, to, startTokenId + i);
            }
        }
    }

    /// @dev Ties the erc721a _afterTokenTransfer hook to more granular transfer validation logic
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        unchecked {
            for (uint256 i = 0; i < quantity; ++i) {
                _validateAfterTransfer(from, to, startTokenId + i);
            }
        }
    }
}
