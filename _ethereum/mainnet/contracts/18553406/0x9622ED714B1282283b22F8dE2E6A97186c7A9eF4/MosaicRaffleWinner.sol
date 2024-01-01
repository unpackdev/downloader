// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract MosaicRaffleWinner is ERC721AQueryable, Ownable {
    using Strings for uint256;

    string public uriPrefix = "https://mosaicraffle.s3.amazonaws.com/json/";
    string public uriSuffix = ".json";

    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    address[] public lotteryAddresses; // Array of lottery addresses

    constructor() ERC721A("MosaicRaffleWinner", "MRW") Ownable(msg.sender) {
        maxSupply = 2000;
        setMaxMintAmountPerTx(20);
    }

    modifier onlyMinter() {
        require(isAuthorizedMinter(msg.sender), "Caller is not authorized");
        _;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    // New function to check if an address is an authorized minter
    function isAuthorizedMinter(address _address) public view returns (bool) {
        for (uint i = 0; i < lotteryAddresses.length; i++) {
            if (lotteryAddresses[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // Function to set multiple lottery addresses
    function setLotteryAddresses(address[] memory _lotteryAddresses) public onlyOwner {
        lotteryAddresses = _lotteryAddresses;
    }

    function mintForAddress(
        uint256 _mintAmount,
        address _receiver
    ) public mintCompliance(_mintAmount) onlyMinter {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setMaxMintAmountPerTx(
        uint256 _maxMintAmountPerTx
    ) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
