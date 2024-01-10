//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract SuddenlyUnicorns is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private supply;
    string public baseTokenURI = "";
    string public SUDDENLY_UNICORNS_PROVENANCE = "";
    uint256 public price = 25000000000000000; // 0.025 Ether
    uint256 public constant MAX_SUPPLY = 11111;
    uint256 public maxMintCount = 20;
    bool public isSaleActive = false;

    constructor(string memory _baseTokenURI)
        ERC721("Suddenly Unicorns", "SUNI")
    {
        setBaseURI(_baseTokenURI);
    }

    function mintTokens(uint256 _numberOfTokens) public payable {
        require(
            isSaleActive,
            "Sale is not active for minting Suddenly Unicorns."
        );
        require(
            (price * _numberOfTokens) <= msg.value,
            "ETH is not sufficient, please check the price required"
        );
        require(
            (balanceOf(msg.sender) + _numberOfTokens) <= maxMintCount,
            "Exceeds maximum number of tokens that can be owned"
        );
        require(
            (supply.current() + _numberOfTokens) <= MAX_SUPPLY,
            "Exceeds maximum supply"
        );

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            supply.increment();
            _safeMint(msg.sender, supply.current());
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMaxMintCount(uint256 _newMaxMintCount) public onlyOwner {
        maxMintCount = _newMaxMintCount;
    }

    function toggleSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        SUDDENLY_UNICORNS_PROVENANCE = _provenanceHash;
    }

    // GETTER FUNCTIONS
    function totalSupply() public view onlyOwner returns (uint256) {
        return supply.current();
    }

    function reserveTokens() public onlyOwner {
        for (uint256 i = 0; i < 5; i++) {
            supply.increment();
            _safeMint(msg.sender, supply.current());
        }
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawPartial(uint256 _amount) public payable onlyOwner {
        require(_amount <= address(this).balance, "not enough funds");
        require(payable(msg.sender).send(_amount));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}
