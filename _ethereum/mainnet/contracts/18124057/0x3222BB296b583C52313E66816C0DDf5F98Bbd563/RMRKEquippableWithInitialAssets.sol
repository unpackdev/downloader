// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "./RMRKAbstractEquippable.sol";

error NoInitialAssets();
error OnlyMinter();

contract RMRKEquippableWithInitialAssets is RMRKAbstractEquippable {
    uint64 private constant _LOWEST_POSSIBLE_PRIORITY = (2 ^ 64) - 1;
    uint64[] private _initialAssets;
    string[] private _initialAssetsMetadata;
    address private _minter;

    modifier onlyMinter() {
        _checkOnlyMinter();
        _;
    }

    /**
     * @notice Used to initialize the smart contract.
     * @param name Name of the token collection
     * @param symbol Symbol of the token collection
     * @param collectionMetadata CID of the collection metadata
     * @param maxSupply The maximum supply of tokens
     * @param royaltyRecipient Recipient of resale royalties
     * @param royaltyPercentageBps The percentage to be paid from the sale of the token expressed in basis points
     * @param minter The address of the minter contract
     * @param initialAssetsMetadata Array with metadata of the initial assets which will be added into every minted token
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory collectionMetadata,
        uint256 maxSupply,
        address royaltyRecipient,
        uint16 royaltyPercentageBps,
        string[] memory initialAssetsMetadata,
        address minter
    )
        RMRKImplementationBase(
            name,
            symbol,
            collectionMetadata,
            maxSupply,
            royaltyRecipient,
            royaltyPercentageBps
        )
    {
        _minter = minter;
        uint256 length = initialAssetsMetadata.length;
        if (length == 0) {
            revert NoInitialAssets();
        }
        for (uint256 i; i < length; ) {
            unchecked {
                ++_totalAssets;
            }
            uint64 newAssetId = uint64(_totalAssets);
            _addAssetEntry(uint64(_totalAssets), initialAssetsMetadata[i]);
            _initialAssetsMetadata.push(initialAssetsMetadata[i]);
            _initialAssets.push(uint64(newAssetId));
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to mint the desired number of tokens to the specified address.
     * @dev The `data` value of the `_safeMint` method is set to an empty value.
     * @dev Can only be called while the open sale is open.
     * @param to Address to which to mint the token
     * @param numToMint Number of tokens to mint
     * @return The ID of the first token to be minted in the current minting cycle
     */
    function mint(
        address to,
        uint256 numToMint
    ) public virtual onlyMinter returns (uint256) {
        (uint256 nextToken, uint256 totalSupplyOffset) = _prepareMint(
            numToMint
        );

        for (uint256 tokenId = nextToken; tokenId < totalSupplyOffset; ) {
            _safeMint(to, tokenId, "");
            for (uint256 j = 0; j < _initialAssets.length; ++j) {
                _addAssetToToken(tokenId, _initialAssets[j], 0);
                _acceptAsset(tokenId, 0, _initialAssets[j]);
            }
            unchecked {
                ++tokenId;
            }
        }

        return nextToken;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        _requireMinted(tokenId);
        // Token has at leats one asset by design
        uint64[] memory priorities = getActiveAssetPriorities(tokenId);
        uint64 maxPriority = _LOWEST_POSSIBLE_PRIORITY;
        uint64 maxPriorityAssetId;
        uint64 currentPrio;
        uint256 length = priorities.length;
        for (uint64 i; i < length; ) {
            currentPrio = priorities[i];
            if (currentPrio < maxPriority) {
                maxPriority = currentPrio;
                maxPriorityAssetId = _activeAssets[tokenId][i];
            }
            unchecked {
                ++i;
            }
        }
        return getAssetMetadata(tokenId, maxPriorityAssetId);
    }

    function getInitialAssetsMetadata()
        public
        view
        returns (string[] memory assetsMetadata)
    {
        return _initialAssetsMetadata;
    }

    function lockSupply() external onlyOwner {
        _maxSupply = _totalSupply;
    }

    function _afterAddAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) internal virtual override {
        // Cancel autoaccept behaviour since we will hand it on mint only
    }

    function _checkOnlyMinter() private view {
        if (msg.sender != _minter) {
            revert OnlyMinter();
        }
    }
}
