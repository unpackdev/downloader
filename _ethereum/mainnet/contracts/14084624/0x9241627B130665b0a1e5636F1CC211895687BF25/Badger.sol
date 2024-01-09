/*

██████╗░██████╗░██╗███╗░░░███╗███████╗██████╗░░█████╗░░█████╗░
██╔══██╗██╔══██╗██║████╗░████║██╔════╝██╔══██╗██╔══██╗██╔══██╗
██████╔╝██████╔╝██║██╔████╔██║█████╗░░██║░░██║███████║██║░░██║
██╔═══╝░██╔══██╗██║██║╚██╔╝██║██╔══╝░░██║░░██║██╔══██║██║░░██║
██║░░░░░██║░░██║██║██║░╚═╝░██║███████╗██████╔╝██║░░██║╚█████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░

*/
// SPDX-License-Identifier: GPL-3.0-or-later
// PrimeDAO Badger contract. Badger is a ERC1155 token used for governance.
// Copyright (C) 2021 PrimeDao

pragma solidity 0.8.10;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Badger is Ownable, ERC1155 {
    using Strings for string;

    /*
        State variables
    */

    mapping(uint256 => TokenTier) public tokenTiers; // tokenId => TokenTier

    /*
        Structs
    */

    struct TokenTier {
        string uriId;
        bool transferable;
    }

    /*
        Events
    */

    event TierChange(uint256 indexed tokenId, string uriId, bool transferable);

    /*
        Modifiers
    */

    modifier isSameLength(
        address[] calldata accounts,
        uint256[] calldata tokenIds,
        uint256[] memory amounts
    ) {
        require(
            accounts.length == tokenIds.length &&
                tokenIds.length == amounts.length,
            "Input array mismatch"
        );
        _;
    }

    modifier isTier(uint256 tokenId) {
        require(
            !_isEmptyString(tokenTiers[tokenId].uriId),
            "Tier does not exist"
        );
        _;
    }

    modifier isValidString(string calldata uriId) {
        require(!_isEmptyString(uriId), "String cannot be empty");
        _;
    }

    modifier isValidTransfer(uint256 tokenId, address from) {
        require(
            tokenTiers[tokenId].transferable,
            "Transfer disabled for this tier"
        );
        require(
            owner() == _msgSender() ||
                from == _msgSender() ||
                isApprovedForAll(from, _msgSender()),
            "Unauthorized"
        );
        _;
    }

    /*
        Constructor
    */

    constructor(string memory _newBaseUri) ERC1155(_newBaseUri) {}

    /*
        Minting & burning
    */

    /**
     * @dev                 mints specified amount token(s) of specific id to specified account
     * @param account       beneficiary address
     * @param id            id of token, aka. tier
     * @param amount        units of token to be minted to beneficiary
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        bytes memory data;

        _mint(account, id, amount, data);
    }

    /**
     * @dev                 burns specified amount token(s) of specific id from specified account
     * @param account       address of token holder
     * @param id            id of token, aka. tier
     * @param amount        units of token to be burnt from beneficiary
     */
    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        _burn(account, id, amount);
    }

    /**
     * @dev                 mints to multiple addresses arbitrary units of tokens of ONE token id per address
     * @notice              example: mint 3 units of tokenId 1 to alice and 4 units of tokenId 2 to bob
     * @param accounts      list of beneficiary addresses
     * @param tokenIds      list of token ids (aka tiers)
     * @param amounts       list of mint amounts
     */
    function mintToMultiple(
        address[] calldata accounts,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) public onlyOwner isSameLength(accounts, tokenIds, amounts) {
        bytes memory data;

        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], tokenIds[i], amounts[i], data);
        }
    }

    /**
     * @dev                 burns from multiple addresses arbitrary units of tokens of ONE token id per address
     *                      example: burn 3 units of tokenId 1 from alice and 4 units of tokenId 2 froms bob
     * @param accounts      list of token holder addresses
     * @param tokenIds      list of token ids (aka tiers)
     * @param amounts       list of burn amounts
     */
    function burnFromMultiple(
        address[] calldata accounts,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) public onlyOwner isSameLength(accounts, tokenIds, amounts) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _burn(accounts[i], tokenIds[i], amounts[i]);
        }
    }

    /*
        Transferring
    */

    /**
     * @dev                 transfers tokens from one address to another and uses 0x0 as default data parameter
     * @notice              this is mainly used for manual contract interactions via etherscan
     * @param from          address from which token will be transferred
     * @param to            recipient of address
     * @param id            id of token to be transferred
     * @param amount        amount of token to be transferred
     */
    function transferFromWithoutData(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) public isValidTransfer(id, from) {
        bytes memory data;

        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev                 transfers tokens from one address to another allowing custom data parameter
     * @notice              this is the standard transfer interface for ERC1155 tokens which contracts expect
     * @param from          address from which token will be transferred
     * @param to            recipient of address
     * @param id            id of token to be transferred
     * @param amount        amount of token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override isValidTransfer(id, from) {
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev                 batch transfers tokens from one address to another allowing custom data parameter
     * @notice              this is the standard transfer interface for ERC1155 tokens which contracts expect
     * @param from          address from which token will be transferred
     * @param to            recipient of address
     * @param ids           ids of token to be transferred
     * @param amounts       amounts of token to be transferred
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        for (uint8 i = 0; i < ids.length; i++) {
            require(
                tokenTiers[ids[i]].transferable,
                "Transfer disabled for this tier"
            );
        }
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /*
        Configuration
    */

    /**
     * @dev                 sets a base uri, that is the first part of the url where the metadata for a tokenId is stored
     * @param _newBaseUri   baseUrl (e.g. www.filestoring.com/)
     */
    function changeBaseUri(string calldata _newBaseUri)
        public
        onlyOwner
        isValidString(_newBaseUri)
    {
        _setURI(_newBaseUri);
    }

    /**
     * @dev                 creates a new token tier
     * @param tokenId       identifier for the new token tier
     * @param uriId         identifier that is appended to the baseUri together forming the uri where the metadata lives
     * @param transferable  determines if tokens from specific tier should be transferable or not
     */
    function createTokenTier(
        uint256 tokenId,
        string calldata uriId,
        bool transferable
    ) public onlyOwner {
        _createTokenTier(tokenId, uriId, transferable);
    }

    /**
     * @dev                 creates multiple new token tiers
     * @param tokenIds      array of identifiers for the new token tiers
     * @param uriIds        array of uriIds for the new token tiers
     * @param transferable  array of bools determining if tokens from specific tier should be transferable or not
     */
    function batchCreateTokenTiers(
        uint256[] calldata tokenIds,
        string[] calldata uriIds,
        bool[] calldata transferable
    ) public onlyOwner {
        require(
            tokenIds.length == uriIds.length &&
                uriIds.length == transferable.length,
            "Input array mismatch"
        );

        for (uint8 i = 0; i < tokenIds.length; i++) {
            _createTokenTier(tokenIds[i], uriIds[i], transferable[i]);
        }
    }

    /**
     * @dev                 updates the identifier that is appended to the baseUri for a specific tokenId (tier)
     * @param tokenId       tokenId for which the uri should be updated
     * @param uriId         identifier that is appended to the baseUri together forming the uri where the metadata lives
     */
    function updateUriIdentifier(uint256 tokenId, string calldata uriId)
        public
        onlyOwner
    {
        _updateUriIdentifier(tokenId, uriId);
    }

    /**
     * @dev                 update uri identifiers for multiple token ids (tiers)
     * @param tokenIds      tokenIds for which the uri should be updated (must be in same order as uriIds)
     * @param uriIds        identifiers that are appended to the baseUri together forming the uri where the metadata lives (must be in same order ass tokenIds)
     */
    function updateMultipleUriIdentifiers(
        uint256[] calldata tokenIds,
        string[] calldata uriIds
    ) public onlyOwner {
        require(tokenIds.length == uriIds.length, "Input array mismatch");

        for (uint8 i = 0; i < tokenIds.length; i++) {
            _updateUriIdentifier(tokenIds[i], uriIds[i]);
        }
    }

    /**
     * @dev                 updates transferability for a given token id (tier)
     * @param tokenId       tokenId for which transferability should be updated
     * @param transferable  determines whether tokens from tier should be transferable or not
     */
    function updateTransferableStatus(uint256 tokenId, bool transferable)
        public
        onlyOwner
        isTier(tokenId)
    {
        tokenTiers[tokenId].transferable = transferable;
        emit TierChange(tokenId, tokenTiers[tokenId].uriId, transferable);
    }

    /*
        Queries
    */

    /**
     * @dev                 returns the uri for a given token
     * @notice              consists of a concatenation of baseUri and uriId
     * @param tokenId       tokenId for which the uri should be retrieved
     */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory baseUri = super.uri(tokenId);
        return baseUri.append(tokenTiers[tokenId].uriId);
    }

    /*
        Internal functions
    */

    function _updateUriIdentifier(uint256 tokenId, string calldata uriId)
        private
        isTier(tokenId)
        isValidString(uriId)
    {
        tokenTiers[tokenId].uriId = uriId;
        emit TierChange(tokenId, uriId, tokenTiers[tokenId].transferable);
    }

    function _isEmptyString(string memory uriId) internal pure returns (bool) {
        return bytes(uriId).length == 0;
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override isTier(id) {
        super._mint(account, id, amount, data);
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override isTier(id) {
        super._burn(account, id, amount);
    }

    function _createTokenTier(
        uint256 tokenId,
        string calldata uriId,
        bool transferable
    ) internal isValidString(uriId) {
        require(
            _isEmptyString(tokenTiers[tokenId].uriId),
            "Tier already exists for tokenId"
        );

        tokenTiers[tokenId] = TokenTier(uriId, transferable);
        emit TierChange(tokenId, uriId, transferable);
    }
}
