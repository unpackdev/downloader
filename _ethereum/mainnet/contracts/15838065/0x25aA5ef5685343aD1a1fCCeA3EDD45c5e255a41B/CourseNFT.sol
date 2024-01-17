// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

/**
 * ERC721 implementation with built-in ERC2981 royalty functionality.
 * The desired result acts as a custom ERC721 with the capability of decoupling each tokenId
 * and personalising them so each has its own feeReceiver and fee percentage.
 *
 * The mint function allows the contract owner to mint a specific tokenId and set the feeNumerator.
 *
 * Custom functions allow the owner to change and modify each token's fee receivers and percentages.
 * The contract is designed to be "modified" only by the owner.
 */

contract CourseNFT is Ownable, ERC721Enumerable, ERC2981 {
    using Strings for uint256;

    // Prefix for tokens metadata URI
    string public baseURI;

    // Suffix for tokens metadata URIs
    string public baseExtension = "";

    // general receiver, the one that gets the fees by default.
    address public generalReceiver;

    // address that can use the mint function
    address public minter;

    // maximum value for feeNumerator
    uint96 public maxFeeValue = 1500;

    /**
     * Instantiates the contract by assigning a name, symbol, baseURI, receiver and feeNumerator.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address receiver,
        uint96 feeNumerator // 1% = 100
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * Modifier that checks if the msgSender is the owner or the minter account
     */
    modifier checkMinter() {
        require(
            _msgSender() == owner() || _msgSender() == minter,
            "CourseNFT: caller must be the owner or the minter"
        );
        _;
    }

    /**
     * Modifier that checks if the fee is lower or equal to the maximum accepted fee.
     */
    modifier checkFee(uint96 feeNumerator) {
        require(
            feeNumerator <= maxFeeValue,
            "CourseNFT: feeNumerator need to be <= maxFeeValue"
        );
        _;
    }

    /**
     * Mint function dedicated to mint NFTs
     * mints the exact NFT that is specified as parameter (_courseId)
     *
     * Access: only the contract owner's account and minter account
     *
     * @param _courseId tokenId of the NFT we want to mint
     * @param feeNumerator the fee that is applied to second sales (0 = default fee). Is calculated in basis points (10000 = 100%)
     * @param to the address that will receive the minted NFT
     */
    function mint(
        uint256 _courseId,
        uint96 feeNumerator,
        address to
    ) public checkMinter {
        require(_exists(_courseId) == false, "CourseNFT: token already minted");

        _safeMint(to, _courseId);

        if (feeNumerator > 0) {
            setTokenRoyaltyOnMint(_courseId, generalReceiver, feeNumerator);
        }
    }

    /**
     * Changes the base URI for token metadata
     *
     * Access: only the contract owner's account
     *
     * @param _newBaseURI new value
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * Changes the base extension for token metadata
     *
     * Access: only the contract owner's account
     *
     * @param _newBaseExtension new value
     */
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    /**
     * Changes the default royalty
     *
     * Access: only the contract owner's account
     *
     * @param receiver new generalReceiver value
     * @param feeNumerator new default fee. Is calculated in basis points (10000 = 100%)
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
        checkFee(feeNumerator)
    {
        generalReceiver = receiver;
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * Changes the royalty fee and receiver of a specific tokenId
     *
     * Access: only the contract owner's account
     *
     * @param tokenId tokenId of the NFT we want to change the fees for
     * @param receiver new generalReceiver value
     * @param feeNumerator new default fee. Is calculated in basis points (10000 = 100%)
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner checkFee(feeNumerator) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * Changes the royalty fee and receiver of a specific tokenId
     *
     * @param tokenId tokenId of the NFT we want to change the fees for
     * @param receiver new generalReceiver value
     * @param feeNumerator new default fee. Is calculated in basis points (10000 = 100%)
     */
    function setTokenRoyaltyOnMint(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal checkFee(feeNumerator) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * Changes the minter, the one that can use the mint function
     *
     * Access: only the contract owner's account
     *
     * @param newMinter new minter value
     */
    function setMinter(address newMinter) public onlyOwner {
        minter = newMinter;
    }

    /**
     * Changes the maxFeeValue, the value that tells the upper bound of the feeNumerator value
     *
     * Access: only the contract owner's account
     *
     * @param newMaxFeeValue new max fee value
     */
    function setMaxFeeValue(uint96 newMaxFeeValue) public onlyOwner {
        require(
            newMaxFeeValue <= 10000,
            "CourseNFT: newMaxFeeValue need to be <= 10000 (100%) "
        );
        maxFeeValue = newMaxFeeValue;
    }

    /**
     * Returns true/false based on the selector (bytes4 interfaceId) sent.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Fetches base metadata URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Returns all the tokenIds of a certain wallet
     */
    function walletOfOwner(address add) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(add);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(add, i);
        }
        return tokenIds;
    }

    /**
     * Returns the complete metadata URI for a specific NFT base of its Id
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "CourseNFT: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }
}
