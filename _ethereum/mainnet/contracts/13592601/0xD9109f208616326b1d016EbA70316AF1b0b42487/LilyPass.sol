// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";

/*
 _         _              ___                     
( )     _ (_ )           (  _`\                   
| |    (_) | |  _   _    | |_) )  _ _   ___   ___ 
| |  _ | | | | ( ) ( )   | ,__/'/'_` )/',__)/',__)
| |_( )| | | | | (_) |   | |   ( (_| |\__, \\__, \
(____/'(_)(___)`\__, |   (_)   `\__,_)(____/(____/
               ( )_| |                            
               `\___/'                            
*/

contract LilyPass is
    ERC721,
    ERC721URIStorage,
    ReentrancyGuard,
    Pausable
{
    uint256 maxPerTx = 4;
    uint256 public availableSupply = 0;
    uint256 public publicSupply = 190;
    uint256 public maxSupply = 201;
    uint256 private _price = 40_000_000_000_000_000; //0.04 ETH
    address private _owner;
    address private _payee;
    string private _uri;
    uint _tokenId = 1;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    // map address to num tokens owned
    mapping(address => uint256) _tokenCount;
    // map tokenId to address of owner
    mapping(uint256 => address) _tokensOwned;

    constructor(
        address payee,
        string memory uri
    ) ERC721("LilyPass", "LP") {
        _owner = msg.sender;
        _payee = payee;
        _uri = uri;
        pause();
    }

    function setPayee(address addr) public onlyOwner {
        _payee = addr;
    } 

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    // @dev surface cost to mint
    function price() public view returns (uint256) {
        return _price;
    }

    // @dev add amount to current available supply
    function setAvailable(uint256 amount) public onlyOwner whenPaused {
        require((availableSupply + amount) < maxSupply, "exceeds public supply");
        availableSupply = availableSupply + amount;
    }

    // @dev change cost to mint protects against price movement
    function setPrice(uint256 amount) public onlyOwner {
        _price = amount;
    }

    // @dev returns number of tokens owned by address
    function tokenCount(address addr) public view returns (uint256) {
        return _tokenCount[addr];
    }
    // @dev website mint function
    function mint(uint256 num) public payable whenNotPaused nonReentrant {
        require(
            totalSupply() + num <= availableSupply,
            "no availability"
        );
        require(
            totalSupply() + num <= publicSupply,
            "resource exhausted"
        );
        require(num <= maxPerTx, "request limit exceeded");
        require(price() * num <= msg.value, "not enough funds");
        require(_tokenCount[msg.sender] < 5, "token max reached");
        require(_tokenCount[msg.sender] + num < 5, "exceeds token limit");

        for (uint256 i = 0; i < num; i++) {
            _tokenCount[msg.sender] += 1;
            _tokensOwned[_tokenId] = msg.sender;
            _mint(msg.sender, _tokenId);
            _tokenId++;
        }
    }
    // @dev owner can safely mint
    function safeMint(address to, uint256 num) public onlyOwner nonReentrant {
        require(
            totalSupply() + num <= availableSupply,
            "no availability"
        );
        require(
            totalSupply()  + num <= maxSupply,
            "resource exhausted"
        );
        _safeMint(to, _tokenId);
        _tokenId++;
    }
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    // @dev withdraw funds
    function withdraw() public onlyOwner {
        (bool success, ) = _payee.call{value: address(this).balance}("");
        require(success, "tx failed");
    }
    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "caller is not owner");
        _;
    }
    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        }
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        require(1 <= _tokenCount[msg.sender], "nothing to burn");
        _tokenCount[msg.sender] = _tokenCount[msg.sender] - 1;
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
        
    {
        return  string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }
}
