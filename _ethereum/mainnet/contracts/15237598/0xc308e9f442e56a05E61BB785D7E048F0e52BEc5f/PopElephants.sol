// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Administration.sol";
import "./ECDSA.sol";

contract PopElephants is ERC721A, Ownable, Administration { 

    uint public price = 0.03 ether;
    uint public maxSupply = 5000;
    uint public maxTx = 20;

    bool private mintOpen = false;
    bool private presaleOpen = false;

    address private _signer;

    string internal baseTokenURI = 'https://us-central1-pop-elephants.cloudfunctions.net/api/asset/';
    
    constructor() ERC721A("Pop Elephants", "pelpt") {
        setSigner(_msgSender());
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

    function mintPresale(uint qty, bytes calldata signature_) external payable {
        require(presaleOpen, "store closed");
        require(isInWhitelist(signature_), "address not in whitelist");
        require(balanceOf(_msgSender()) + qty <= maxTx, "You can't buy more");
        _buy(qty);
    }
    
    function mint(uint qty) external payable {
        require(mintOpen, "store closed");
        _buy(qty);
    }

    function _buy(uint qty) internal {
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not alowed");
        uint free = balanceOf(_msgSender()) == 0 ? 1 : 0;
        require(msg.value >= price * (qty - free), "PAYMENT: invalid value");
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

    function togglePresale() external onlyOwner {
        presaleOpen = !presaleOpen;
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
    
}
