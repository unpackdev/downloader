// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Pausable.sol";

import "./AccessControl.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

import "./SafeERC20.sol";

import "./ERC4907.sol";


// NFT pass基础
/// @custom:security-contact developer@loopop.io
contract LoopopTokenBase is ERC4907, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl, ERC721Burnable, ReentrancyGuard {
    
    using SafeERC20 for IERC20;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant URI_ROLE = keccak256("URI_ROLE");
    bytes32 public constant USE_ROLE = keccak256("USE_ROLE");

    address public validator;

    address public cfo;

    mapping(uint32 => bool) internal _isNonceUsed;


    constructor(string memory name_, string memory symbol_) ERC4907(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        cfo = 0xFbCe08DE4b6aF692CE55C3cdc513250ED348C48B;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        virtual
        override(ERC4907, ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC4907, ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function checkPublicMintValidator(address mintToAddress, uint256 price, uint32 nonce, string memory uri, bytes memory validatorSig) public view {
        bytes32 validatorHash = keccak256(abi.encodePacked(mintToAddress, price, nonce, uri));
        checkSign(validatorSig, ECDSA.toEthSignedMessageHash(validatorHash), validator, "invalid validator sign!");
    }

    function checkSign(bytes memory sign, bytes32 hashCode, address signer, string memory words) public pure {
        require(ECDSA.recover(hashCode, sign) == signer, words);
    }

    function setValidator(address newValidator) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        require(newValidator != address(0) && validator != newValidator, "invalid newValidator address!");
        validator = newValidator;
    }

    function setCfo(address newCfo) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        require(newCfo != address(0) && cfo != newCfo, "invalid newCfo address!");
        cfo = newCfo;
    }

    function setTokenURI(uint256 tokenId, string memory newuri) public onlyRole(URI_ROLE) {
        _setTokenURI(tokenId, newuri);
    }

    /**
        In case money get Stuck in the contract
    */
    function withdraw(address payable to, uint256 amount) external onlyRole(WITHDRAW_ROLE) {
        to.transfer(amount);
    }

    function withdrawERC20(address erc20Address, address to, uint256 amount) external onlyRole(WITHDRAW_ROLE) {
        IERC20(erc20Address).safeTransfer(to, amount);
    }

}
