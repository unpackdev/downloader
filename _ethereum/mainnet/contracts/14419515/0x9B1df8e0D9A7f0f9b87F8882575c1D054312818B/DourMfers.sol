// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract DourMfers is Ownable, ERC721A {
    uint256 public constant collectionSize = 6969;
    uint256 public constant totalFree = 496;
    uint256 public constant mintLimit = 20;
    uint256 public constant freeLimit = 5;
    uint256 public constant price = .0055 ether;
    
    string private baseURI;
    uint256 public startTime;
    address public immutable proxyRegistryAddress;
 
    constructor(
        uint256 _startTime, 
        address _proxyRegistryAddress, 
        string memory _baseTokenURI
    ) 
        ERC721A('DourMfers', 'DourMfers') 
    {
        startTime = _startTime;
        proxyRegistryAddress = _proxyRegistryAddress;
        baseURI = _baseTokenURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract');
        _;
    }

    function mint(uint256 quantity) external payable callerIsUser {
        require(isActive(), 'public sale has not started yet');
        require(quantity > 0 && quantity <= mintLimit, 'cannot mint 0 or mint more than 20 in one txn');
        require(totalSupply() + quantity <= collectionSize, 'reached max supply');
        
        uint256 totalCost = price * quantity;
        if (isFreeRemaining()) {
            if (quantity > freeLimit) quantity = 5;
            totalCost = 0;
        }

        require(msg.value >= totalCost, 'need to send more ETH.');
        _safeMint(msg.sender, quantity);
        refundIfOver(totalCost);
    }

    function refundIfOver(uint256 totalCost) private {
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= 5, 'too many minted before dev mint');
        _safeMint(msg.sender, quantity);
    }

    function isActive() public view returns (bool) {
        return startTime != 0 && block.timestamp >= startTime;
    }

    function setStartTime(uint256 _startTime) external {
        startTime = _startTime;
    } 

    function isFreeRemaining() public view returns (bool) {
        return totalSupply() <= totalFree;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Transfer failed.');
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator) return true;
        return super.isApprovedForAll(_owner, operator);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
