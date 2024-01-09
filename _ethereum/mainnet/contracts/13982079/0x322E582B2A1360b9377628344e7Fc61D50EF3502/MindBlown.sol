// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "ERC721.sol";
import "Ownable.sol";
import "ERC721Enumerable.sol";

contract MindBlown is ERC721, ERC721Enumerable, Ownable {
    string private _baseURIextended;
    string public provenanceHash;
    bool public saleActive = false;
    bool public whitelistActive = false;
    uint256 public maxTokens = 10000;

    uint8 public constant maxPublicQty = 5;
    uint256 public constant pricePerToken = 0.1 ether;
    uint256 private constant list1Price = 0.05 ether;
    uint256 private constant list2Price = 0.075 ether;

    mapping(address => uint8) private _allowList1Qty;
    mapping(address => uint8) private _allowList2Qty;

    constructor(string memory unrevealedURI) ERC721("Mind-Blown", "M | B") {
        _baseURIextended = unrevealedURI;
    }

    function flipSaleState(uint8[] calldata saleIdArr) external onlyOwner {
        for (uint256 i = 0; i < saleIdArr.length; i++) {
            if (saleIdArr[i] == 1) {
                whitelistActive = !whitelistActive;
            } else if (saleIdArr[i] == 2) {
                saleActive = !saleActive;
            }
        }
    }

    function voidUnminted() external onlyOwner {
        uint256 ts = totalSupply();
        require(maxTokens == 10000, "Unminted tokens have already been voided");
        maxTokens = ts;
        whitelistActive = false;
        saleActive = false;
    }

    function setWhitelist(address[] calldata addresses1, uint8 numAllowedToMint1, address[] calldata addresses2, uint8 numAllowedToMint2) external onlyOwner {
        for (uint256 i = 0; i < addresses1.length; i++) {
            _allowList1Qty[addresses1[i]] = numAllowedToMint1;
        }
        for (uint256 i = 0; i < addresses2.length; i++) {
            _allowList2Qty[addresses2[i]] = numAllowedToMint2;
        }
    }

    function whitelistMintCheck(address addr) external view returns (uint8, uint256) {
        if (_allowList1Qty[addr] > 0) {
            return (_allowList1Qty[addr], list1Price);
        } else if (_allowList2Qty[addr] > 0) {
            return (_allowList2Qty[addr], list2Price);
        } else {
            return (0, 0);
        }
    }

    function mintWhitelist(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(whitelistActive, "Whitelist is not active");
        require(ts + numberOfTokens <= maxTokens, "Purchase would exceed max tokens");
        if (_allowList1Qty[msg.sender] > 0) {
            require(numberOfTokens <= _allowList1Qty[msg.sender], "Exceeded max available to purchase");
            require(list1Price * numberOfTokens <= msg.value, "Ether value sent is not correct");
            _allowList1Qty[msg.sender] -= numberOfTokens;
        } else if (_allowList2Qty[msg.sender] > 0) {
            require(numberOfTokens <= _allowList2Qty[msg.sender], "Exceeded max available to purchase");
            require(list2Price * numberOfTokens <= msg.value, "Ether value sent is not correct");
            _allowList2Qty[msg.sender] -= numberOfTokens;            
        } else {
            revert("Could not mint whitelist");
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }    

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenanceHash(string memory provenance) public onlyOwner {
        provenanceHash = provenance;
    }

    function reserve(uint256 tokenCount) public onlyOwner {
      uint supply = totalSupply();
      require(supply + tokenCount <= maxTokens, "Reserve would exceed max tokens");
      for (uint256 i = 0; i < tokenCount; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    function mint(uint8 numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= maxPublicQty, "Exceeded max token purchase");
        require(ts + numberOfTokens <= maxTokens, "Purchase would exceed max tokens");
        require(pricePerToken * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
