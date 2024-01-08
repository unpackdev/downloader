// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Tradable.sol";

contract Grailer is ERC721Tradable {
    bool public saleIsActive;
    uint256 public maxByMint;
    uint256 public maxSupply;
    uint256 public maxPublicSupply;
    uint256 public maxReservedSupply;
    uint256 public totalPublicSupply;
    uint256 public totalReservedSupply;
    uint256 public fixedPrice;
    address public daoAddress;
    string internal baseTokenURI;
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        maxByMint = 10;
        maxSupply = 999;
        maxReservedSupply = 30;
        fixedPrice = 0.6 ether;
        maxPublicSupply = maxSupply - maxReservedSupply;
        daoAddress = 0x63fE60e3373De8480eBe56Db5B153baB1A431E38;
        baseTokenURI = 'https://www.grailers.io/api/meta/1/';
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.grailers.io/api/contract/1";
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function mintPublic(uint numberOfTokens) external payable {
        require(saleIsActive, "Sale not active");
        require(numberOfTokens <= maxByMint, "Max mint exceeded");
        require(totalPublicSupply + numberOfTokens <= maxPublicSupply, "Max supply reached");
        require(fixedPrice * numberOfTokens <= msg.value, "Eth val incorrect");
        for(uint i = 0; i < numberOfTokens; i++) {
            _mint(msg.sender, totalPublicSupply + 1);
            totalPublicSupply++;
        }
    }

    function mintReserved(address _to) external onlyOwner {
        _mint(_to, maxPublicSupply + totalReservedSupply + 1);
        totalReservedSupply++;
    }

    function flipSaleStatus() external onlyOwner {
        saleIsActive = !saleIsActive;
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

}