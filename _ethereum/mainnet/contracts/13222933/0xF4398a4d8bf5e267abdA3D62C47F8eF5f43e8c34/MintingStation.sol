//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMintingStation.sol";
import "./ERC721Full.sol";

/// @title MintingStation
/// @author Simon Fremaux (@dievardump)
abstract contract MintingStation is IMintingStation, ERC721Full {
    /// @dev This contains the last token id that was created
    uint256 public lastTokenId;

    bool internal _mintingOpenToAll;

    /// @notice modifier allowing only safe listed addresses to mint
    ///         safeListed addresses are all user in the Minter or owner
    modifier onlyMinter(address minter) {
        require(_mintingOpenToAll || canMint(minter), 'Not minter.');
        _;
    }

    /// @notice helper to know if an address can mint or not
    /// @param operator the address to check
    function canMint(address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return isMinter(operator) || operator == owner();
    }

    /// @notice helper to know if everyone can mint or only minters
    /// @inheritdoc	IMintingStation
    function isMintingOpenToAll() public view override returns (bool) {
        return _mintingOpenToAll;
    }

    /// @notice Toggle minting open to all state
    /// @param isOpen if the new state is open or not
    /// @inheritdoc	IMintingStation
    function setMintingOpenToAll(bool isOpen) external override onlyOwner {
        _mintingOpenToAll = isOpen;
    }

    /// @dev only a minter can call this
    /// @inheritdoc	IMintingStation
    function mint(
        string memory tokenURI_,
        address royaltiesRecipient,
        uint256 royaltiesAmount
    ) public override onlyMinter(msg.sender) returns (uint256) {
        return
            mintTo(msg.sender, tokenURI_, royaltiesRecipient, royaltiesAmount);
    }

    /// @dev only a minter can call this
    /// @inheritdoc	IMintingStation
    function mintTo(
        address to,
        string memory tokenURI_,
        address royaltiesRecipient,
        uint256 royaltiesAmount
    ) public override onlyMinter(msg.sender) returns (uint256 tokenId) {
        tokenId = lastTokenId + 1;

        // update lastTokenId before _safeMint is called
        lastTokenId = tokenId;

        _mintTo(tokenId, to, tokenURI_, royaltiesRecipient, royaltiesAmount);
    }

    /// @dev only a minter can call this
    /// @inheritdoc	IMintingStation
    function mintBatch(
        string[] memory tokenURIs_,
        address[] memory feeRecipients,
        uint256[] memory feeAmounts
    ) public override onlyMinter(msg.sender) returns (uint256[] memory) {
        return mintBatchTo(msg.sender, tokenURIs_, feeRecipients, feeAmounts);
    }

    /// @dev only a minter can call this
    /// @inheritdoc	IMintingStation
    function mintBatchTo(
        address to,
        string[] memory tokenURIs_,
        address[] memory feeRecipients,
        uint256[] memory feeAmounts
    ) public override onlyMinter(msg.sender) returns (uint256[] memory) {
        // build an array of address with only "to" inside
        uint256 count = tokenURIs_.length;
        address[] memory toBatch = new address[](count);
        for (uint256 i; i < count; i++) {
            toBatch[i] = to;
        }

        return mintBatchToMore(toBatch, tokenURIs_, feeRecipients, feeAmounts);
    }

    /// @dev only a minter can call this
    /// @inheritdoc	IMintingStation
    function mintBatchToMore(
        address[] memory to,
        string[] memory tokenURIs_,
        address[] memory feeRecipients,
        uint256[] memory feeAmounts
    )
        public
        override
        onlyMinter(msg.sender)
        returns (uint256[] memory tokenIds)
    {
        require(
            to.length == tokenURIs_.length &&
                to.length == feeRecipients.length &&
                to.length == feeAmounts.length,
            'Length mismatch'
        );

        uint256 tokenId = lastTokenId;
        uint256 count = tokenURIs_.length;
        tokenIds = new uint256[](count);
        for (uint256 i; i < count; i++) {
            tokenId++;
            _mintTo(
                tokenId,
                to[i],
                tokenURIs_[i],
                feeRecipients[i],
                feeAmounts[i]
            );
            tokenIds[i] = tokenId;
        }

        // update lastTokenId
        lastTokenId = tokenId;
    }

    /// @notice Mint `tokenId` to `to` with `tokenURI_` and `royaltiesRecipient` getting secondary sales
    /// @dev Explain to a developer any extra details
    /// @param tokenId the tokenId to mint
    /// @param to the token recipient
    /// @param tokenURI_ the token URI
    /// @param royaltiesRecipient the recipient of royalties
    /// @param royaltiesAmount the royalties amount. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    function _mintTo(
        uint256 tokenId,
        address to,
        string memory tokenURI_,
        address royaltiesRecipient,
        uint256 royaltiesAmount
    ) internal {
        _safeMint(to, tokenId, '');
        _setTokenURI(tokenId, tokenURI_);
        _setTokenCreator(tokenId, to);

        if (royaltiesAmount > 0) {
            _setTokenRoyalty(tokenId, royaltiesRecipient, royaltiesAmount);
        }
    }
}
