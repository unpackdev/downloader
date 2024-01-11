// SPDX-License-Identifier: MIT

// Phone on face

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract POF is ERC721A, Ownable {
    using Strings for uint256;

    string baseURI;
    uint256 public cost = 0.05 ether;
    uint256 public maxSupply = 5555;
    uint256 public maxMintAmount = 10;
    uint256 public amountMinted;
    uint256 public maxUserMintAmount = 20;
    mapping(address => uint256) public userMintedAmount;
    bool public paused = false;
    bool public revealed = false;

    constructor(string memory _initBaseURI) ERC721A("Phone on Face", "POF") {
        setBaseURI(_initBaseURI);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Sale is not active");
        require(_mintAmount > 0, "Must mint at least 1 POF");
        require(_mintAmount <= maxMintAmount, "No more than 10 POF in a tx");
        require(supply + _mintAmount <= maxSupply, "Max mint supply reached");

        if (msg.sender != owner()) {
            require(
                userMintedAmount[msg.sender] + _mintAmount <= maxUserMintAmount,
                "Over mint limit"
            );
            require(msg.value >= cost * _mintAmount, "Not enough eth sent");
        }

        amountMinted += _mintAmount;
        userMintedAmount[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}
