// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract AiCatsNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _givedAmountTracker;

    string private _baseTokenURI;
    uint256 public maxTokenAmount = 8000;

    mapping(address => bool) private whiteListAddresses;

    mapping(address => bool) private mintedFreeAddresses;

    constructor() ERC721("AiCatsNFT", "AiCats") {
        _baseTokenURI = "ipfs://QmUsMY4VVv8rABRT85DJgYxZM5MboRNPACdj2mFTizEagR/";
        whiteListAddresses[owner()] = true;
    }

    function contractURI() external pure returns (string memory) {
        return "https://aicats.vercel.app/api/metadata_contract";
    }

    function mint(uint256 amount) external payable {
        _canMint(amount);
        require(
            msg.value >= amount * 50000000000000000, //amount * 0.05 eth
            "Invalid ether amount sent "
        );
        _mintAmount(msg.sender, amount);
        payable(owner()).transfer(msg.value);
    }

    function mint(address receiver, uint256 amount) external payable {
        _canMint(amount);
        require(whiteListAddresses[msg.sender], "must be whitelisted");
        _mintAmount(receiver, amount);
        payable(msg.sender).transfer(msg.value);
    }

    function _canMint(uint256 amount) internal view {
        require(
            amount <= maxTokenAmount - _tokenIdTracker.current(),
            "Not enough left"
        );
    }

    function amountLeft() public view returns (uint256) {
        return maxTokenAmount - _tokenIdTracker.current();
    }

    function canMintFree(address account) public view returns (bool) {
        return mintedFreeAddresses[account] == false;
    }

    function _mintAmount(address to, uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            _tokenIdTracker.increment();
            _mint(to, _tokenIdTracker.current());
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
