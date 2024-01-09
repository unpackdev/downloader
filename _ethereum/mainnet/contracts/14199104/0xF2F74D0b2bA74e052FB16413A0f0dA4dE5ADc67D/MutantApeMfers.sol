// SPDX-License-Identifier: UNLICENSED

/*


 __ __  __  __ __ ___ ___ ___   __  
|  V  |/  \|  V  | __| __| _ \/' _/ 
| \_/ | /\ | \_/ | _|| _|| v /`._`. 
|_| |_|_||_|_| |_|_| |___|_|_\|___/ 
                                                                                                                               

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract MutantApeMfers is ERC721A, Ownable {
    bool public saleEnabled;
    uint256 public mintPrice;
    string public metadataBaseURL;
    string public provenance;

    uint256 public maxTxn = 50;
    uint256 public constant maxSupply = 4444;

    constructor() ERC721A("Mutant Ape Mfers", "MAMFERS", maxTxn) {
        saleEnabled = false;
        mintPrice = 0.0169 ether;
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }


    function toggleSale() external onlyOwner {
        saleEnabled = !(saleEnabled);
    }

    function setMaxTxn(uint256 _maxTxn) external onlyOwner {
        maxTxn = _maxTxn;
    }

    function setPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        provenance = _provenance;
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function reserve(uint256 num) external onlyOwner {
        require((totalSupply() + num) <= maxSupply, "Exceed max supply");
        _safeMint(msg.sender, num);
    }

    function mint(uint256 numOfTokens) external payable {
        require(numOfTokens > 0, "Must mint 1 token or more");
        require(saleEnabled, "Sale isn't active");
        require(totalSupply() + numOfTokens <= maxSupply, "Exceed max supply");
        require(
            (mintPrice * numOfTokens) <= msg.value,
            "Insufficient funds to claim."
        );

        _safeMint(msg.sender, numOfTokens);
    }

}