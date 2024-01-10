// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract dudZZ is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public constant maxPresaleMintsPerWallet = 4;

    uint256 public constant itemPrice = 80000000000000000;

    Counters.Counter private _nextTokenId;

    Counters.Counter private _mintedCount;

    uint256 private _maxMintTokenId = 0;

    mapping (address => uint256) private _presaleMints;

    bool private _areItemsReserved = false;

    string private baseURI;

    string public PROVENANCE_HASH;

    uint256 public TOTAL_ITEMS;

    bool public IS_SALE_ACTIVE = false;

    constructor(string memory name, string memory symbol, uint256 totalItems, string memory provenanceHash) ERC721(name, symbol) {
        TOTAL_ITEMS = totalItems;
        PROVENANCE_HASH = provenanceHash; // provenance hash set on init
        _nextTokenId.increment();
    }

    function reserveItems(uint256[] memory reservedItems) external onlyOwner {
        require(!_areItemsReserved, "Items are already reserved.");

        for (uint256 i = 0; i < reservedItems.length; i++) {
            _safeMint(owner(), reservedItems[i]);
            _mintedCount.increment();
        }
    }

    function setItemsReserved() external onlyOwner {
        _areItemsReserved = true;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function enableSale(uint256 maxMintTokenId) external onlyOwner {
        _maxMintTokenId = maxMintTokenId;
        IS_SALE_ACTIVE = true;
    }

    function disableSale() external onlyOwner {
        IS_SALE_ACTIVE = false;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : "";
    }

    function mint(uint256 mintCount) external payable returns(uint256) {
        uint256 mintTokenId = _nextTokenId.current();

        require(IS_SALE_ACTIVE, "Sale is inactive");
        require(mintCount > 0, "At least one must be minted");
        require(_presaleMints[msg.sender] + mintCount <= maxPresaleMintsPerWallet, "You can only mint 4 dudZZ");
        require(_mintedCount.current() + mintCount <= TOTAL_ITEMS, "Purchase would exceed max supply");
        require(itemPrice * mintCount <= msg.value, "ETH value is invalid");

        uint256 mintedCount = 0;
        while (mintedCount < mintCount) {
            mintTokenId = _nextTokenId.current();

            if (_mintedCount.current() > TOTAL_ITEMS || mintTokenId > _maxMintTokenId) {
                break;
            }

            _nextTokenId.increment();

            // reserved - skip
            if (_exists(mintTokenId)) {
                continue;
            }

            _safeMint(msg.sender, mintTokenId);
            mintedCount++;
            _mintedCount.increment();
        }

        require(mintedCount > 0, "Minting round has been finished");

        _presaleMints[msg.sender] += mintedCount;

        // return ETH to sender
        if (mintCount > mintedCount) {
            uint256 returnValue = (mintCount - mintedCount) * itemPrice;
            Address.sendValue(payable(msg.sender), returnValue);
        }

        return mintedCount;
    }

    function getTopMintTokenId() public view returns(uint256) {
        return _nextTokenId.current() - 1;
    }
}
