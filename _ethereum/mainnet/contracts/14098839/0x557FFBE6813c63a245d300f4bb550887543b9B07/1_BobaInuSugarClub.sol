// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Strings.sol";

contract BobaInuSugarClub is Ownable, ERC721 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _token_id;
    Counters.Counter private _reserved_quantity;

    uint256 public constant inuPrice = 0.05 ether;
    uint256 public constant whitelistPrice = 0.03 ether;
    uint256 public constant maxMintAmount = 20;
    uint256 public constant whitelistMintLimit = 3;
    uint256 public maxSupply = 8000;
    uint256 public season = 1;
    string public baseURI;
    bool public saleActive = false;
    bool public isPresale = true;
    bool public forceReveal = false;
    address[] whitelist;

    mapping(uint256 => string) private id_to_uri;

    constructor(string memory _baseURI) ERC721("BobaInuSugarClub", "BISC") {
        baseURI = _baseURI;
    }

    function mintReserved(address to, uint256 quantity) public onlyOwner {
        require(_reserved_quantity.current() + quantity <= 100, "Reserving too many");
        for (uint256 i = 1; i <= quantity; i++) {
            _reserved_quantity.increment();
            uint256 id = maxSupply + _reserved_quantity.current();
            _safeMint(to, id);
            id_to_uri[id] = string(abi.encodePacked(baseURI, id.toString(), ".json"));
        }
    }

    function getOwnedReserved(address owner) private view returns(uint256) {
        uint256 count = 0;
        for (uint256 i = 8001; i <= 8100; i++) {
            if (_exists(i) && ownerOf(i) == owner) {
                count++;
            }
        }
        return count;
    }

    function mint(uint256 quantity) public payable {
        require(saleActive == true, "Sale is not open");
        require(quantity <= maxMintAmount, "Minting too many");
        if (isPresale == true) {
            require(isWhitelisted(msg.sender), "User is not whitelisted");
            uint256 owned = balanceOf(msg.sender) - getOwnedReserved(msg.sender);
            require(owned < whitelistMintLimit, "You already possess 3 presale NFTs");
            require(owned + quantity <= whitelistMintLimit, "Minting too many tokens");
        }
        require(totalSupply() + quantity <= season * 2000, "Mint amount exceeds current max supply");
        uint256 cost = isPresale == true ? whitelistPrice : inuPrice;
        require(msg.value >= quantity * cost, "Ether payment is not enough");

        for (uint256 i = 1; i <= quantity; i++) {
            _token_id.increment();
            _safeMint(msg.sender, _token_id.current());
            id_to_uri[_token_id.current()] = string(abi.encodePacked(baseURI, _token_id.current().toString(), ".json"));
        }
    }

    function isWhitelisted(address user) public view returns(bool) {
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == user) {
                return true;
            }
        }
        return false;
    }

    function getWhitelist() public view returns(address[] memory) {
        return whitelist;
    }

    function setWhitelist(address[] calldata newWhitelist) public onlyOwner {
        require(newWhitelist.length <= 500, "Whitelist too large");
        delete whitelist;
        whitelist = newWhitelist;
    }

    function setIsPresale(bool _isPresale) public onlyOwner {
        isPresale = _isPresale;
    }

    function setSaleActive(bool _saleActive) public onlyOwner {
        saleActive = _saleActive;
    }

    function totalSupply() public view returns(uint256) {
        return _token_id.current();
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function tokenURI(uint256 id) public view virtual override returns(string memory) {
        require(_exists(id), "Token id does not exist");
        if (id > 8000 || forceReveal == true || _token_id.current() >= season * 2000) {
            return id_to_uri[id];
        } else {
            return string(abi.encodePacked(baseURI, "0.json"));
        }
    }

    function setTokenURI(uint256 id, string memory uri) public onlyOwner {
        require(_exists(id), "Token id does not exist");
        id_to_uri[id] = uri;
    }

    function releaseNextSeason() public onlyOwner {
        require(season < 4, "Already final season");
        season++;
    }

    function setForceReveal(bool _forceReveal) public onlyOwner {
        forceReveal = _forceReveal;
    }
}