// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ArchiePooch is ERC721Enumerable, Ownable {

    string public URI;
    
    bool public REVEALED = false;

    uint64 private _maxPurchase = 10;
    uint64 public saleState = 2; // 0 = paused, 1 = presale, 2 = live

    uint256 private _price = 0.04 ether;
    uint256 public constant MAX_ARCHIES = 3333;
    
    // list of addresses that have a number of reserved tokens for presale
    mapping(address => uint256) private _preSaleWhitelist;

    constructor() ERC721('ArchiePooch ', 'AP') {
        URI = 'ipfs://QmQrkxwAxXi5WRNvxBKmcWfMcVvivEMGLZHRLzZKdfNGsX';
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        if (REVEALED) {
            return string(abi.encodePacked(URI, Strings.toString(tokenId)));
        }
        return URI;
    }

    function toggleReveal(string memory updatedURI) public onlyOwner {
        REVEALED = !REVEALED;
        URI = updatedURI;
    }

    function setBaseURI(string memory updatedURI) public onlyOwner {
        URI = updatedURI;
    }


    function goMint(uint256 numberOfTokens) public payable {
        uint256 supply = totalSupply();

        if (msg.sender != owner()) {
            require(saleState > 1, 'Sale must be active to mint');
            require(
                msg.value >= _price * numberOfTokens,
                'Ether sent is not correct'
            );
        }
        require(
            numberOfTokens <= _maxPurchase,
            'You can only mint a few tokens at a time'
        );
        require(
            supply + numberOfTokens <= MAX_ARCHIES,
            'Purchase would exceed max supply'
        );
        
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function ownerMint(address _to, uint256 numberOfTokens) public onlyOwner {
        require(numberOfTokens > 0, "At least 1");
        uint256 supply = totalSupply();
        require(
            supply + numberOfTokens <= MAX_ARCHIES,
            "Purchase would exceed max supply"
        );

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }


    function getPrice() public view returns (uint256) {
        return _price;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function flipSaleStarted(uint64 _saleState) public onlyOwner {
        saleState = _saleState;
    }

    function withdraw() public onlyOwner {
        uint balanceP1 = (address(this).balance * 5) / 100;
        uint balanceP2 = (address(this).balance * 40) / 100;

        payable(0x6f566a6672f615C2975F6c48224c46153e12FFcf).transfer(balanceP1);
        payable(0x42dAf22f82516e5c43507983171626dA486d7054).transfer(balanceP2);

        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}