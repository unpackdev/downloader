// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

/*
                                                                   
 _____                _         _             _            _   
/  __ \              | |       | |           | |          | |  
| /  \/  ___    ___  | | _ __  | |__    __ _ | |__    ___ | |_ 
| |     / _ \  / _ \ | || '_ \ | '_ \  / _` || '_ \  / _ \| __|
| \__/\| (_) || (_) || || |_) || | | || (_| || |_) ||  __/| |_ 
 \____/ \___/  \___/ |_|| .__/ |_| |_| \__,_||_.__/  \___| \__|
                        | |                                    
                        |_|                                    

                Coolphabet: The cool letters crew
                
Visit us on http://coolphabet.art

Contact:

If you want to say hello or just drop congratulations please send an email to:
team@coolphabet.art

Credits:

Buildspace(https://buildspace.so/) and Farza (https://twitter.com/FarzaTV) helped us 
to create this beautiful NFT collection. Thank you so much ♥♥♥

 */
contract Coolphabet is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // maximum number of token
    uint256 public constant MAX_TOKEN = 36 * 6;
    uint256 public constant MAX_PER_MINT = 5;

    uint256 _mintPrice = 0.05 ether;

    mapping(address => bool) public _whiteList;

    bool _isPresale = true;

    string _baseTokenUri =
        "ipfs://QmbFemacpnw7YsCNj6QAxk25NuRUoTUPc4og1dKfyjsTr8/";

    event LetterMinted(address sender, uint256 tokenId);

    constructor() ERC721("Coolphabet: The Cool Letters Crew", "COOLPHABET") {}

    function mint(uint256 amount) public payable {
        uint256 newItemId = _tokenIds.current();

        require(amount > 0 && amount <= MAX_PER_MINT, "Only 1-5 allowed");
        require(newItemId + amount < MAX_TOKEN, "Max number of token minted.");

        require(
            msg.value >= _mintPrice * amount,
            "Please call with enough money."
        );

        if (_isPresale) {
            require(
                _whiteList[msg.sender] == true,
                "Only whitelist can mint in presale"
            );
        }

        for (uint256 i = 0; i < amount; i++) {
            _mintLetter(msg.sender);
        }
    }

    function sendGifts(address[] memory gifts) public onlyOwner {
        for (uint256 index = 0; index < gifts.length; index++) {
            address gift = gifts[index];
            _mintLetter(gift);
        }
    }

    function _mintLetter(address to) private {
        uint256 newItemId = _tokenIds.current();
        _safeMint(to, newItemId);
        _tokenIds.increment();
        emit LetterMinted(to, newItemId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenUri;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenUri = _newBaseURI;
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

        string memory newstring = string(
            abi.encodePacked(_baseTokenUri, Strings.toString(tokenId), ".json")
        );

        return newstring;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        _mintPrice = _newMintPrice;
    }

    function setWhiteList(address[] calldata addresses) external onlyOwner {
        uint256 count = addresses.length;
        for (uint256 i = 0; i < count; i++) {
            _whiteList[addresses[i]] = true;
        }
    }

    function iamInWhitelist() public view returns (bool) {
        return _whiteList[msg.sender] == true;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function isPresale() public view returns (bool) {
        return _isPresale;
    }

    function setIsPresale(bool _newIsPresale) public onlyOwner {
        _isPresale = _newIsPresale;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}
