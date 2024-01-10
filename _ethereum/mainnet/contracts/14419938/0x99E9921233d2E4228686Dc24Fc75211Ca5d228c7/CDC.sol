// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";


contract CryptoDicksClub is Ownable, ERC721Enumerable, ERC721Burnable {
    using Address for address;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    string private _tokenBaseURI = "";

    bool public isPaused = true;
    uint256 public maxPerMint = 100;
    uint256 public maxSupply = 10000;
    uint256 public price = 0.1 ether;

    // Payment addresses + Payments basis points (percentage using 2 decimals - 10000 = 100, 0 = 0)
    address private paymentAddress = 0x13D22EFB01E7F7b7FEfea9e74ffd690eE9B7feCE;
    
    // Royalties address
    address private royaltyAddress = 0x13D22EFB01E7F7b7FEfea9e74ffd690eE9B7feCE;

    // Royalties basis points (percentage using 2 decimals - 10000 = 100, 0 = 0)
    uint256 private royaltyBasisPoints = 1000; // 10%

    constructor(string memory _initialBaseURI) ERC721("Crypto Dicks Club", "CDC") {
      _tokenBaseURI = _initialBaseURI;
    }

    function getPrice() public view returns (uint256) {
      return price;
    }

    function mint(uint256 _amount, address _to) public payable {
        require(!isPaused, 'mint: Minting is paused.');
        uint256 totalSupply = totalSupply();
        require(totalSupply + _amount <= maxSupply, "mint: Not enough supply remaining");
        require(_amount <= maxPerMint, "mint: Amount more than max per mint");

        uint256 mintPrice = getPrice();

        uint256 costToMint = mintPrice * _amount;

        require(costToMint <= msg.value, "mint: ETH amount sent is not correct");

        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = _tokenIds.current();
            _mint(_to, tokenId);
            _tokenIds.increment();
        }

        Address.sendValue(payable(paymentAddress), costToMint);

        uint256 remainder = msg.value - costToMint;

        // Return unused value
        if (msg.value > costToMint) {
            Address.sendValue(payable(msg.sender), remainder);
        }
    }

    function ownerMint(uint256 _amount, address _to) external onlyOwner {
        uint256 totalSupply = totalSupply();
        require(totalSupply + _amount <= maxSupply, "mint: Not enough supply remaining");

        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = _tokenIds.current();
            _mint(_to, tokenId);
            _tokenIds.increment();
        }
    }

    // Support royalty info - See {EIP-2981}: https://eips.ethereum.org/EIPS/eip-2981
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            royaltyAddress,
            (_salePrice * royaltyBasisPoints / 10000)
        );
    }

    function setBaseURI(string memory URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), uint2str(tokenId)));
    }

    // Contract metadata URI - Support for OpenSea: https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "contract"));
    }

    function setPaymentAddress(address _address) public onlyOwner {
        paymentAddress = _address;
    }

    function setRoyaltyAddress(address _address) public onlyOwner {
        royaltyAddress = _address;
    }

    function setRoyaltyBasisPoints(uint256 _royaltyBasisPoints) public onlyOwner {
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    function setMaxPerMint(uint256 _maxPerMint) public onlyOwner {
        maxPerMint = _maxPerMint;
    }

    function turnPauseOn() external onlyOwner {
        isPaused = true;
    }

    function turnPauseOff() external onlyOwner {
        isPaused = false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
