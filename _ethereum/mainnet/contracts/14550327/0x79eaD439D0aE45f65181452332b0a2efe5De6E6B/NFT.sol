// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "Base64.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public cost = 0.04 ether;
    uint256 public maxMintAmount = 1;
    bool public paused = false;

    address private devGuy = 0xA9889aAC1c8d0e8d5F874CdC9D475D0Dfcf32EB1;
    bool public devFunding = true;

    struct Word {
        string text;
    }
    mapping(uint256 => Word) public words;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function mint(uint256 _mintAmount, string memory _text) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();

        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );

        Word memory newWord = Word(string(abi.encodePacked(_text)));

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            words[supply + 1] = newWord;
            _safeMint(msg.sender, supply + 1);
        }
    }

    function buildImage(uint256 _tokenId) public view returns (string memory) {
        Word memory currentWord = words[_tokenId];
        return
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" width="640" height="480" viewBox="0 0 640 480" xml:space="preserve"><defs></defs><g transform="matrix(1 0 0 1 318 189.17)" style=""  ><text xml:space="preserve" font-family="Open Sans, sans-serif" font-size="18" font-style="normal" font-weight="normal" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-dashoffset: 0; stroke-linejoin: miter; stroke-miterlimit: 4; fill: rgb(255,246,245); fill-rule: nonzero; opacity: 1; white-space: pre;" ></text></g><g transform="matrix(0.68 0 0 0.6 320.02 221)"  ><g style=""><g transform="matrix(1 0 0 1 0.05 0)" id="Layer_1"  ><path style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-dashoffset: 0; stroke-linejoin: miter; stroke-miterlimit: 4; fill: rgb(0,0,0); fill-rule: nonzero; opacity: 1;"  transform=" translate(-500.05, -500)" d="M 914.9 785.1 H 85.1 C 65.7 785.1 50 769.4 50 750 V 250 c 0 -19.4 15.7 -35.1 35.1 -35.1 h 829.9 c 19.4 0 35.1 15.7 35.1 35.1 v 500 C 950 769.4 934.3 785.1 914.9 785.1 z" stroke-linecap="round" /></g><g transform="matrix(1 0 0 1 0 -186.15)" id="Layer_1"  ><rect style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-dashoffset: 0; stroke-linejoin: miter; stroke-miterlimit: 4; fill: rgb(204,204,204); fill-rule: nonzero; opacity: 1;"  x="-450" y="-43.25" rx="0" ry="0" width="900" height="86.5" /></g></g></g><g transform="matrix(1.16 0 0 1.16 313.96 348.04)" style=""  ><text xml:space="preserve" font-family="Open Sans, sans-serif" font-size="32" font-style="normal" font-weight="bold" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-dashoffset: 0; stroke-linejoin: miter; stroke-miterlimit: 4; fill: rgb(255,255,255); fill-rule: nonzero; opacity: 1; white-space: pre;" ><tspan x="-238" y="10.05" >',
                        currentWord.text,
                        "</tspan></text></g></svg>"
                    )
                )
            );
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function buildMetadata(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        Word memory currentWord = words[_tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                currentWord.text,
                                '", "description":"',
                                currentWord.text,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                buildImage(_tokenId),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return buildMetadata(_tokenId);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function pauseDevFunding() public {
        require(msg.sender == devGuy, "You are not developer");
        devFunding = false;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        if (devFunding) {
            (bool hs, ) = payable(devGuy).call{
                value: (address(this).balance * 50) / 100
            }("");
            require(hs);
        }
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
