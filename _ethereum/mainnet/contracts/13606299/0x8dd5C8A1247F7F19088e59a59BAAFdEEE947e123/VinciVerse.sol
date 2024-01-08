// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./SignatureChecker.sol";

/// @custom:security-contact contact@vinciverse.io
contract VinciVerse is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("VinciVerse", "VINCI") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://vinciverse.io/nft/api/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdrawBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(this.owner()).call{value: balance}("");
        require(success, "My withdrawal failed.");
    }

    uint16 public maxScrolls = 88;
    uint256 public mintPrice = 4 ether / 100; // 0.04 ETH
    uint16 public maxTokensPerWallet = 4;
    uint8 public availableScrollType = 1; // Starts with OG Mint
    event AvailableScrollTypeChanged(uint8 scrollType);
    function setMintPrice(uint8 _scrollType, uint16 _maxScrolls, uint256 _price, uint16 _maxTokensPerWallet) public onlyOwner {
        require(_maxScrolls <= 8888, "Number of scrolls is capped at 8888;");
        availableScrollType = _scrollType;
        maxScrolls = _maxScrolls;
        mintPrice = _price;
        maxTokensPerWallet = _maxTokensPerWallet;
        emit AvailableScrollTypeChanged(_scrollType);
    }

    event NewScrollUnlocked(address sender, uint256 tokenId);
    function mintAirScrolls(address payable[] memory _to_addr) public onlyOwner {
        require(totalSupply() + _to_addr.length <= maxScrolls, "Mint would exceed max supply.");
        // Mint price is 0 ETH for AirScolls
        for(uint16 i = 0; i < _to_addr.length; i++) {
            address payable to = _to_addr[i];
            uint256 newItemId = _tokenIdCounter.current();
            if (totalSupply() < maxScrolls) {
                _safeMint(to, newItemId);
                _tokenIdCounter.increment();
                emit NewScrollUnlocked(to, newItemId);
            }
        }
    }

    function isOG(address _wallet, bytes memory _signature) public view returns (bool) {
        return SignatureChecker.isValidSignatureNow(this.owner(), keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n24isOG",_wallet)), _signature);
    }

    function mintOGScrolls(uint16 _numTokens, bytes memory _signature) public payable {
        require(availableScrollType == 1, "OGScrolls must be approved.");
        require(isOG(msg.sender, _signature), "Your wallet is not in OG list. Please swith to your OG wallet.");
        require(totalSupply() + _numTokens <= maxScrolls, "Mint would exceed max supply.");
        require(msg.value >= mintPrice * _numTokens, "Ether value sent is not correct.");
        require(balanceOf(msg.sender) + _numTokens <= maxTokensPerWallet, "Mint would exceed max tokens per wallet.");

        for(uint16 i = 0; i < _numTokens; i++) {
            address payable to = payable(msg.sender);
            uint256 newItemId = _tokenIdCounter.current();
            if (totalSupply() < maxScrolls) {
                _safeMint(to, newItemId);
                _tokenIdCounter.increment();
                emit NewScrollUnlocked(to, newItemId);
            }
        }
    }

    function mintPublicScrolls(uint16 _numTokens) public payable {
        require(availableScrollType == 2, "Public Scrolls must be approved.");
        require(totalSupply() + _numTokens <= maxScrolls, "Mint would exceed max supply.");
        require(msg.value >= mintPrice * _numTokens, "Ether value sent is not correct.");
        require(balanceOf(msg.sender) + _numTokens <= maxTokensPerWallet, "Mint would exceed max tokens per wallet.");

        for(uint16 i = 0; i < _numTokens; i++) {
            address payable to = payable(msg.sender);
            uint256 newItemId = _tokenIdCounter.current();
            if (totalSupply() < maxScrolls) {
                _safeMint(to, newItemId);
                _tokenIdCounter.increment();
                emit NewScrollUnlocked(to, newItemId);
            }
        }
    }
}
