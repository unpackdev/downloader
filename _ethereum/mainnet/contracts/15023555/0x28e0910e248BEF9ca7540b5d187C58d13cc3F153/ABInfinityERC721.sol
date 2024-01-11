// contracts/ABInfinity.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "Counters.sol";
import "PaymentSplitter.sol";

contract ABInfinityERC721 is ERC721, Ownable, PaymentSplitter {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string private _firstLaunchURI;
    uint8 private _maxInitialMintCount;
    Counters.Counter private _tokenIds;
    string private _futureSetbaseURI;
    uint96 royaltyFeesInBips = 250; // 2.5%

    constructor(string memory firstLaunchURI, uint8 maxInitialMintCount, address[] memory _artists, uint256[] memory _shares) ERC721("ABInfinity","ABI") PaymentSplitter(_artists, _shares) payable {
        _firstLaunchURI = firstLaunchURI;
        _maxInitialMintCount = maxInitialMintCount;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenIds.current();
    }

    function firstBatchMint(address[] memory toAddressList) external onlyOwner {
        require(toAddressList.length <= 50, "Too many addresses provided at once.");
        for (uint i = 0; i < toAddressList.length; i++) {
            uint256 newItemId = _tokenIds.current();
            require(newItemId < _maxInitialMintCount, "First batch mint limit exceeded");
            _mint(toAddressList[i], newItemId);
            _tokenIds.increment();
        }
    }

    function mint(address to) external onlyOwner {
        uint256 newItemId = _tokenIds.current();
        require(newItemId >= _maxInitialMintCount, "Must mint first batch before minting new collection NFTs.");
        require(bytes(_futureSetbaseURI).length > 0, "Must call setBaseURI before minting new collection NFTs.");
        _mint(to,newItemId);
        _tokenIds.increment();
    }
    
    function updateLaunchURI(string memory newURI) external onlyOwner {
        _firstLaunchURI = newURI;
    }

    function setBaseURI(string memory newURI) external onlyOwner {
        _futureSetbaseURI = newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        require(bytes(_futureSetbaseURI).length != 0, "Base URI has not been set.");
        return _futureSetbaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId <= _tokenIds.current(), 'invalid tokenId');
        string memory baseURI;
        if (tokenId < _maxInitialMintCount) { // tokens 0-94 are first batch.
            baseURI = _firstLaunchURI;
        }
        else {
            baseURI = _baseURI();
            
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function updateRoyaltyFee(uint96 _royaltyFeesInBips) external onlyOwner {
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    // standard function called by markets (OpenSea, etc) to execute royalties
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        returns (address, uint256)
    {
        return (address(this), _calculateRoyalty(_salePrice));
    }

    function _calculateRoyalty(uint256 _salePrice) view private returns (uint256) {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

}
