// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract monkETH is ERC721, Ownable {
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    bool public isPublicMintEnabled;
    bool public revealed = false;
    mapping(address => uint256) public walletMints;

    constructor() payable ERC721("monkETH", "MKETH") {
        mintPrice = 0.005 ether;
        totalSupply = 0;
        maxSupply = 808;
        maxPerWallet = 3;
        setHiddenMetadataUri(
            "ipfs://QmYFJgiTdTc7YKKMsEK72oTXPfNtRCH2vVK94S5nyNsREV/hidden.json"
        );
    }

    function setIsPublicMintEnabled(bool isPublicMintEnabled_)
        external
        onlyOwner
    {
        isPublicMintEnabled = isPublicMintEnabled_;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist!");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(_tokenId),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }

    function mint(uint256 _count) external payable {
        require(isPublicMintEnabled, "minting is not enabled");
        require(msg.value == _count * mintPrice, "wrong mint value");
        require(totalSupply + _count <= maxSupply, "sold out");
        walletMints[msg.sender] += _count;
        require(walletMints[msg.sender] < 4, "max per wallet exceeded");

        for (uint256 i = 0; i < _count; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
