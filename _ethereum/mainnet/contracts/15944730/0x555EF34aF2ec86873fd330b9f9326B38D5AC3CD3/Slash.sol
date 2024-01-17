// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Monotonic.sol";
import "./ERC721.sol";
import "./ERC721Royalty.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Address.sol";

/// @custom:security-contact tobybaggio@gmail.com
contract Slash is ERC721, ERC721Royalty, Pausable, Ownable {
    using Monotonic for Monotonic.Increaser;

    uint256 public constant totalInventory = 100000;
    uint256 public defaultMintPrice;
    address payable public beneficiary;

    Monotonic.Increaser private _totalPublished;

    mapping(uint256 => uint256) private _prices;

    // Slash internal collection id
    string private _collectionId;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory collectionId,
        uint256 _defaultMintPrice,
        uint96 royaltyFraction,
        address payable _beneficiary
    ) ERC721(name, symbol) {
        _collectionId = collectionId;
        setBeneficiary(_beneficiary,royaltyFraction);
        setDefaultMintPrice(_defaultMintPrice);
    }

    function _baseURI() internal view override returns (string memory) {
        return string.concat("https://api.slash.sg/api/nft/commodity/v1/query/", _collectionId,"/");
    }

    function contractURI() public view returns (string memory) {
        return string.concat("https://api.slash.sg/api/nft/v1/album/query/", _collectionId);        
    }

    /// @notice Sets the recipient of revenues.
    function setBeneficiary(address payable _beneficiary,uint96 royaltyFraction) public onlyOwner {
        // mint beneficiary and royalty receiver are same
        beneficiary = _beneficiary;
        _setDefaultRoyalty(_beneficiary, royaltyFraction);
    }

    function setDefaultMintPrice(uint256 price) public onlyOwner {
        defaultMintPrice = price;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        // public mint must after the token being published
        require(_published(tokenId), "private mint for nonpublished token");
        _safeMint(to, tokenId);
    }

    function publicMint(address to, uint256 tokenId) public payable callerIsUser {
        /**
         * ##### CHECKS
         */
        // check the price
        // public mint must after the token being published
        require(_published(tokenId), "public mint for nonpublished token");
        // value is enough
        uint256 cost = mintPriceOf(tokenId);
        if (msg.value < cost) {
            revert(
                "mint value is not enough"
            );
        }

        /**
         * ##### EFFECTS
         */
        _safeMint(to, tokenId);

        /**
         * ##### INTERACTIONS
         */
        if (msg.value > 0) {
            Address.sendValue(beneficiary , msg.value);
            //beneficiary.transfer(msg.value);
            //emit Revenue(beneficiary, tokenId, msg.value);
        }
    } 

    /**
     * @dev Returns whether `tokenId` published.
     *
     * Tokens can be published by owner. Check the price of the token, if not exsits, means not published
     *
     * Tokens are published with (`safePublish`).
     */
    function _published(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _totalPublished.current();
    }

    function mintPriceOf(uint256 tokenId) public view virtual returns (uint256) {
        require(_published(tokenId), "query price for nonpublished token");

        uint256 price = _prices[tokenId];
        if (price == 0) price = defaultMintPrice;
        return price;
    }

    function totalPublished() public view returns (uint256) {
        return _totalPublished.current();
    }


    /**
     * @dev Safely publish next `quantity` tokens and set price to `price`.
     *
     * Requirements:
     *
     * - `quantity` must greater then 0.
     * - `price` must greater or equal then 1 finney or 0 means default price
     *
     * Emits a {Publish} event.
     */
    function safePublish(uint256 quantity, uint256 price) public whenNotPaused onlyOwner {
        //require(quantity > 0, "quantity must greater than 0");
        // set next n token price to publish
        uint256 beforeCount = _totalPublished.current();
        require(beforeCount + quantity <= totalInventory, "publish too many tokens");

        // if price == 0 means we will use default price, do not loop for save gas
        if (price > 0) {
            // only store the price when not equal to default price;
            for (uint256 j = beforeCount; j < beforeCount + quantity; j++) {
                _prices[j] = price;
            }
        }

        _totalPublished.add(quantity);
        //emit Publish(beforeCount, _totalPublished.current() - 1, price);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }
}