// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721AUpgradeable.sol";
import "./HasRegistration.sol";
import "./ERC721ABurnableUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./IHandlerCallback.sol";
import "./ERC2981Royalties.sol";
import "./OperatorFiltererUpgradeable.sol";

contract EmblemVault721AUpgradeable is ERC721AUpgradeable, ERC721ABurnableUpgradeable, ERC721AQueryableUpgradeable, HasRegistration, OperatorFiltererUpgradeable, ERC2981Royalties {  

    mapping(uint256 => uint256) internal _externalTokenIdMap; // tokenId >> externalTokenId
    bool initialized;
    
    function initialize(string memory name_, string memory symbol_) initializer external {
        if (!initialized) {
            initialized = true;
            ERC721AStorage.layout()._name = name_;
            ERC721AStorage.layout()._symbol = symbol_;
            ERC721AStorage.layout()._currentIndex = _startTokenId();
            _transferOwnership(_msgSender());
            toggleClaimable();
            __OperatorFilterer_init(0x9dC5EE2D52d014f8b81D662FA8f4CA525F27cD6b, true);
            BASE_URI = "https://v2.emblemvault.io/v3/meta";
        }
    }

    function mint(address to, uint256 externalTokenId) external onlyOwner {
        __mint(to, externalTokenId);
    }

    function mintMany(address[] memory to, uint256[] memory externalTokenId) public onlyOwner {
        require(to.length == externalTokenId.length, "Invalid input");
        for (uint i = 0; i < to.length; i++) {
            __mint(to[i], externalTokenId[i]);
        }
    }

    function __mint(address to, uint256 externalTokenId) internal {
        require(_externalTokenIdMap[externalTokenId] == 0, "External ID already minted");
        uint256 _tokenId = ERC721AStorage.layout()._currentIndex;
        _externalTokenIdMap[externalTokenId] = _tokenId;
        _mint(to, 1);        
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] == _msgSender()) { // Called by Handler
            IHandlerCallback(_msgSender()).executeCallbacks(address(0), to, _tokenId, IHandlerCallback.CallbackType.MINT);
        }
    }    

    function burn(uint256 tokenId) public override {      
        require(isApprovedForAll(_ownershipOf(tokenId).addr, _msgSender()) || canBypass(), 'Not Approved to burn');  
        super.burn(tokenId);
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] != address(0)) {
            IHandlerCallback(registeredOfType[3][0]).executeCallbacks(_msgSender(), address(0), tokenId, IHandlerCallback.CallbackType.BURN);
        }
    }

    function setDetails(string memory name_, string memory symbol_) public onlyOwner {
        ERC721AStorage.layout()._name = name_;
        ERC721AStorage.layout()._symbol = symbol_;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        BASE_URI = baseURI;
    }

    // function tokenURI(uint256 tokenId) public view override(ERC721AUpgradeable, IERC721AUpgradeable) onlyOwner returns (string memory)  {
    //     if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);
    //     string memory baseURI = _baseURI();
    //     return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "/", _addressToString(address(this)), "/", _toString(tokenId))) : '';
    // }
    

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 _interfaceId) public view override(ERC721AUpgradeable, IERC721AUpgradeable) returns (bool) {
        return 
        ERC721AUpgradeable.supportsInterface(_interfaceId) || 
        _interfaceId == bytes4(keccak256("ERC721A")) || 
        _interfaceId == 0x2a55205a;
    }

    function getInternalTokenId(uint256 tokenId) external view returns (uint256) {
        return _externalTokenIdMap[tokenId];
    }

    function version() external pure returns (string memory) {
        return "14";
    }

    function interfaceId() external pure returns (bytes4) {
        return bytes4(keccak256("ERC721A"));
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
        
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    function approve(address operator, uint256 tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    // function _addressToString(address _addr) internal pure returns(string memory) {
    //     bytes32 value = bytes32(uint256(uint160(_addr)));
    //     bytes memory alphabet = "0123456789abcdef";

    //     bytes memory str = new bytes(42);
    //     str[0] = '0';
    //     str[1] = 'x';
    //     for (uint256 i = 0; i < 20; i++) {
    //         str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
    //         str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
    //     }
    //     return string(str);
    // }

    uint256[50] private __gap;
    string BASE_URI;
}