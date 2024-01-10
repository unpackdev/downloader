// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./Ownable.sol";


contract UkrNoWar is ERC721("UkrNoWar", "UNW"), ERC721Enumerable, Ownable {
    using Strings for uint256;
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    string private baseURI;
    uint256 public mintLimit = 15;
    uint256 private constant TOTAL_NFT = 10000;
    uint256 public mintPrice = 0.3 ether;
    bool public mintActive;
    uint256 public partnerMintAmount = 100;
    mapping(address => uint256) public partnerMintAvailableBy;

    constructor() {
        partnerMintAvailableBy[msg.sender] = 100;
    }

    function setMintActive(bool _isActive) external onlyOwner {
        mintActive = _isActive;
    }

    function setURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 amount1 = balance * 20 / 100;
        uint256 amount2 = balance - amount1;
        payable(0x10E1439455BD2624878b243819E31CfEE9eb721C).transfer(amount1); //unchain.fund
        payable(0xfa8dCB922Dcbecf1712f23439A84d4CC1A8fAc64).transfer(amount2);
    }

    function updateMintLimit(uint256 _newLimit) public onlyOwner {
        mintLimit = _newLimit;
    }

    function updateMintPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    function addPartnerMint(address account, uint256 amount) public onlyOwner {
        partnerMintAmount += amount;
        require(totalSupply() + partnerMintAmount <= TOTAL_NFT, "Can't add partner more than available");
        partnerMintAvailableBy[account] += amount;
    }

    function decreasePartnerMint(address account, uint256 amount) public onlyOwner {
        require(partnerMintAmount >= amount, "Too big amount");
        require(partnerMintAvailableBy[account] >= amount, "Too big amount for partner");

        partnerMintAmount -= amount;
        partnerMintAvailableBy[account] -= amount;
    }

    function mintNFT(uint256 _numOfTokens) public payable {
        require(mintActive, 'Not active');
        require(_numOfTokens <= mintLimit, "Can't mint more than limit per tx");
        require(mintPrice * _numOfTokens <= msg.value, "Insufficient payable value");
        require(totalSupply() + _numOfTokens <= TOTAL_NFT, "Can't mint more than total");
        require(msg.sender == tx.origin);

        for(uint i = 0; i < _numOfTokens; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function partnersMintMultiple(address[] memory _to) public {
        uint256 amount = _to.length;
        require(totalSupply() + amount <= TOTAL_NFT, "Can't mint more than total");
        require(partnerMintAmount >= amount, "Can't mint more than total available for partners");
        require(partnerMintAvailableBy[msg.sender] >= amount, "Can't mint more than available for msg.sender");
        for(uint256 i = 0; i < amount; i++){
            _safeMint(_to[i],totalSupply() + 1);
        }
        partnerMintAmount -= amount;
        partnerMintAvailableBy[msg.sender] -= amount;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
            return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function supportsInterface(bytes4 _interfaceId) public view override (ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function isApprovedForAll(address owner, address operator) override public view returns(bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistryAddress == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

}