// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Receiver.sol";

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// This is the main building block for smart contracts.
contract Registry is Ownable, IERC721Receiver {
    // Some string type variables to identify the token.
    // The `public` modifier makes a variable readable from outside the contract.
    string public name = "NFTRegistry";

    struct NFT {
        address c;
        uint256 tokenId;
    }

    struct Wishlist {
        address owner;
        string data;
        string name;
    }

    // Mapping from owner to token
    mapping(address => NFT[]) _tokens;
    mapping(address => mapping(uint256 => address)) _owners;

    // A mapping is a key/value map. Here we store the wishlist for an address
    mapping(string => Wishlist) _wishlists; // list name to wishlist
    mapping(string => NFT[]) _wishlistCurrent; // current items
    mapping(address => string[]) _wishlistsByOwner; // owner to list names
    uint256 public createPrice;
    uint256 public updatePrice;
    bool public disabled;

    constructor() Ownable()  {
        createPrice = 10000000000000000;
        updatePrice = 5000000000000000;
    }

    function setCreatePrice(uint256 price) onlyOwner external {
        createPrice = price;
    }

    function setUpdatePrice(uint256 price) onlyOwner external {
        updatePrice = price;
    }

    function setDisabled(bool d) onlyOwner public {
        disabled = d;
    }

     function withdraw() onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
     }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) public override returns (bytes4) {
        _tokens[from].push(NFT(msg.sender, tokenId));
        _owners[msg.sender][tokenId] = from;
        return this.onERC721Received.selector;
    }

    function updateWishlist(string memory listName, string memory displayName, string memory data) payable external {
        require (!disabled);
        address _currentOwner = _wishlists[listName].owner;
        require(_currentOwner == address(0) || _currentOwner == msg.sender);
        if (_currentOwner == address(0)) {
            require(msg.value >= createPrice);
            _wishlistsByOwner[msg.sender].push(listName);
        } else {
            require(msg.value >= updatePrice);
        }
        Wishlist memory w;
        w.owner = msg.sender;
        w.data = data;
        w.name = displayName;
        _wishlists[listName] = w;
    }

    // return wishlist data ipfs address
    function getWishlistWanted(string memory listName) external view returns (string memory) {
        return _wishlists[listName].data;
    }

    function getWishlistCurrent(string memory listName) external view returns (NFT[] memory) {
        return _wishlistCurrent[listName];
    }

    function transferOut(address account, address tokenContractAddress, uint256 tokenId) external {
        require(_owners[tokenContractAddress][tokenId] == msg.sender);
        IERC721 tokenContract = IERC721(tokenContractAddress);
        delete _owners[tokenContractAddress][tokenId];
        removeToken(tokenContractAddress, tokenId);
        tokenContract.safeTransferFrom(address(this), account, tokenId);
    }

    function claimAll() external {
        for (uint256 i = 0; i < _tokens[msg.sender].length; i++) {
            NFT memory token = _tokens[msg.sender][i];
            IERC721 tokenContract = IERC721(token.c);
            tokenContract.safeTransferFrom(address(this), msg.sender, token.tokenId);
            delete _owners[token.c][token.tokenId];
        }
        delete _tokens[msg.sender];
    }

    function transferToWishlist(string memory listName, address tokenContractAddress, uint256 tokenId) external {
        require(_owners[tokenContractAddress][tokenId] == msg.sender);
        delete _owners[tokenContractAddress][tokenId];
        _wishlistCurrent[listName].push(NFT(tokenContractAddress, tokenId));
        removeToken(tokenContractAddress, tokenId);
    }

    function removeToken(address tokenContractAddress, uint256 tokenId) private {
        uint256 index = _tokens[msg.sender].length;
        for (uint256 i = 0; i<_tokens[msg.sender].length; i++){
            if (_tokens[msg.sender][i].c == tokenContractAddress && _tokens[msg.sender][i].tokenId == tokenId) {
                index = i;
                break;
            }
        }

        if (index >= _tokens[msg.sender].length) {
            return;
        }
        _tokens[msg.sender][index] = _tokens[msg.sender][_tokens[msg.sender].length-1];
        _tokens[msg.sender].pop();
    }

    function claimFromWishlist(string memory listName) external {
        require(_wishlists[listName].owner == msg.sender);
        for (uint256 i=0; i < _wishlistCurrent[listName].length; i++) {
            NFT memory token = _wishlistCurrent[listName][i];
            IERC721 tokenContract = IERC721(token.c);
            tokenContract.safeTransferFrom(address(this), msg.sender, token.tokenId);
        }
        delete _wishlistCurrent[listName];
    }

    function getTokens() external view returns (NFT[] memory) {
        return _tokens[msg.sender];
    }

    function getWishlistOwner(string memory listName) external view returns (address) {
        return _wishlists[listName].owner;
    }

    function getWishlists() external view returns (string[] memory) {
        return _wishlistsByOwner[msg.sender];
    }

    function getWishlistName(string memory listName) external view returns (string memory) {
        return _wishlists[listName].name;
    }
}