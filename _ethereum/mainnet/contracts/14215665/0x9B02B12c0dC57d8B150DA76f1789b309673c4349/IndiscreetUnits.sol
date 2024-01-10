// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721.sol";

contract IndiscreetUnits is ERC721, Ownable {
    uint16 private _tokenTokenIdMax = 266;
    string private _baseURIValue = "ipfs://Qma9HTcgo3YwD5KrEy8CF5gtWmpQYocM8VnNLpxwAvoeLb/";
    uint256 private _price = 0.1 ether;
    uint16 private _maxTokensPerWallet = 3;
    bool private _paused = true;
    address payable private adminWallet = payable(0x99271D7D8c789F2cD401D16d20282Df7FdB5bEf3    );

    constructor() ERC721("Indiscreet Units", "IU") {}

    function setTokenIdMax(uint16 newTokenIdMax) external onlyOwner {
        _tokenTokenIdMax = newTokenIdMax;
    }

    function setMaxTokensPerWallet(uint16 newMaxTokensPerWallet) external onlyOwner {
        _maxTokensPerWallet = newMaxTokensPerWallet;
    }

    function setPaused(bool newPaused) external onlyOwner {
        _paused = newPaused;
    }

    function mint(address recipient, uint16 tokenId)
        external
        payable
    {
        require(!_paused, "Contract not activated yet");
        require(balanceOf(recipient) < _maxTokensPerWallet , "Max. tokens per wallet exceeded");
        require(msg.value >= _price, "You did not send enough ether");
        require(tokenId <= _tokenTokenIdMax, "TokenId exceeds maximum");
        _safeMint(recipient, tokenId);
        adminWallet.transfer(msg.value);
    }

    function updateAdminWallet(address payable _adminWallet) external onlyOwner {
        adminWallet = _adminWallet;
    }

    function adminMint(address recipient, uint16 tokenId) external onlyOwner {
        _safeMint(recipient, tokenId);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        _price = newPrice;    
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseURIValue = newBaseURI;
    }
}
