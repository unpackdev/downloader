// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./ERC721A.sol";
import "./Administration.sol";
import "./ECDSA.sol";

contract Earless is ERC721A, Administration { 

    uint public price = 0.0045 ether;
    uint public wlPrice = 0.004 ether;
    uint public maxSupply = 2222;
    uint private maxTx = 20;
    uint public maxFree = 200;
    uint public freeCount = 0;

    bool public mintOpen = false;

    address private _signer;

    mapping(address => uint) public free;

    string internal baseTokenURI = 'https://us-central1-earless-nft.cloudfunctions.net/api/asset/';
    
    constructor(address signer_) ERC721A("Earle$$", "ERL") {
        setSigner(signer_);
    }

    function isInWhitelist(bytes calldata signature_) private view returns (bool) {
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(abi.encodePacked(_msgSender())), signature_) == _signer;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function buyTo(address to, uint qty) external onlyAdmin {
        _mintTo(to, qty);
    }

    function mintWhitelist(uint qty, bytes calldata signature_) external payable {
        require(mintOpen, "closed");
        require(isInWhitelist(signature_), "address not in whitelist");
        bool isFree = free[_msgSender()] == 0 && freeCount < maxFree;
        uint free_ = isFree ? 1 : 0;
        require(msg.value >= wlPrice * (qty - free_), "PAYMENT: invalid value");
        if(isFree){
            free[_msgSender()] = 1;
            freeCount++;
        }
        _buy(qty);
    }
    
    function mint(uint qty) external payable {
        require(mintOpen, "closed");
        require(msg.value >= price * qty, "PAYMENT: invalid value");
        _buy(qty);
    }

    function _buy(uint qty) internal {
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not alowed");
        _mintTo(_msgSender(), qty);
    }

    function _mintTo(address to, uint qty) internal {
        require(qty + totalSupply() <= maxSupply, "SUPPLY: Value exceeds totalSupply");
        _mint(to, qty);
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function setSigner(address newSigner) public onlyOwner {
        _signer = newSigner;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function setMaxFree(uint newMax) external onlyOwner {
        maxFree = newMax;
    }
    
}
