// SPDX-License-Identifier: GPL-3.0
/*
   The Miner Ape | Proof Of Aper                                                                                                     
 */                                                                                                

pragma solidity >=0.7.0 <0.9.0;
import "./ERC721A.sol";
import "./Ownable.sol";

contract ProofOfAper is ERC721A, Ownable {
    uint256 maxPerTx;
    string uri;
    uint256 cost;
    uint256 public maxSupply = 3300; // max supply
    mapping(address => uint256) public addrMinted;
    
    modifier verify(uint256 amount) {
        uint256 need;
        if (addrMinted[msg.sender] > 0) {
            need = amount * cost;
        } else {
            need = (amount - 1) * cost;
        }
        require(msg.value >= need, "No enough ether");
        if (cost == 0) {
            require(addrMinted[msg.sender] == 0);
        }
        _;
    }

    constructor() ERC721A("Proof Of Aper", "POA") {
        maxPerTx = 3;
    }
    
    function ape_mine(uint256 amount) payable public verify(amount) {
        require(totalSupply() + amount <= maxSupply, "SoldOut");
        require(amount <= maxPerTx, "MaxPerTx");
        addrMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function setCost(uint256 newcost, uint256 newmaxtx) public onlyOwner  {
        cost = newcost;
        maxPerTx = newmaxtx;
    }


    function setURI(string memory uri_) public onlyOwner {
        uri = uri_;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(uri, _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

