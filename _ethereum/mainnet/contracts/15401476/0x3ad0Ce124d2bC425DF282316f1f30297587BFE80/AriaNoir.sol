//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract AriaNoir is ERC721, Ownable, ReentrancyGuard {
    uint256 public whitelistPrice = 0.00 ether;
    uint256 public publicPrice = 0.05 ether;

    bool public paused = false;
    bool public onlyWhitelisted = true;

    mapping(uint256 => address) public whitelist;
    mapping(uint256 => string) public tokenUris;

    constructor() payable ERC721("AriaNoir", "ARANR") {}

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist!");
        return string(abi.encodePacked(tokenUris[_tokenId]));
    }

    function mint(uint256 _tokenId) public payable nonReentrant {
        require(!paused, "Contract is paused!");
        if (onlyWhitelisted == true) {
            require(!_exists(_tokenId), "Already claimed!");
            require(msg.sender == whitelist[_tokenId], "Not whitelisted!");
            if (whitelistPrice > 0) {
                require(msg.value >= whitelistPrice, "Insufficient funds!");
            }
        } else {
            if (publicPrice > 0) {
                require(msg.value >= publicPrice, "Insufficient funds!");
            }
        }
        _safeMint(msg.sender, _tokenId);
    }

    function updateWhitelist(
        address[] calldata _addesses,
        uint256[] calldata _tokens,
        string[] calldata _metaurls
    ) public onlyOwner {
        require(
            _addesses.length == _tokens.length &&
                _addesses.length == _metaurls.length,
            "Length of arrays must be equal!"
        );
        for (uint256 i = 0; i < _tokens.length; i++) {
            whitelist[_tokens[i]] = _addesses[i];
            tokenUris[_tokens[i]] = _metaurls[i];
        }
    }

    function giftToken(
        address[] calldata _addesses,
        uint256[] calldata _tokens,
        string[] calldata _metaurls
    ) public onlyOwner {
        require(
            _addesses.length == _tokens.length &&
                _addesses.length == _metaurls.length,
            "Length of arrays must be equal!"
        );
        for (uint256 i = 0; i < _tokens.length; i++) {
            _safeMint(_addesses[i], _tokens[i]);
            tokenUris[_tokens[i]] = _metaurls[i];
        }
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function setPublicPrice(uint256 _price) public onlyOwner {
        publicPrice = _price;
    }

    function setWhitelistPrice(uint256 _price) public onlyOwner {
        whitelistPrice = _price;
    }

    function setTokenUris(
        uint256[] calldata _tokens,
        string[] calldata _metaurls
    ) public onlyOwner {
        require(
            _tokens.length == _metaurls.length,
            "Length of arrays must be equal!"
        );
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenUris[_tokens[i]] = _metaurls[i];
        }
    }

    function withdraw() public {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw failed!");
    }
}
