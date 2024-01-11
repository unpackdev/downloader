// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC2981.sol";
import "./Address.sol";
import "./ERC721A.sol"; 

/// @custom:security-contact tech@btang.cn
contract LuluLandADs is ERC721A, IERC2981, ReentrancyGuard, Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(string memory baseURI_, address defaultAdmin_) ERC721A("LuluLandADs", "LLAD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin_);
        _grantRole(MINTER_ROLE, defaultAdmin_);

        customBaseURI = baseURI_;
    }

    /** PAUSE **/

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    /** MINTING **/

    uint256 public constant MAX_SUPPLY = 10000;

    function mint(uint256 quantity)
        public
        callerIsUser
        nonReentrant
        onlyRole(MINTER_ROLE)
    {
        require(totalSupply() + quantity < MAX_SUPPLY, "Exceeds max supply");

        _safeMint(msg.sender, quantity);
    }

    function numberMinted(address owner)
        public
        view
        returns (uint256)
    {
        return _numberMinted(owner);
    }

    function totalMinted() 
        public
        view
        returns (uint256)
    {
        return _totalMinted();
    }

    function exists(uint256 tokenId)
        public
        view
        returns (bool)
    {
        return _exists(tokenId);
    }

    /** URI HANDLING **/

    string private customContractURI =
        "ipfs://bafkreifpybn4w2eufcpgbdossjxwijn5ahut7tavdn65jkmcg5idzmi6fq";

    function setContractURI(string memory customContractURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        customContractURI = customContractURI_;
    }

    function contractURI()
        public
        view
        returns (string memory)
    {
        return customContractURI;
    }

    string private customBaseURI;

    function setBaseURI(string memory customBaseURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        customBaseURI = customBaseURI_;
    }

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return customBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".token.json"));
    }

    /** PAYOUT **/

    address private constant payoutAddress1 =
        0x80bc3Fc6101f9BbBA8689d76E44B6eA12dFEE427;

    function withdraw() public nonReentrant {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(payoutAddress1), balance);
    }

    /** ROYALTIES **/

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * 1000) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165, AccessControl)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(AccessControl).interfaceId || 
            super.supportsInterface(interfaceId)
        );
    }

    /** --- Modifier --- **/

    /**
     * @notice for security reasons, CA is not allowed to call sensitive methods.
     */
    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "caller is another contract");
        _;
    }
}