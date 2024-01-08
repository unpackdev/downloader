// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PausableUpgradeable.sol";
import "./ERC1155Upgradeable.sol";

import "./OwnerOperatorControlWithSignature.sol";
import "./ERC1155Configurable.sol";
import "./ERC1155WithMetadata.sol";
import "./ERC2981Royalties.sol";
import "./OpenSeaMandatory.sol";
import "./ProxyRegistry.sol";
import "./EditionsStorage.sol";

contract EditionsRegistry is
    OwnerOperatorControlWithSignature,
    PausableUpgradeable,
    ERC1155Configurable,
    ERC1155WithMetadata,
    ERC2981Royalties,
    OpenSeaMandatory,
    EditionsStorage
{
    event Mint(uint256 indexed tokenId, bytes indexed data);

    function initialize(
        string memory uri,
        address minter,
        string memory contractURI_,
        address proxyRegistryAddress_
    ) public initializer {
        __OwnableOperatorControl_init(); // already inits context and ERC165
        __Pausable_init_unchained();
        __ERC1155WithMetadata_init(uri);

        _addOperator(minter);

        if (bytes(contractURI_).length != 0) {
            setContractURI(contractURI_);
        }

        if (proxyRegistryAddress_ != address(0)) {
            proxyRegistryAddress = proxyRegistryAddress_;
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Royalties, ERC1155Upgradeable)
        returns (bool)
    {
        return
            ERC2981Royalties.supportsInterface(interfaceId) ||
            ERC1155Upgradeable.supportsInterface(interfaceId);
    }

    receive() external payable {
        revert('No value accepted');
    }

    /**
     * @dev Pauses all token creation.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function pause() public virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token creation.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev Minting function - With royalties
     *
     * Requirements:
     * - An  Operator must have signed (msg.sender, data), which allows to link the mint
     * to our off-chain data and to prove that the user has the right to mint
     */
    function mint(
        uint256 supply,
        uint256 royalties,
        address royaltiesRecipient,
        bytes memory data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused {
        bytes32 message = prepareMessage(msg.sender, data);
        requireOperatorSignature(message, v, r, s);
        require(alreadyMinted[message] == false, 'ERC1155: Already minted');

        // set
        alreadyMinted[message] = true;

        // only one read
        uint256 _currentId = currentId + 1;

        _mint(
            _currentId,
            msg.sender,
            supply,
            royaltiesRecipient,
            royalties,
            data
        );

        currentId = _currentId;
    }

    function burn(
        address owner,
        uint256 id,
        uint256 amount
    ) external {
        require(
            owner == _msgSender() || isApprovedForAll(owner, _msgSender()),
            'ERC1155: caller is not owner nor approved'
        );

        _burn(owner, id, amount);
    }

    function burnBatch(
        address owner,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        require(
            owner == _msgSender() || isApprovedForAll(owner, _msgSender()),
            'ERC1155: caller is not owner nor approved'
        );

        _burnBatch(owner, ids, amounts);
    }

    /**
     * @dev allows to transfer one id to several recipient with corresponding amounts
     */
    function safeBatchTransferIdFrom(
        address from,
        address[] memory recipients,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(
            recipients.length == amounts.length,
            'ERC1155: length mismatch'
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            safeTransferFrom(from, recipients[i], id, amounts[i], data);
        }
    }

    /// @dev Post Upgrade, called after an upgrade of the contract
    function postUpgrade() external onlyOwner {
        // reset _safeMintBatchForArtistsAndTransferFlag to be able to do the
        // Paris treasure hunt generation call
        _safeMintBatchForArtistsAndTransferFlag = 0;
    }

    /**
     * @dev allows to create Batch NFTs and to send part of those to some recipient
     * This function is a ONE TIME USE per upgrade
     *
     * Use cases are "Giveaways" and things like this.
     */
    function safeMintBatchForArtistsAndTransfer(
        address[] memory artists, // artist creator of the NFT
        uint256[] memory amounts, // amounts to create
        uint256[] memory royalties, // royalties for each one of them
        address recipient, // recipient
        bytes memory data
    ) public virtual onlyOwner {
        require(_safeMintBatchForArtistsAndTransferFlag == 0, 'Already used.');

        require(
            artists.length == amounts.length &&
                artists.length == royalties.length,
            'ERC1155: length mismatch'
        );

        // set flag to 2 so isApprovedForall is overrode
        _safeMintBatchForArtistsAndTransferFlag = 2;

        uint256 _currentId = currentId;
        for (uint256 i; i < artists.length; i++) {
            _currentId++;
            // mint token for artist with royalties[i] royalties
            _mint(
                _currentId,
                artists[i],
                amounts[i],
                artists[i],
                royalties[i],
                data
            );

            // transfer 1 to the recipient wallet
            safeTransferFrom(artists[i], recipient, _currentId, 1, data);
        }

        // set current id to highest id
        currentId = _currentId;

        // set flag to 1 so we do not use this function again without updating the contract
        _safeMintBatchForArtistsAndTransferFlag = 1;
    }

    /**
     * Function to let Owner set the baseURI
     */
    function setBaseURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    /**
     * Function to let Owner set configurationURI
     */
    function setInteractiveConfURI(
        uint256 tokenId,
        address owner_,
        string calldata interactiveConfURI_
    ) public {
        require(
            owner_ == _msgSender() || isApprovedForAll(owner_, _msgSender()),
            'ERC1155: caller is not owner nor approved'
        );
        _setInteractiveConfURI(tokenId, owner_, interactiveConfURI_);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // this is used in the function safeMintBatchForArtistsAndTransfer
        // in order to allow the team to mint a bunch of NFTs for some artists
        // and to transfer one of those NFTs to a given recipient
        // used for giveaways & treasure hunt
        if (_safeMintBatchForArtistsAndTransferFlag == 2) {
            return true;
        }

        // Whitelist OpenSea proxy contract for easy trading.
        address openSeaRegistry = proxyRegistryAddress;
        if (openSeaRegistry != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(openSeaRegistry);
            if (address(proxyRegistry.proxies(_owner)) == _operator) {
                return true;
            }
        }

        return ERC1155Upgradeable.isApprovedForAll(_owner, _operator);
    }

    function prepareMessage(address sender, bytes memory data)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(sender, data));
    }

    /**
     * Internal function used to mint
     */
    function _mint(
        uint256 id,
        address creator_,
        uint256 supply,
        address royaltiesRecipient,
        uint256 royalties,
        bytes memory data
    ) internal {
        ERC1155Upgradeable._mint(creator_, id, supply, data);

        // if specific uri
        _setMetadata(id, creator_);

        // if royalties
        if (royalties > 0) {
            _setTokenRoyalty(id, royaltiesRecipient, royalties);
        }

        // if data, then fire a mint event
        if (data.length > 0) {
            emit Mint(id, data);
        }
    }
}
