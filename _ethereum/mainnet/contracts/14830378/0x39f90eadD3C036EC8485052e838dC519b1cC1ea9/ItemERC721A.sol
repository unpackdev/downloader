//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./AccessControl.sol";

import "./ERC721A.sol";

contract ItemERC721A is ERC721A, Ownable, AccessControl {
    using Strings for uint256;

    string private baseURI;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public activeEdition;

    // ============ MODIFIERS ============

    modifier onlyOwnerOrManager() {
        require( hasRole(MINTER_ROLE, _msgSender()) || owner() == _msgSender(), "Only Owner/Minter allowed");
        _;
    }

    modifier onlyActiveEdition(uint256 _edition){
        require(activeEdition == _edition, "Only active edition allowed to mint");
        _;
    }

    // ========== CONSTRUCTOR =================

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _minter
    ) ERC721A(_name, _symbol) {
        // maxSupply = _maxSupply;
        baseURI = _uri;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, _minter);
    }

    function setBaseURI(string memory _uri) external onlyOwnerOrManager {
        baseURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function safeMintMany(address recipient, uint256 amount, uint256 _activeEdition) 
        external  
        onlyOwnerOrManager 
        onlyActiveEdition(_activeEdition) {
        _safeMint(recipient, amount);
    }

    function airdrop(address[] calldata addresses, uint256 _activeEdition)
        external
        onlyOwnerOrManager
        onlyActiveEdition(_activeEdition)
    {
        uint256 numToGift = addresses.length;

        for (uint256 i = 0; i < numToGift; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function setActiveEdition(uint256 _activeEdition) public onlyOwnerOrManager {
        activeEdition = _activeEdition;
    }

    // ============ FUNCTION OVERRIDES ============

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
