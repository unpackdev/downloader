// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract CryptoAthletes is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 private constant PRICE_PER_CA = 5 * 10**16; // 0.05ETH Per Crypto Athletes

    uint256 private constant MAX_ELEMENTS_CROWDSALE = 1 * 10**4 + 20; // 10020 Crypto Athletes in CrowdSale
    uint256 private constant MAX_ELEMENTS_PRESALE = 5 * 10**2; // 500 Crypto Athletes in PreSale

    uint256 private constant MAX_MINT_CROWDSALE = 20; // Upper Limit is 10 in CrowdSale
    uint256 private constant MAX_MINT_PRESALE = 5; // Upper Limit is 2 in PreSale

    address private constant ownerAddress = 0x0081aD52FF7Eb8B5165777aa6adCf7d80cBF647D; // Wallet Address of Owner
    address public constant developerAddress = 0xA7482C9c5926E88d85804A969c383730Ce100639; // Wallet Address of the Cory

    mapping(uint256 => bool) private _isOccupiedId;
    uint256[] private _occupiedList;

    uint256 private maxSalesAmount;
    uint256 private maxMintAmount;

    string private baseTokenURI;

    event CreateCryptoAthletes(address to, uint256 indexed id);

    modifier saleIsOpen {
        require(_totalSupply() <= maxSalesAmount, "SALES: Sale end");

        if (_msgSender() != owner()) {
            require(!paused(), "PAUSABLE: Paused");
        }
        _;
    }

    constructor (string memory baseURI) ERC721("CryptoAthletes", "CATH") {
        setBaseURI(baseURI);
        pause(true);

        maxSalesAmount = MAX_ELEMENTS_CROWDSALE;
        maxMintAmount = MAX_MINT_CROWDSALE;
    }

    function mint(address payable _to, uint256[] memory _ids) public payable saleIsOpen {
        uint256 total = _totalSupply();

        require(total + _ids.length <= maxSalesAmount, "MINT: Current count exceeds maximum element count.");
        require(total <= maxSalesAmount, "MINT: Please go to the Opensea to buy Crypto Athletes.");
        require(_ids.length <= maxMintAmount, "MINT: Current count exceeds maximum mint count.");
        require(msg.value >= price(_ids.length), "MINT: Current value is below the sales price of Crypto Athletes");

        for (uint256 i = 0; i < _ids.length; i++) {
            require(_isOccupiedId[_ids[i]] == false, "MINT: Those ids already have been used for other customers");
        }

        for (uint256 i = 0; i < _ids.length; i++) {
            _mintAnElement(_to, _ids[i]);
        }
    }

    function _mintAnElement(address payable _to, uint256 _id) private {
        _tokenIdTracker.increment();
        _safeMint(_to, _id);
        _isOccupiedId[_id] = true;
        _occupiedList.push(_id);

        emit CreateCryptoAthletes(_to, _id);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function startPreSale() public onlyOwner {
        maxSalesAmount = MAX_ELEMENTS_PRESALE;
        maxMintAmount = MAX_MINT_PRESALE;
    }

    function stopPreSale() public onlyOwner {
        maxSalesAmount = MAX_ELEMENTS_CROWDSALE;
        maxMintAmount = MAX_MINT_CROWDSALE;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE_PER_CA.mul(_count);
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function occupiedList() public view returns (uint256[] memory) {
      return _occupiedList;
    }

    function maxMint() public view returns (uint256) {
        return maxMintAmount;
    }

    function maxSales() public view returns (uint256) {
        return maxSalesAmount;
    }

    function raised() public view returns (uint256) {
        return address(this).balance;
    }

    function getTokenIdsOfWallet(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function pause(bool value) public onlyOwner {
        if (value == true) {
            _pause();

            return;
        }

        _unpause();
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "WITHDRAW: No balance in contract");

        _widthdraw(developerAddress, balance.mul(3).div(100));
        _widthdraw(ownerAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "WITHDRAW: Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}