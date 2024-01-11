//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract KaeruFrog is ERC721A, Ownable, ReentrancyGuard {
    string public baseURI = "ipfs://QmQvqcXQA5PEt2TmbfcGG8LdHxVtHk9WXxVwZyg1kksRcr/";
    uint   public price             = 0 ether;
    uint   public maxPerTx          = 10;
    uint   public maxPerFree        = 10;
    uint   public totalFree         = 6006;
    uint   public maxSupply         = 6006;

    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("KaeruFrog", "KaeruFrog"){}


    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI,Strings.toString(_tokenId+1),".json"))
            : "";
    }

    function mint(uint256 count) external payable {
        uint256 cost = price;
        bool isFree = ((totalSupply() + count < totalFree + 1) &&
            (_mintedFreeAmount[msg.sender] < maxPerFree));

        if (isFree) {
            require(msg.value >= (count * cost) - cost, "INVALID_ETH");
            require(totalSupply() + count <= maxSupply, "No more");
            require(count <= maxPerTx, "Max per TX reached.");
            _mintedFreeAmount[msg.sender] += count;
        }
        else{
            require(msg.value >= count * cost, "Please send the exact amount.");
            require(totalSupply() + count <= maxSupply, "No more");
            require(count <= maxPerTx, "Max per TX reached.");
        }

        _safeMint(msg.sender, count);
    }

    function Giveaways(address mintAddress, uint256 count) public onlyOwner {
        _safeMint(mintAddress, count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseUri(string memory baseuri_) public onlyOwner {
        baseURI = baseuri_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMaxTotalFree(uint256 MaxTotalFree_) external onlyOwner {
        totalFree = MaxTotalFree_;
    }

	function withdraw(uint amount) public onlyOwner {
		require(payable(msg.sender).send(amount));
	}
}