// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

//  ____  _                      _      _   _ _____ _____ 
// |  _ \| |__   ___   ___ _ __ (_)_  _| \ | |  ___|_   _|
// | |_) | '_ \ / _ \ / _ \ '_ \| \ \/ /  \| | |_    | |  
// |  __/| | | | (_) |  __/ | | | |>  <| |\  |  _|   | |  
// |_|   |_| |_|\___/ \___|_| |_|_/_/\_\_| \_|_|     |_|   

contract PhoenixNFT is ERC721, ERC721Enumerable, Ownable {
    uint256 public MAX_SUPPLY = 50;
    uint256 public MINT_PRICE = 3.5 ether;

    bool public mintable = false;
    bool public whitelistMint = false;

    mapping(address => bool) public whitelist;
    mapping(address => bool) private _whitelistClaimed;
    uint256 private _nextTokenId;
    string private BASE_URI;

    constructor(
        address initialOwner
    ) ERC721("PhoenixNFT", "PHNX") Ownable(initialOwner) {}

    function addToWhitelist(address[] calldata _addrs) external onlyOwner {
        for (uint i = 0; i < _addrs.length; i++) {
            whitelist[_addrs[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata _addrs) external onlyOwner {
        for (uint i = 0; i < _addrs.length; i++) {
            delete whitelist[_addrs[i]];
        }
    }

    function checkWhitelist(address _addr) external view returns (bool) {
        return whitelist[_addr];
    }

    function togglePublicMint() external onlyOwner {
        mintable = !mintable;
    }

    function toggleWhitelistMint() external onlyOwner {
        whitelistMint = !whitelistMint;
    }

    function setPrice(uint256 _price) external onlyOwner {
        MINT_PRICE = _price;
    }

    function setSupply(uint256 _newSupply) external onlyOwner {
        require(totalSupply() < _newSupply);
        MAX_SUPPLY = _newSupply;
    }

    function mint() external payable {
        require(mintable, "Public mint is not active");
        require(!whitelistMint, "Mint through whitelist");
        require(
            totalSupply() < MAX_SUPPLY,
            "All tokens have been minted for now"
        );
        require(MINT_PRICE == msg.value, "Ether value sent is not correct");

        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
    }

    function mintWhitelist() external payable {
        require(whitelistMint, "Whitelist is not active");
        require(whitelist[msg.sender], "You are not on the whitelist");
        require(
            totalSupply() < MAX_SUPPLY,
            "All tokens have been minted for now"
        );
        require(MINT_PRICE == msg.value, "Ether value sent is not correct");
        require(
            !_whitelistClaimed[msg.sender],
            "You have already minted through the whitelist"
        );

        uint256 tokenId = _nextTokenId++;
        _whitelistClaimed[msg.sender] = true;
        _safeMint(msg.sender, tokenId);
    }

    function privateMint(address to) public onlyOwner {
        require(
            totalSupply() < MAX_SUPPLY,
            "All tokens have been minted for now"
        );
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        BASE_URI = URI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = address(owner()).call{value: balance}("");
        require(success);
    }
}