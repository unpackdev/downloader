// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Tradable.sol";
import "./console.sol";
import "./Counters.sol";

contract Oracle is IERC165, ERC721Tradable {
    using Strings for string;
    using Counters for Counters.Counter;

    bool public saleIsActive = false;
    uint256 public constant MAX_PER_ADDRESS = 10;
    uint256 public maxSupply = 10000;
    uint256 public price = 100000000000000000; //0.1 ETH
    string private baseURI;

    /**
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs.
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */
    Counters.Counter private _nextTokenId;

    event OracleRequested(bytes32 indexed requestId);

    constructor(
        uint256 inputSupply,
        bool saleStatus,
        address _proxyRegistryAddress,
        string memory _baseURI
    ) ERC721Tradable("Oracle", "ORACLE", _proxyRegistryAddress) {
        maxSupply = inputSupply;
        saleIsActive = saleStatus;
        baseURI = _baseURI;
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function getbaseURI() public view virtual returns (string memory) {
        return baseURI;
    }

    function createNewOracle(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active");
        require(numberOfTokens <= MAX_PER_ADDRESS, "Can only mint 10 Oracles");
        require(
            (totalSupply() + numberOfTokens) <= maxSupply,
            "Purchase would exceed max supply"
        );
        require(price <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalSupply() < maxSupply) {
                uint256 currentTokenId = _nextTokenId.current();
                _nextTokenId.increment();
                _safeMint(_msgSender(), currentTokenId);
            }
        }
    }

    function reserve(uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(_msgSender(), currentTokenId);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function changeSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        returns (uint256)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(
            index < totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}
