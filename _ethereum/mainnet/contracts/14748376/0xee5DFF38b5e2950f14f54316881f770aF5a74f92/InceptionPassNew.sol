// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC1155Holder.sol";
import "./IERC721.sol";
// import "./Strings.sol";
import "./OwnerPausable.sol";
import "./ProxyTarget.sol";

contract InceptionPassNew is ERC1155, ERC1155Holder, OwnerPausable, ProxyTarget {
    bool public initialized;
    string private _symbol;
    string public name;
    mapping (uint256 => string) private _tokenURIs;

    IERC721 public oldPassNft;
    mapping(uint256 => bool) public claims;
    uint public totalClaimed;

    address w1;
    address w2;

    // uint8 public MAX_TX_MINT;
    // bool public isBuyOpen;
    // uint public buyPrice;
    uint256 public constant TOKEN_ID = 1;

    function initialize(string memory symbol_, string memory name_) external { // "https://game.example/api/item/{id}.json"
        require(msg.sender == _getAddress(ADMIN_SLOT), "not admin");
		require(!initialized);
		initialized = true;

        _setURI("");
        _transferOwnership(msg.sender);
        _symbol = symbol_;
        name = name_;

        // MAX_TX_MINT = 2;
        // isBuyOpen = false;
        // buyPrice = 0.2 ether;
        // _mint(address(this), TOKEN_ID, 750, "");
        w1 = 0x79792bF612bf456ff9ED70F5016C1c01Ee9c7598;
        w2 = 0xDE4CD210246271a3595870cE5442298550C0a263;
    }

    constructor() ERC1155("") { // "https://game.example/api/item/{id}.json"
        // _mint(address(this), TOKEN_ID, 750, "");
    }

    function setUri(string memory uri_) external onlyOwner {
        _setURI(uri_);
    }

    // function setBuyOpen(bool val_) external onlyOwner {
    //     isBuyOpen = val_;
    // }

    // function setBuyPrice(uint val_) external onlyOwner {
    //     buyPrice = val_;
    // }

    // function setMaxMint(uint8 amount_) external onlyOwner {
    //     MAX_TX_MINT = amount_;
    // }

    function setOldPassNft(address oldPassNft_) external onlyOwner {
        oldPassNft = IERC721(oldPassNft_);
    }

    function setSymbol(string memory sym) external onlyOwner {
        _symbol = sym;
    }

    function symbol() public virtual view returns (string memory) {
        return _symbol;
    }
    
    function setTokenUri(uint256 tokenId, string memory tokenURI) external onlyOwner {
         _tokenURIs[tokenId] = tokenURI; 
    } 

    /**
     * Sets the name of the pass. OpenSea uses this to determine the collection name.
     */
    function setName(string memory _name) external onlyOwner {
        name = _name;
    }

    function uri(uint256 tokenId) override public view returns (string memory) { 
        return(_tokenURIs[tokenId]); 
    }

    /** claim method to mint new pass */

    function claim(uint256[] calldata oldTokenIds) external {
        for (uint256 i = 0; i < oldTokenIds.length; i++) {
            require(oldTokenIds[i] >= 4500, "Not pass"); // check if old token id
            require(oldPassNft.ownerOf(oldTokenIds[i]) == msg.sender, "Invalid token holder");
            require(claims[oldTokenIds[i]] == false, "Already claimed");
            claims[oldTokenIds[i]] = true;
            oldPassNft.transferFrom(msg.sender, address(this), oldTokenIds[i]);
        }
        totalClaimed += oldTokenIds.length;
        // _safeTransferFrom(address(this), msg.sender, TOKEN_ID, oldTokenIds.length, "0x0");
        _mint(msg.sender, TOKEN_ID, oldTokenIds.length, hex"");
    }

    // function withdrawReserved(uint amount, address to) external onlyOwner {
    //     require(balanceOf(address(this), TOKEN_ID) >= amount, "Invalid amount");
    //     _safeTransferFrom(address(this), to, TOKEN_ID, amount, "0x0");
    // }

    // function buy(uint amount) external payable {
    //     require(isBuyOpen == true, "Buy not open");
    //     require(amount <= MAX_TX_MINT, "Exceeds number");
    //     require(balanceOf(address(this), TOKEN_ID) >= amount, "Out of supply");
    //     require(msg.value >= buyPrice * amount, "Value below price");
    //     _safeTransferFrom(address(this), msg.sender, TOKEN_ID, amount, "0x0");
    // }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(w1, balance * 85 / 100);
        _widthdraw(w2, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success,) = _address.call{value : _amount}("");
        require(success, "Transfer failed.");
    }

    // override

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }

    receive() external payable {}
}