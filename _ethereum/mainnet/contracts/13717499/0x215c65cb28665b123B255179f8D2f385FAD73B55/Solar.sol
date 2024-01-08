// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Ownable.sol";



//
//
//
//      —————————————░░░░░░░░░░░░░░░░░░░░—██░░░░░—▓——░░░░░░░——░██▓—————░
//      ————————————░░░░░░░░░░░░░░░░░░░░░▓██—░░░░░░░—█▓░░░░░░░▓—█——————░
//      ————————————░░░░░░░░░░░░░░░░░░░░—▓█▓░░░░░░░░░░▓▓▓░░░░░—░▓█▓————▓
//      ————————————░░░░░░░░░░░░░░░░░░░—░██▓————░░░░░░░░▓—░░░░░———▓—▓▓—░
//      ——░————░—░░░░░░░░░░░░░░░░░░░░░░▓▓██▓——————░░░░░░░—░░░░░░—█———░░░
//      ░░░—░░░—░░░░░░░░░░░░░░░░░░░░░░—██▓———————————░░░———░░░░░░—▓——░░░
//      ░░░░░░—░░░░░░░░░░░░░░░░░░░░░░░▓▓█▓————————————————░░░░░░░░█▓————
//      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░—██░░———————————————░░░░░░░░▓▓——░░
//      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓███▓▓——▓—————————▓—░░░░░░░░░—█———▓
//      ░░░░░░░░░░░░░░░░░░░░░░░░—░░—▓▓██▓——————░————░░░░—░░░░░░░░░——█———
//      ░░░░░░░░░░░░░░░░░░░░░░—██▓—██▓——————————————░░░░░░░░░░░░░———▓—░—
//      ░░░░░░░░░░░░░░░░░░░░—▓██████▓—————————————————░░░░░░░░░░—▓░—█▓——
//      ░░░░░░░░░░░░░░░░░░░▓—█▓▓▓▓▓▓—————————————————░░░░░░░░░░░██▓▓█▓——
//      ░░░░░░░░░░░░░░░░░▓███▓▓———▓—————————————░——░░░░░░░░░░░░░▓▓—█▓———
//      ░░░░░░░░░░░░░—▓█▓███———░░——▓—————————░░░░░░░░░░░░░░░░░░░—█—█▓———
//      ░░░░░░—░—▓▓—███▓———————————————░░░░░░░░░░░░░░░░░░░░░░░░░░███▓———
//      ░░░————▓██▓—————————————————░░░░░░░░░░░░▓▓—░░░░░░░░░░—————▓—————
//      ████▓▓▓▓———————————————————░░░░░░░—░—▓▓░—█▓▓———————░—████———————
//      ———————————————————————————░░░░░░░█—░█████▓▓█████████———————————
//      —————————░░———————————————░░░░░░░—█—▓██████▓——░—————————————————
//      ——————————————————————————░░░░░░░▓▓██▓▓▓▓▓—————▓————————————————
//      —————————————————————————░░░░░░░░███▓———————————————————————————
//      —————————————░——————————░░░░░░░░————————————————————————————————
//      ————————————————————————░░░░░░░—██▓——————░░—————————————————————
//      —————————————————————░—░░░░░░░—███————————————————————————░—————
//      ——————————————————————░░░░░░░░▓▓▓—————————————————————————░—————
//      ——————————————————————░░░░░░░██▓———————————————————————————░░░▓—
//      —░———————————————————░░░░░░░███—————————————————————————————░░——
//      ░—░——————————————————░░░░░░——▓██————————————————░————————————░░—
//      ░░░░░░░░———————————░░░░░░░░▓▓—▓█▓——————————————░—————————————░░—
//      ░░░░░░░░░░░———░———░░░░░░░░▓—▓░—█▓—————░░—————————————————————░░░
//      ░░░░░░░░░░—░░░░░—░░░░░░░░—█▓██————————————————————————————————░░
//      
//                                                                                         
//
//      Solar, 2021
//
//      Martin Houra
//     
//      https://martinhoura.net/
//
//
//

contract Solar is ERC721Enumerable, ERC721Burnable, ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    event baseURIUpdated(string newBaseURL);

    constructor() ERC721("Solar", "SOLAR") {}

    bool public mintActive = false;
    uint256 public lastMintedId;
    uint256 public constant maxSupply = 100;
    uint256 public constant mintPrice = 0.35 ether;
    
    bool public baseURILocked = false;
    string public baseURI;

    // metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    // metadata update
    function setBaseURI(string memory _url) public onlyOwner {
        require(!baseURILocked, "Metadata on IPFS are locked.");
        emit baseURIUpdated(_url);
        baseURI = _url;
    }

    // metadata lock
    function setBaseLocked() public onlyOwner returns (bool) {
        baseURILocked = true;
        return baseURILocked;
    }

    // mint on/off button
    function mintState() public onlyOwner returns(bool) {
        mintActive = !mintActive;
        return mintActive;
    }

    function mint() public payable nonReentrant {
        require(mintActive, "Minting is not currently active.");
        require(
            lastMintedId < maxSupply,
            "Minting has ended."
        );
        require(mintPrice == msg.value, "Must use correct amount of ETH.");
        _mint();
    }

    function _mint() private {
        require(lastMintedId < maxSupply, "All minted already.");
        uint256 newTokenId = lastMintedId + 1;
        lastMintedId = newTokenId;
        _safeMint(msg.sender, newTokenId);
    }

    function reserveMint() public onlyOwner {
        _mint();
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}