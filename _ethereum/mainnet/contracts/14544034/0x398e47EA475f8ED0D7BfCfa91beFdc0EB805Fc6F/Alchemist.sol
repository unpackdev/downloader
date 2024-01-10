// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract Alchemist is ERC721, Ownable { 

    using ECDSA for bytes32; 
    
    string internal baseTokenURI = 'https://us-central1-alchemist-order.cloudfunctions.net/api/asset/';

    uint public price = 0.08 ether;

    uint public maxSupply = 888;
    uint public totalSupply = 0;

    uint public maxTx = 8;
    uint public maxAssetsPresale = 8;

    bool public mintOpen = false;
    bool public presaleOpen = true;
    
    mapping(address => uint) private presaleMints;

    address private _signer = 0x9b208A7B07A75419C28a8B8510c2ce07C3B4Be5B;
    
    constructor() ERC721("Alchemist Order Genesis", "AOG") {}

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function setSigner(address newSigner) public onlyOwner {
        _signer = newSigner;
    }

    function togglePresale() external onlyOwner {
        presaleOpen = !presaleOpen;
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

    function setMaxAssetsPresale(uint newMax) external onlyOwner {
        maxAssetsPresale = newMax;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function giveaway(address to, uint qty) external onlyOwner {
        _mintTo(to, qty);
    }

    function _buyPresale(uint qty, bytes calldata signature_) external payable {
        require(presaleOpen, "presale closed");
        require(isInWhitelist(signature_), "address not in whitelist");
        require(presaleMints[_msgSender()] + qty <= maxAssetsPresale, "max presale mints reached");
        presaleMints[_msgSender()] += qty;
        _buy(qty);
    }

    function buy(uint qty) external payable {
        require(mintOpen, "store closed");
        _buy(qty);
    }

    function _buy(uint qty) internal {
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not alowed");
        require(msg.value >= price * qty, "PAYMENT: invalid value");
        require(qty + totalSupply <= maxSupply, "Sold out");
        _mintTo(_msgSender(), qty);
    }

    function _mintTo(address to, uint qty) internal {
        require(qty + totalSupply <= maxSupply, "SUPPLY: Value exceeds totalSupply");
        for(uint i = 0; i < qty; i++){
            totalSupply++;
            _safeMint(to, totalSupply);
        }
    }

    function isInWhitelist(bytes calldata signature_) private view returns (bool) {
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(abi.encodePacked(_msgSender())), signature_) == _signer;
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
    
}
