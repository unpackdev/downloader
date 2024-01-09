//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract BraveTigers is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    uint public totalSupply = 10000;
    uint public maxPresaleTokens = 2500;
    uint public maxTokensOnPresale = 5;
    uint public maxTokensOnSale = 5;
    uint public maxTokensToMintPerAddress = 15;
    uint public teamTokens = 50;

    // Prices
    uint private price = 0.2 ether;
    uint private presalePrice = 0.15 ether;

    string private notRevealedJson = "ipfs://QmSMgm99W58VRFUmog8HGqgKgbxi8nUxXfycJDeUrm8QHJ";
    string private ipfsBaseURI = "";

    bool public presaleActive = false;
    bool public publicSaleActive = false;
    bool public isRevealed = false;


    mapping(address => bool) public presaleWhitelist;
    mapping(address => uint) public mintedPerWallet;

    
    constructor () ERC721 ("Brave Tigers", "BRAVE"){
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        ipfsBaseURI = _baseURI;
    }

    function setPresaleActive() public onlyOwner {
        require(!isSaleActive(), "Sale already started!");
        presaleActive = true;
    }

    function setPublicSaleActive() public onlyOwner {
        require(presaleActive, "Presale is not active!");
        publicSaleActive = true;
        presaleActive = false;
    }

    function revealTokens() public onlyOwner {
        require(!isRevealed, "Tokens already revealed!");
        require(bytes(ipfsBaseURI).length > 0, "BaseURI not set!");
        isRevealed = true;
    }

    function addToWhitelist(address[] memory _addresses) public onlyOwner {
        require(!publicSaleActive, "Presale already ended!");
        require(_addresses.length >= 1, "You need to send at least one address!");
        for(uint i = 0; i < _addresses.length; i++) {
            presaleWhitelist[address(_addresses[i])] = true;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        if(isRevealed) {            
            return string(abi.encodePacked(ipfsBaseURI, "/", uint2str(tokenId), ".json"));
        }
        return string(abi.encodePacked(notRevealedJson, "/", uint2str(tokenId), ".json"));
    }

    function isSaleActive() public view returns(bool) {
        if(presaleActive || publicSaleActive) {
            return true;
        }
        return false;
    }

    function getPrice() public view returns(uint) {
        if(publicSaleActive) {
            return price;    
        } else if(presaleActive) {
            return presalePrice;
        }
        return 0;
    }

    function currentSupply() public view returns(uint) {
        return tokenIds.current();
    }

    function withdrawBalance() public onlyOwner {
        (bool success, ) = payable(owner()).call{value:address(this).balance}("");
        require(success, "Withdrawal failed!");
    }

    receive() external payable {       
    }

    function mintTiger(uint256 _amount) public payable {
        require(isSaleActive(), "Sale not started yet!");
        require(_amount + mintedPerWallet[msg.sender] <= maxTokensToMintPerAddress, string(abi.encodePacked("Not allowed to mint more than ", uint2str(maxTokensToMintPerAddress), " token(s) per wallet!")));
        require(msg.value >= getPrice() * _amount, string(abi.encodePacked("Not enough ETH! At least ", uint2str(getPrice()*_amount), " wei has to be sent!")));
        if(presaleActive) {
            require(mintedPerWallet[msg.sender] < maxTokensOnPresale, string(abi.encodePacked("You can't mint more than ", uint2str(maxTokensOnPresale), " token(s) on presale per wallet!")));
            require(presaleWhitelist[msg.sender], "You are not whitelisted to participate on presale!");
            require(_amount + mintedPerWallet[msg.sender] <= maxTokensOnPresale, string(abi.encodePacked("Not allowed to mint more than ", uint2str(maxTokensOnPresale), " token(s) per wallet on presale!")));
            require(_amount > 0 && _amount < maxTokensOnPresale + 1, string(abi.encodePacked("You can buy between 1 and ",  uint2str(maxTokensOnPresale), " tokens per transaction.")));
            require(maxPresaleTokens >= _amount + tokenIds.current(), "Not enough presale tokens left!");
        } else {
            require(_amount > 0 && _amount < maxTokensOnSale + 1, string(abi.encodePacked("You can buy between 1 and ",  uint2str(maxTokensOnSale), " tokens per transaction.")));
            require(totalSupply >= _amount + tokenIds.current(), "Not enough tokens left!");
        }

        for(uint256 i = 0; i < _amount; i++) {
            tokenIds.increment();
            uint256 newItemId = tokenIds.current();
            _safeMint(msg.sender, newItemId);
            mintedPerWallet[msg.sender]++;
        }
    }

    function mintForTeam() public onlyOwner {
        require(totalSupply >= teamTokens + tokenIds.current(), "Not enough tokens left!");

        for (uint256 i = 0; i < teamTokens; i++) {
            tokenIds.increment();
            uint256 newItemId = tokenIds.current();
            _safeMint(msg.sender, newItemId);
            mintedPerWallet[msg.sender]++;
        }
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
