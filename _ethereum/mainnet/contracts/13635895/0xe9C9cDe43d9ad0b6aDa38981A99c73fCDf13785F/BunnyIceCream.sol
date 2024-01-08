// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
    
contract BunnyIceCream is Ownable, ERC721 {
    
    uint32 public currentTokenId;             // increments with each new message

    string private _uriPrefix;                  // uri prefix

    uint256 public publicPrice;                 // price in utility token 1e18 units

    address public charityWallet1;

    address public charityWallet2;

    uint8 public charityPercentage1;

    uint8 public charityPercentage2;
    
    bool public isStoreOpen;

    constructor(uint256 _initialPrice, string memory _initURIPrefix, address _charityWallet1, uint8 _charityPercentage1, address _charityWallet2, uint8 _charityPercentage2, bool _isStoreOpen)
    ERC721("Bunny Ice Cream", "BIC")
    Ownable() 
    {
        currentTokenId = 0;
        charityWallet1 = _charityWallet1;
        charityWallet2 = _charityWallet2;
        charityPercentage1 = _charityPercentage1;
        charityPercentage2 = _charityPercentage2;
        _uriPrefix = _initURIPrefix;
        publicPrice = _initialPrice;
        isStoreOpen = _isStoreOpen;
    }

    function mintBunnyIceCream(uint8 _number) external payable {
        require(isStoreOpen == true, "STORE_CLOSED");
        require(_number <= 10, "TOO_MANY_MINTS");

        require(publicPrice * _number <= msg.value, "INSUFFICIENT_ETH");

        for(uint8 i = 0; i < _number; i++) {
            _mintBunnyIceCream();
        }
        payable(charityWallet1).transfer(charityPercentage1*publicPrice/100*_number);
        payable(charityWallet2).transfer(charityPercentage2*publicPrice/100*_number);
    }

    function _mintBunnyIceCream() internal {
        uint256 nextTokenId = _getNextTokenId();
        _safeMint(_msgSender(), nextTokenId);
        _incrementTokenId();
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _uriPrefix;
    }

    function _getNextTokenId() private view returns (uint256) {
        return currentTokenId + 1;
    }

    function _incrementTokenId() private {
        currentTokenId++;
    }

    function daoMint(uint8 _number) external onlyOwner {
        require(_number <= 10, "TOO_MANY_MINTS");

        for(uint8 i = 0; i < _number; i++) {
            _mintBunnyIceCream();
        }
    }

    // need to specify in units of 1e18 
    function setPrice(uint256 _newPrice) external onlyOwner {
        publicPrice = _newPrice;
    }     

    function setStoreOpen(bool _newStatus) external onlyOwner {
        isStoreOpen = _newStatus;
    }     

    function setURIPrefix(string calldata _newURIPrefix) external onlyOwner {
        _uriPrefix = _newURIPrefix;
    }

    function setCharity1(address _newCharityAddress, uint8 _percentage) external onlyOwner {
        charityWallet1 = _newCharityAddress;
        charityPercentage1 = _percentage;
    }

    function setCharity2(address _newCharityAddress, uint8 _percentage) external onlyOwner {
        charityWallet2 = _newCharityAddress;
        charityPercentage2 = _percentage;
    }
}