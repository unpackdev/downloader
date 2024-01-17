// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";


contract LuckyBears is ERC721, ERC721URIStorage, Ownable {
    // using Counters for Counters.Counter;

    // Counters.Counter private _tokenIdCounter;

    uint256 public counter;
    using Strings for uint256;

    string public baseExtension = ".json";

    string constant personalURI =
        "ipfs://QmPmdxiakuvr2nZr4mX5QapZJfLAe7854BdWas76GuDw1Y/";
    string constant companyURI =
        "ipfs://QmYWYaowVedBXEfoEyDzSCWkqZzRGjXNfFguSuEMEKjoZZ/";
    bool public mutex = false;

    error SaleHasentStarted();
    error AlreadyMinted();

    mapping(address => bool) public oneMintPerWallet;

    constructor() ERC721("Lucky Bears", "LB") {
        counter = 38;
    }

    function startSale() external onlyOwner {
        mutex = true;
    }

    function stopSale() external onlyOwner {
        mutex = false;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function safeMint() external payable {
        if (!mutex) {
            revert SaleHasentStarted();
        }
        if (oneMintPerWallet[msg.sender]) {
            revert AlreadyMinted();
        }
        if (counter >= 38 && counter <= 721) {
            if (counter <= 150) {
                require(msg.value >= 0.25 ether);
                personalMint();
            } else if (counter <= 400) {
                require(msg.value >= 0.30 ether);
                personalMint();
            } else if (counter <= 600) {
                require(msg.value >= 0.32 ether);
                personalMint();
            } else if (counter <= 721) {
                require(msg.value >= 0.35 ether);
                personalMint();
            }
        } else if (counter >= 722 && counter <= 1000) {
            if (counter <= 822) {
                require(msg.value >= 0.42 ether);
                companyMint();
            } else if (counter <= 900) {
                require(msg.value >= 0.45 ether);
                companyMint();
            } else if (counter <= 1000) {
                require(msg.value >= 0.49 ether);
                companyMint();
            }
        }
    }

    function personalMint() internal {
        uint256 tokenIds = counter;
        counter += 1;
        _safeMint(msg.sender, tokenIds);
        string memory uri = tokenURI(tokenIds);
        _setTokenURI(tokenIds, uri);
        oneMintPerWallet[msg.sender] = true;
    }

    function companyMint() internal {
        uint256 tokenIds = counter;
        counter += 1;
        _safeMint(msg.sender, tokenIds);
        string memory uri = tokenURI(tokenIds);
        _setTokenURI(tokenIds, uri);
        oneMintPerWallet[msg.sender] = true;
    }

    // function tokenURI(uint256 tokenIdz)
    //     public
    //     view
    //     override(ERC721, ERC721URIStorage)
    //     returns (string memory)
    // {
    //     return super.tokenURI(tokenIdz);
    // }

    function withDrawfunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

      function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (tokenId >=38 && tokenId <= 721){
        string memory currentBaseURI = personalURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";

        } else if(tokenId >=722 && tokenId <= 1000){
        string memory currentBaseURI = companyURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";

        }
    }
}