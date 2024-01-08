// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

abstract contract CGArms {
  function ownerOf(uint256 tokenId) public virtual view returns (address);
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract CashGrabLegsNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    
    string private _baseTokenURI;

    string public LEG_PROVENANCE = "";

    string private _contractURI;
    
    uint256 public MAX_CASH_GRAB_LEGS = 5608;
    
    uint public constant MAX_CLAIM_AMOUNT = 50;

    bool public claimIsActive = false;
    
    CGArms private cgArms;

    ProxyRegistry private _proxyRegistry;

    constructor(
        address openseaProxyRegistry_
    ) public ERC721("CashGrabLegs", "CGLegs") {
        cgArms = CGArms(0xd448E6CCA10ff5d1cE52Ddc6B6FC4bfCb796d8eb);
        if (address(0) != openseaProxyRegistry_) {
            _setOpenSeaRegistry(openseaProxyRegistry_);
        }
    }
    
    function claimLeg(uint256 _cgArmTokenID) public {
        require(claimIsActive, "Claim is not active");
        require(_cgArmTokenID <= MAX_CASH_GRAB_LEGS, "Arm TokenID exceeds max Leg Supply");
        require(cgArms.ownerOf(_cgArmTokenID) == msg.sender, "You must own the Arm tokenId to mint the Leg");
        
        _safeMint(msg.sender, _cgArmTokenID);
    }
    
    function claimXLegs(uint256[] memory _listOfTokenIds) public nonReentrant {
        require(claimIsActive, "Claim is not active");
        uint256 _amountToClaim = _listOfTokenIds.length;
        require(_amountToClaim > 0, "Must claim at least one leg.");
        require(_amountToClaim <= MAX_CLAIM_AMOUNT, "Cannot claim more than 50 Legs at one time.");
        require((totalSupply() + _amountToClaim) <= MAX_CASH_GRAB_LEGS, "Mint would exceed max supply of Cash Grabs Legs");
        uint256 _balance = cgArms.balanceOf(msg.sender);
        
        for(uint256 i = 0; i < _balance && i < _amountToClaim; i++) {
            uint256 _tokenId = _listOfTokenIds[i];
            require(cgArms.ownerOf(_tokenId) == msg.sender, "You must own the Arm tokenId to mint the leg");
            if (!_exists(_tokenId)) {
                _safeMint(msg.sender, _tokenId);
            }
        }
    }
    
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        LEG_PROVENANCE = provenanceHash;
    }
    
    function setBaseURI(string calldata newBaseTokenURI) public onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    function isClaimed(uint256 _cgArmTokenID) public view returns (bool) {
        return _exists(_cgArmTokenID);
    } 
    
    function isClaimedBulk(uint256[] memory _listOfTokenIds) public view returns (bool[] memory) {
        bool[] memory isClaimedArray = new bool[](_listOfTokenIds.length);
        for(uint256 i = 0; i < _listOfTokenIds.length; i++) {
            isClaimedArray[i] = isClaimed(_listOfTokenIds[i]);
        }
        return isClaimedArray;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function changeClaimState() public onlyOwner {
        claimIsActive = !claimIsActive;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Returns the contract URI function. Used on OpenSea to get details
    //          about a contract (owner, royalties etc...)
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Helper for OpenSea gas-less trading
    /// @dev Allows to check if `operator` is owner's OpenSea proxy
    /// @param owner the owner we check for
    /// @param operator the operator (proxy) we check for
    function isOwnersOpenSeaProxy(address owner, address operator) public view returns (bool) {
        ProxyRegistry proxyRegistry = _proxyRegistry;
        return
            // we have a proxy registry address
            address(proxyRegistry) != address(0) &&
            // current operator is owner's proxy address
            address(proxyRegistry.proxies(owner)) == operator;
    }

    /// @dev Internal function to set the _contractURI
    /// @param contractURI_ the new contract uri
    function _setContractURI(string memory contractURI_) internal {
        _contractURI = contractURI_;
    }

    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }

    /// @notice Allows gas-less trading on OpenSea by safelisting the Proxy of the user
    /// @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
    /// @inheritdoc	ERC721
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        // allows gas less trading on OpenSea
        if (isOwnersOpenSeaProxy(owner, operator)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function setOpenSeaRegistry(address proxyRegistryAddress) external onlyOwner {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }

    /// @notice Helper for the owner of the contract to set the new contract URI
    /// @dev needs to be owner
    /// @param contractURI_ new contract URI
    function setContractURI(string memory contractURI_) external onlyOwner {
        _setContractURI(contractURI_);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}