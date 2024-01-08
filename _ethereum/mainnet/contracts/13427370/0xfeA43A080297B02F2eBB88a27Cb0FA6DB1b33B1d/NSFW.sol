// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract PlanetWaifu {
    function balanceOf(address) public returns (uint256) {}

    function ownerOf(uint256) public returns (address) {}
}

contract NSFW is ERC721Enumerable, Ownable {
    uint256 public tokenPrice;
    uint256 public freeThreshold = 1000;
    uint256 public freePer = 3;
    bool public paused = false;
    string _baseTokenURI;

    uint256 public totalMinted;

    mapping(address => uint256) public freeItemsReceived;

    PlanetWaifu planetWaifuContract;

    constructor(
        string memory baseURI,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _price,
        address pwAddress
    ) ERC721(tokenName, tokenSymbol) {
        _baseTokenURI = baseURI;
        tokenPrice = _price;
        planetWaifuContract = PlanetWaifu(pwAddress);
    }

    function mint(uint256[] memory tokens) public payable {
        require(!paused || msg.sender == owner(), "We're paused");

        uint256 totalPrice = 0;
		uint256 balance = planetWaifuContract.balanceOf(msg.sender);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 token = tokens[i];
            require(
                planetWaifuContract.ownerOf(token) == msg.sender,
                "Not the owner of the Planet Waifu NFT"
            );
            uint256 price = tokenPrice;
            if (token <= freeThreshold) {
                price = 0;
            } else if (freeItemsReceived[msg.sender] < balance / freePer) {
                price = 0;
                freeItemsReceived[msg.sender]++;
            }
            totalPrice += price;
        }

        require(msg.value >= totalPrice, "Didn't send enough ETH");

        for (uint256 i = 0; i < tokens.length; i++) {
            _safeMint(msg.sender, tokens[i]);
        }
        totalMinted += tokens.length;
    }

    function tokensExist(uint256[] memory tokens)
        public
        view
        returns (bool[] memory)
    {
        bool[] memory ret = new bool[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 token = tokens[i];
            if (_exists(token)) {
                ret[i] = true;
            }
        }

        return ret;
    }

    function devMint(uint256 id) external onlyOwner {
        _safeMint(planetWaifuContract.ownerOf(id), id);
        totalMinted++;
    }

    function devMintMultiple(uint256[] memory tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 id = tokens[i];
            _safeMint(planetWaifuContract.ownerOf(id), id);
        }
        totalMinted += tokens.length;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setTokenPrice(uint256 _price) external onlyOwner {
        tokenPrice = _price;
    }

    function setFreeThreshold(uint256 _threshold) external onlyOwner {
        freeThreshold = _threshold;
    }

    function setFreePer(uint256 _per) external onlyOwner {
        freePer = _per;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function pause(bool val) external onlyOwner {
        paused = val;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
