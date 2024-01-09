// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./NFT.sol";

contract Lucha3DKnockout is ERC721, Ownable { 

    bool public saleActive = false;
    bool public claimActive = false;
    
    string internal baseTokenURI;

    uint public price = 0.09 ether;
    uint public totalSupply = 4444;
    uint public claimSupply = 3333;
    uint public saleSupply = 1111;
    uint public nonce = 0;
    uint public claimed = 0;
    uint public maxTx = 3;

    NFT public NFTC;
    
    mapping(uint => bool) public luchaMints;
    uint[] public used;
    
    constructor(address nft) ERC721("Lucha 3D Knockout", "L3DKN") {
        setLuchaAddress(nft);
    }

    function setLuchaAddress(address newAddress) public onlyOwner {
        NFTC = NFT(newAddress);
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setTotalSupply(uint newSupply) external onlyOwner {
        totalSupply = newSupply;
    }

    function setClaimSupply(uint newSupply) external onlyOwner {
        claimSupply = newSupply;
    }

    function setSaleSupply(uint newSupply) external onlyOwner {
        saleSupply = newSupply;
    }

    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    function setClaimActive(bool val) public onlyOwner {
        claimActive = val;
    }

    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function getLuchaByOwner(address owner) public view returns (uint[] memory) {
        uint[] memory balance = new uint[](NFTC.balanceOf(owner));
        uint counter = 0;
        for (uint i = 0; i < NFTC.nonce(); i++) {
            if (NFTC.ownerOf(i) == owner) {
                balance[counter] = i;
                counter++;
            }
        }
        return balance;
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
    }

    function claim(uint[] memory ids) external payable {
        require(claimActive, "TRANSACTION: claim is not active");
        require(ids.length + claimed <= claimSupply, "SUPPLY: Value exceeds totalSupply");
        require(ids.length >= 3, "You need to own at least 3 LLKO nfts to be able to claim 3D");

        for(uint i=0; i < ids.length;i++){
            uint tokenId = ids[i];
            if((luchaMints[tokenId] != true) && (NFTC.ownerOf(tokenId) == _msgSender())){
              used.push(tokenId);
              if(used.length == 3){
                  _safeMint(_msgSender(), nonce);
                  luchaMints[tokenId] = true;
                  nonce++;
                  claimed++;
                  luchaMints[used[0]] = true;
                  luchaMints[used[1]] = true;
                  luchaMints[used[2]] = true;
                  delete used;
              }
            }
        }
    }

    function buy(uint qty) external payable {
        require(saleActive, "TRANSACTION: sale is not active");
        require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not alowed");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        require(qty + claimed <= saleSupply, "SUPPLY: Value exceeds saleSupply");
        require(msg.value == price * qty, "PAYMENT: invalid value");
        for(uint i = 0; i < qty; i++){
            uint tokenId = nonce;
            _safeMint(msg.sender, tokenId);
            nonce++;
        }
    }
    
    function withdrawOwner() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}