// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC2981.sol";


contract Collectooors is ERC721A, Ownable, IERC2981 {
    using Strings for uint256;

    error BreachingMintLimit();

    uint256 constant MAX_TOKENS = 100;

    string private _baseTokenURI;
    address public royaltyRecipient = 0x76cE6D8e24089589AF07474ef9378C1214e6dCB7;

    constructor() ERC721A("Collectooors", "COLLECTOOORS") {}

    ///////// ONLY OWNER FUNCTIONS ////////
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice no `safeMint` allowed implying it doesn't call `onERC721Received` on the minter.
     * @param quantity number of tokens to mint, all owned by the `owner`.
     */
    function mintBatch(uint256 quantity) external onlyOwner {
        if (_currentIndex + quantity > MAX_TOKENS) {
            revert BreachingMintLimit();
        }

        _mint(msg.sender, quantity, "", false);
    }

    function setRoyaltyRecipient(address _addr) external onlyOwner {
        royaltyRecipient = _addr;
    }

    /**
     * @notice transfer tokens starting from `_startIndex` to addresses in `receivers`.
     *         provides an easier way to transfer tokens to multiple addresses.
     * @param _startId transfer tokens starting from this number, incrementing by 1 each time.
     * @param receivers addresses of receivers. `receivers[i]` receives the token `_startId+i`.
     * @dev the tokenId to transfer can overflow, but it has to be a impractical high number.
     */
    function transferToMultiple(uint256 _startId, address[] calldata receivers) external onlyOwner {
        unchecked {
            for (uint i; i<receivers.length; ++i) {
                transferFrom(msg.sender, receivers[i], _startId+i);
            }
        }
    }

    ///////// VIEW FUNCTIONS ///////////

    /**
     * @notice ERC2981 NFT royalty standard. 5% royalty on secondary sales.
     * @param
     * @param salePrice sale amount.
     * @return recipient address that should receive the royalty.
     * @return royalty amount from `salePrice` that `recipient` should receive.
     */
    function royaltyInfo(uint256 /* tokenId */, uint256 salePrice)
        external
        view
        returns (address, uint256) {

        uint256 royaltyAmount = salePrice * 500 / 10000; // 5% royalty
        return (royaltyRecipient, royaltyAmount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json")) : '';
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    ////////// INTERNAL FUNCTIONS //////////
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

}
