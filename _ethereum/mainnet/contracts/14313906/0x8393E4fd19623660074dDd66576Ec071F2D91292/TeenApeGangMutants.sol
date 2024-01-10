// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";

contract TeenApeGangMutants is ERC721, Ownable { 

    bool public saleActive = false;
    bool public claimActive = false;
    
    string internal baseTokenURI;

    uint public price = 0.05 ether;
    uint public totalSupply = 6000;
    uint public claimSupply = 2000;
    uint public saleSupply = 4000;
    uint public nonce = 0;
    uint public claimed = 0;
    uint public bought = 0;
    uint public maxTx = 3;
    
    event Mint(address owner, uint qty);
    event Giveaway(address to, uint qty);
    event Withdraw(uint amount);

    mapping (address => uint256) public claimWallets;
    
    constructor() ERC721("Teen Ape Gang Mutants", "TAGM") {}
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setTotalSupply(uint newSupply) external onlyOwner {
        totalSupply = newSupply;
    }

    function setSaleSupply(uint newSupply) external onlyOwner {
        saleSupply = newSupply;
    }

    function setClaimSupply(uint newSupply) external onlyOwner {
        claimSupply = newSupply;
    }

    function setClaimActive(bool val) public onlyOwner {
        claimActive = val;
    }

    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    function setClaimWallets(address[] memory _a, uint256[] memory _amount) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            claimWallets[_a[i]] = _amount[i];
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
            uint tokenId = nonce;
            _safeMint(to, tokenId);
            nonce++;
        }
        emit Giveaway(to, qty);
    }

    function claim(uint qty) external payable {
        uint256 qtyAllowed = claimWallets[msg.sender];
        require(claimActive, "TRANSACTION: Claim is not active");
        require(qtyAllowed > 0, "TRANSACTION: You can't claim that amount");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        require(qty + claimed <= claimSupply, "SUPPLY: Value exceeds ClaimSupply");
        claimWallets[msg.sender] = qtyAllowed - qty;
        for(uint i = 0; i < qty; i++){
            uint tokenId = nonce;
            _safeMint(msg.sender, tokenId);
            nonce++;
            claimed++;
        }
        emit Mint(msg.sender, qty);
    }
    
    function buy(uint qty) external payable {
        require(saleActive, "TRANSACTION: sale is not active");
        require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not alowed");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        require(qty + bought <= saleSupply, "SUPPLY: Value exceeds SaleSupply");
        require(msg.value == price * qty, "PAYMENT: invalid value");
        for(uint i = 0; i < qty; i++){
            uint tokenId = nonce;
            _safeMint(msg.sender, tokenId);
            nonce++;
            bought++;
        }
        emit Mint(msg.sender, qty);
    }
    
    function withdrawOwner() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}