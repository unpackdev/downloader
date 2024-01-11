// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract ShibuyaCannesBrut is ERC721, ERC721Enumerable, Ownable {
    struct SaleConfig {
        uint256 goldTierPrice;
        uint256 silverTierPrice;
        uint256 bronzeTierPrice;
        uint256 maxPerTransaction;
        uint256 maxSupply;
        bool saleOpen;
        bytes32 merkleRoot;
    }

    bool public isTransferrable = false;

    string private _baseTokenURI;
    address payable public treasuryAddress;

    SaleConfig public saleConfig;

    // Tier specific values where each tier is represented by its index position within the array
    uint256[6] public startingTierIds;
    uint256[6] public tierCounters;
    uint256[6] public tierPricing;

    constructor(uint256 maxSupply)
        ERC721("ShibuyaCannesBrut", "SHIBUYACANNESBRUT")
    {
        saleConfig = SaleConfig({
            goldTierPrice: 7000000000000000000,
            silverTierPrice: 6000000000000000000,
            bronzeTierPrice: 5000000000000000000,
            maxPerTransaction: 2,
            maxSupply: maxSupply,
            saleOpen: false,
            merkleRoot: ""
        });

        startingTierIds = [0, 7, 13, 17, 21, 25];
        tierCounters = [0, 7, 13, 17, 21, 25];
        tierPricing = [
            saleConfig.goldTierPrice,
            saleConfig.goldTierPrice,
            saleConfig.silverTierPrice,
            saleConfig.silverTierPrice,
            saleConfig.silverTierPrice,
            saleConfig.bronzeTierPrice
        ];
    }

    modifier originIsUser() {
        require(tx.origin == msg.sender, "Calling from a contract.");
        _;
    }

    function getStartingTierIds() external view returns (uint256[6] memory) {
        return startingTierIds;
    }

    function getTierCounters() external view returns (uint256[6] memory) {
        return tierCounters;
    }

    /**
     * @dev Checks if the provided Merkle Proof is valid for the given root hash from saleConfig.
     */
    function isValidMerkleProof(bytes32[] calldata merkleProof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                merkleProof,
                saleConfig.merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    /**
     * @dev Mint amount based on a tier value (0-5).
     *
     * Requirements:
     *
     * - Tier is a valid value between 0-5.
     * - The user is not trying to mint more than saleConfig.maxPerTransaction.
     * - If tier value 0-4: The user is not trying to mint past the following tier starting index.
     * - If tier value 5: The user is not trying to mint more than saleConfig.maxSupply.
     * - The user has enough ETH for the transaction
     */
    function _mintTier(uint256 tier, uint256 amountToMint) private {
        require(tier >= 0 && tier < tierCounters.length, "Invalid tier.");
        uint256 tierCounter = tierCounters[tier];
        require(
            amountToMint <= saleConfig.maxPerTransaction,
            "Max per transaction exceeded."
        );
        if (tier == tierCounters.length - 1) {
            require(
                tierCounter + amountToMint <= saleConfig.maxSupply,
                "Sold out."
            );
        } else {
            uint256 nextTierStartingId = startingTierIds[tier + 1];
            require(
                tierCounter + amountToMint <= nextTierStartingId,
                "Max supply reached for this tier."
            );
        }
        require(
            msg.value == tierPricing[tier] * amountToMint,
            "Invalid ETH amount."
        );

        for (uint256 i = 0; i < amountToMint; i++) {
            _safeMint(msg.sender, tierCounter + i);
        }

        tierCounters[tier] = tierCounter + amountToMint;
    }

    /**
     * @dev Public mint amount based on a tier value (0-5).
     *
     * Requirements:
     *
     * - Sale is open.
     */
    function mintTier(uint256 tier, uint256 amountToMint)
        external
        payable
        originIsUser
    {
        require(saleConfig.saleOpen, "Sale is not open.");

        _mintTier(tier, amountToMint);
    }

    /**
     * @dev Whitelist mint amount based on a tier value (0-5).
     */
    function whitelistMintTier(
        uint256 tier,
        uint256 amountToMint,
        bytes32[] calldata merkleProof
    ) external payable originIsUser {
        require(isValidMerkleProof(merkleProof), "Not authorized to mint");

        _mintTier(tier, amountToMint);
    }

    /**
     * Owner-only methods
     */

    /**
     * @dev Toggle sale to be open.
     */
    function toggleSale(bool saleOpen) public onlyOwner {
        saleConfig.saleOpen = saleOpen;
    }

    /**
     * @dev Toggle tokens to be transferrable.
     */
    function toggleIsTransferrable(bool isTransferrable_) public onlyOwner {
        isTransferrable = isTransferrable_;
    }

    /**
     * @dev Set merkleRoot for the allowlist
     */
    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        saleConfig.merkleRoot = merkleRoot;
    }

    /**
     * @dev Set the treasury address to withdraw contract funds to.
     */
    function setTreasuryAddress(address treasuryAddress_) external onlyOwner {
        treasuryAddress = payable(treasuryAddress_);
    }

    /**
     * @dev Withdraws funds to the treasuryAddress.
     */
    function withdrawMoney() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = treasuryAddress.call{value: balance}("");
        require(success, "Withdraw failed.");
    }

    /**
     * @dev Sets the base URI for the metadata.
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev tokenId is transferrable based on:
     * 1 - it does not exist yet (has not minted).
     * 2 - isTransferrable boolean if tokenId exists.
     */
    function checkIsTransferrable(uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        if (!_exists(tokenId)) {
            return true;
        }

        return isTransferrable;
    }

    /**
     * Boilerplate overrides
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        require(checkIsTransferrable(tokenId), "Transfers disabled.");

        super._beforeTokenTransfer(from, to, tokenId);
    }
}
