//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ECDSA.sol";
import "./ERC721Enumerable.sol";

contract SapphireNFT is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;
    
    //variables
    int public STATE;
    uint256 public PURCHASE_PRICE = 0.1 ether;
    uint256 public RENEW_PRICE = 0.1 ether;
    
    uint256 private _stock;
    address private _signerAddress;
    string private _baseUri;
    
    mapping(uint256 => uint256) private _users;
    mapping(string => bool) private _usedNonces;
    
    constructor() public ERC721("SapphireLicense", "SPHR") {}

    // verify whether hash matches against tampering; use of others' minting opportunity, diff mint count etc
    function hashTransaction(address sender,string memory nonce) private pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, nonce)))
        );
            
        return hash;
    }
    
    // match serverside private key sign to set pub key
    function matchAddressSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.recover(signature);
    }
    
    function purchase(bytes memory signature, string memory nonce) external payable {
        require(STATE == 1, "NOT_LIVE");
        require(msg.value >= PURCHASE_PRICE, "INVALID_AMOUNT");
        require(balanceOf(msg.sender) == 0, "ONE_PER_ADDRESS");
        require(_stock > 0, "OUT_OF_STOCK");
        require(matchAddressSigner(hashTransaction(msg.sender, nonce), signature), "DIRECT_PURCHASE_DISALLOWED");
        require(!_usedNonces[nonce], "HASH_USED");
        
        _stock -= 1;
        _usedNonces[nonce] = true;
        uint256 tokenId = totalSupply() + 1;
        _users[tokenId] = block.timestamp + 30 days;
        _safeMint(msg.sender, tokenId);
    }
    
    function _isExpired(uint256 tokenId) internal view returns (bool) {
        return block.timestamp > _users[tokenId];
    }
    
    function renew(uint256 tokenId) external payable {
        require(STATE < 2, "CONTRACT_LOCKED");
        require(_exists(tokenId), "UNKNOWN_TOKEN_ID");
        require(ownerOf(tokenId) == msg.sender, "NOT_LICENSE_OWNER");
        require(_users[tokenId] > 0, "NOT_RENEWABLE");
        require(msg.value >= RENEW_PRICE, "INVALID_AMOUNT");
        
        if (_isExpired(tokenId)) {
            _users[tokenId] = block.timestamp + 30 days;
        } else {
            _users[tokenId] += 30 days;
        }
    }
    
    function gift(address to, bool lifetime) external onlyOwner {
        require(STATE < 2, "CONTRACT_LOCKED");
        require(balanceOf(to) == 0, "ONE_PER_ADDRESS");
        
        uint256 tokenId = totalSupply() + 1;
        _users[tokenId] = lifetime ? block.timestamp + (365 days * 10) : block.timestamp + 30 days;
        _safeMint(to, tokenId);
    }
    
    function setExpiry(uint256 tokenId, uint256 timestamp) external onlyOwner {
        require(STATE < 2, "CONTRACT_LOCKED");
        require(_exists(tokenId), "UNKNOWN_TOKEN_ID");

        _users[tokenId] = timestamp;
    }
    
    function isExpired(uint256 tokenId) external view returns(bool) {
        require(_exists(tokenId), "UNKNOWN_TOKEN_ID");

        return _users[tokenId] <= block.timestamp;
    }
    
    function getExpiry(uint256 tokenId) external view returns(uint256) {
        require(_exists(tokenId), "UNKNOWN_TOKEN_ID");
        
        return _users[tokenId];
    }
    
    function tokenByAddress(address _address) external view returns(uint256) {
        require(balanceOf(_address) > 0, "NOT_AN_OWNER");
        
        for (uint256 tokenId = 1; tokenId <= totalSupply(); tokenId++) {
            if (ownerOf(tokenId) == _address)
                return tokenId;
        }
        return 0;
    }
    
    function setPurchasePrice(uint256 price) external onlyOwner {
        PURCHASE_PRICE = price;
    }
    
    function setRenewPrice(uint256 price) external onlyOwner {
        RENEW_PRICE = price;
    }
    
    function setStock(uint256 amount) external onlyOwner {
        _stock = amount;
    }
    
    function pause() external onlyOwner {
        STATE = 0;
    }
    
    function startSale() external onlyOwner {
        STATE = 1;
    }
    
    function lock() external onlyOwner {
        STATE = 2;
    }
    
    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }
    
    function setBaseURI(string calldata uri) external onlyOwner {
        _baseUri = uri;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "UNKNOWN_TOKEN_ID");
        
        return bytes(_baseUri).length > 0 ? string(abi.encodePacked(_baseUri, tokenId.toString())) : "";
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        require(
            !_isExpired(tokenId),
            "EXPIRED"
        );

        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
