// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";

contract TheAwakening is ERC721, Ownable { 

    bool public saleActive = false;
    bool public presaleActive = false;
    bool public freeActive = false;
    
    string internal baseTokenURI;

    uint public price = 0.1 ether;
    uint public totalSupply = 9999;
    uint public saleMax = 8999;
    uint public nonce = 0;
    uint public maxTx = 20;

    mapping (address => uint256) public presaleWallets;
    mapping (address => uint256) public freeWallets;
    
    constructor() ERC721("The Awakening", "AWAKE") {}
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setTotalSupply(uint newSupply) external onlyOwner {
        totalSupply = newSupply;
    }

    function setSaleMax(uint supp) external onlyOwner {
        saleMax = supp;
    }

    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    function setFreeActive(bool val) public onlyOwner {
        freeActive = val;
    }

    function setPresaleWallets(address[] memory _a, uint256[] memory _amount) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            presaleWallets[_a[i]] = _amount[i];
        }
    }

    function setFreeWallets(address[] memory _a, uint256[] memory _amount) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            freeWallets[_a[i]] = _amount[i];
        }
    }

    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }
    
    function getAssetsByOwner(address _owner) public view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = 0; i < nonce; i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    
    function getMyAssets() external view returns(uint[] memory){
        return getAssetsByOwner(tx.origin);
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }
    
    function giveaway(address to, uint qty) external onlyOwner {
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        for(uint i = 0; i < qty; i++){
            nonce++;
            uint tokenId = nonce;
            _safeMint(to, tokenId);
        }
    }

    function buyPresale(uint qty) external payable {
        uint256 qtyAllowed = presaleWallets[msg.sender];
        require(presaleActive, "TRANSACTION: Presale is not active");
        require(qtyAllowed > 0, "TRANSACTION: You can't mint on presale");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        require(msg.value == price * qty, "PAYMENT: invalid value");
        presaleWallets[msg.sender] = qtyAllowed - qty;
        for(uint i = 0; i < qty; i++){
            nonce++;
            uint tokenId = nonce;
            _safeMint(msg.sender, tokenId);
        }
    }

    function freeMint(uint qty) external payable {
        uint256 qtyAllowed = freeWallets[msg.sender];
        require(freeActive, "TRANSACTION: free mint is not active");
        require(qtyAllowed > 0, "TRANSACTION: You can't mint on free mint");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        freeWallets[msg.sender] = qtyAllowed - qty;
        for(uint i = 0; i < qty; i++){
            nonce++;
            uint tokenId = nonce;
            _safeMint(msg.sender, tokenId);
        }
    }
    
    function buy(uint qty) external payable {
        require(saleActive, "TRANSACTION: sale is not active");
        require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not alowed");
        require(qty + nonce <= saleMax, "SUPPLY: Value exceeds saleMax");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        require(msg.value == price * qty, "PAYMENT: invalid value");
        for(uint i = 0; i < qty; i++){
            nonce++;
            uint tokenId = nonce;
            _safeMint(msg.sender, tokenId);
        }
    }
    
    function withdrawOwner() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}