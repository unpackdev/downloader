//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721RoyaltyUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";
import "./Initializable.sol";

// @title: Wally Character_V1 Smart contract
// @notice: ERC721 NFT Smart Contract for Symbiogenesis project's Character
// @dev: This contract inherited ERC721,ERC721Enumerable, ERC721URIStorage, Pausable, AccessControlEnumerable, ERC721Burnable, ERC721Royalty, Ownable and DefaultOperatorFilterer Smart contracts from openzepplin
contract CHARACTER_V1_UPGRADEABLE is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, AccessControlEnumerableUpgradeable, ERC721BurnableUpgradeable, ERC721RoyaltyUpgradeable, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable {
    // As byte32 type public constants , stores hash for string value that display various kinds of roles
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ROYALTY_ROLE = keccak256("ROYALTY_ROLE");
    // Private mapping that stores status variable as bool type that display whether token is burned or not
    mapping(uint256 => bool) private burnedTokens;
    //@notice: This construcor function is executed when contract is deployed
    //@param: token name and token symbol
    //@dev:assign all kinds of roles to deployer's address
    function initialize(
        string memory _name,
        string memory _symbol
    ) external initializer {
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __ERC721Royalty_init();
        __Pausable_init();
        __Ownable_init();
        __AccessControlEnumerable_init();
        __DefaultOperatorFilterer_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(ROYALTY_ROLE, msg.sender);
    }

    ////////////////////
    //@notice: This is a function that mint token
    //@param: token id, address that token is minted to, token uri
    //@dev: Only address that has minter role can execute this function. It requires that token id to be minter is not burned. Call safeMint function. Set token uri
    function mint(uint256 tokenId, address to, string memory uri) public onlyRole(MINTER_ROLE)
    {
        require(isBurnedToken(tokenId) == false, "Token is burned");
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    //@notice: This function triggers stoped state of the contract
    //@dev: Only msg.sender that has PAUSER_ROLE can call this function. Call _pause() in the Pausable contract
    function pause() public onlyRole(PAUSER_ROLE)
    {
        _pause();
    }

    //@notice: This function triggers unstoped state of the contract
    //@dev: Only msg.sender that has PAUSER_ROLE can call this function. Call _unpause() in the Pausable contract
    function unpause() public onlyRole(PAUSER_ROLE)
    {
        _unpause();
    }

    ////////////////////

    //@notice: This is a public function that set defaukt royalty.
    //@param: receiver address that represents the address that royalty will be transferred, feeNumerator that represents the numerator of the fee percentage charged when a token is transferred.
    //@dev: Only msg.sender that has ROYALTY_ROLE can call this function. Call _setDefaultRoyalty in the ERC721Royalty contract
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(ROYALTY_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    //@notice: This is a function that delete default royalty
    //@dev: Only msg.sender that has ROYALTY_ROLE can call this function. Call _deleteDefaultRoyalty in the ERC721Royalty contract
    function deleteDefaultRoyalty() external onlyRole(ROYALTY_ROLE)
    {
        _deleteDefaultRoyalty();
    }

    //@notice: This is a function that sets the royalty information for a specific token id.
    //@param: token id, receiver address, feeNumerator
    //@dev: Only msg.sender that has ROYALTY_ROLE can call this function. Call  _setTokenRoyalty in the ERC721Royalty contract
    function setTokenRoyalty(uint256 tokenId ,address receiver, uint96 feeNumerator) public onlyRole(ROYALTY_ROLE)
    {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    //@notice: This is a function that resets the royalty information for a specific token id.
    //@param: token id
    //@dev: Only msg.sender that has ROYALTY_ROLE can call this function. Call  _resetTokenRoyalty in the ERC721Royalty contract
    function resetTokenRoyalty(uint256 tokenId) public onlyRole(ROYALTY_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    ////////////////////
    // The following functions are overrides from inherited contract
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable)
    {
        super._burn(tokenId);
        burnedTokens[tokenId] = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerableUpgradeable, ERC721EnumerableUpgradeable, ERC721RoyaltyUpgradeable, ERC721URIStorageUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual whenNotPaused onlyAllowedOperator(from) override(ERC721Upgradeable, IERC721Upgradeable) {
        super.transferFrom(from, to, tokenId);
        if (to == address(0)) {
            burnedTokens[tokenId] = true;
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual whenNotPaused onlyAllowedOperator(from) override(ERC721Upgradeable, IERC721Upgradeable) {
        super.safeTransferFrom(from, to, tokenId);
        if (to == address(0)) {
            burnedTokens[tokenId] = true;
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        virtual whenNotPaused onlyAllowedOperator(from)
        override(ERC721Upgradeable, IERC721Upgradeable)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //@notice: This is a function that represents if current token is burned or not.
    //@param: token id.
    //@return: return bool type state variable that is stored in the burnedTokens mapping.
    function isBurnedToken(uint256 tokenId) public view returns (bool) {
        return burnedTokens[tokenId];
    }
    //@notice: This is a function that represents if current token id exists.
    //@param: token id
    //@return: return _exists function that return state variable that indicate the existance of token id.
    function exists(uint _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }
}