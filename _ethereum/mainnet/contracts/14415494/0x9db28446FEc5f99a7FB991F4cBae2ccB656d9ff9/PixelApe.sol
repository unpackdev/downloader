// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Tradable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

contract IApe {
    function balanceOf(address _address) public view returns(uint256){}
}

contract PixelApe is ERC721Tradable {
    bool public salePublicIsActive;
    uint256 public maxPublicSupply;
    address public daoAddress;
    string internal baseTokenURI;
    mapping(address => uint256) public pixelApesClaimed;
    using Counters for Counters.Counter;
    Counters.Counter public totalPublicSupply;
    IApe public Ape;
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        salePublicIsActive = true;
        maxPublicSupply = 3333;
        daoAddress = 0x050F30bd067ac136B471Ed7CB7e7BE05cA11d779;
        baseTokenURI = "https://radioactiveapes.io/api/meta/2/";
        Ape = IApe(0x5A817E0dB5712ABabD75C6037Bf5C83D87c79d19);
    }

    function contractURI() public pure returns (string memory) {
        return "https://radioactiveapes.io/api/contract/2";
    }

    function mint(uint256 numberOfTokens) public payable {
        require(salePublicIsActive, "Sale not active");
        require(canClaim(_msgSender()) && numberOfTokens <= Ape.balanceOf(_msgSender()) , "Cannot claim");
        require(totalPublicSupply.current() + numberOfTokens <= maxPublicSupply, "Max supply reached");
        _mintN(_msgSender(), numberOfTokens);
        pixelApesClaimed[_msgSender()] = numberOfTokens;
    }

    function _mintN(address _to, uint256 numberOfTokens) private {
        for (uint256 i=0; i<numberOfTokens; i++) {
            totalPublicSupply.increment();
            _safeMint(_to, totalPublicSupply.current());
        }
    }

    function canClaim(address _address) public view returns(bool) {
        return pixelApesClaimed[_address] == 0;
    }
    
    function mintReserved(address _to, uint256 numberOfTokens) external onlyOwner {
        _mintN(_to, numberOfTokens);
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function flipSalePublicStatus() external onlyOwner {
        salePublicIsActive = !salePublicIsActive;
    }

    function setDaoAddress(address _daoAddress) external onlyOwner {
        daoAddress = _daoAddress;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0);
        _withdraw(daoAddress, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Tx failed");
    }

    function setApe(address _address) external onlyOwner {
        Ape = IApe(_address);
    }

}