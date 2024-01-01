// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./INFTRegistry.sol";
import "./INFTOperator.sol";
import "./INFT.sol";

contract NFT is
    INFT,
    Initializable,
    OwnableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC2981Upgradeable
{
    bytes32 public constant VERSION = "1.0.0";

    INFTRegistry public registry;
    bool public registryDisabled;
    INFTOperator public operator;

    event RegistrySet(INFTRegistry indexed registry);
    event RegistryDisabled(bool indexed registryDisabled);
    event OperatorSet(INFTOperator indexed operator);
    event DefaultRoyaltySet(address indexed receiver, uint96 feeNumerator);
    event TokenRoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        INFTRegistry registry_,
        INFTOperator operator_
    ) external initializer {
        ERC721Upgradeable.__ERC721_init(name_, symbol_);
        OwnableUpgradeable.__Ownable_init();
        ERC721URIStorageUpgradeable.__ERC721URIStorage_init();
        ERC721EnumerableUpgradeable.__ERC721Enumerable_init();
        ERC721BurnableUpgradeable.__ERC721Burnable_init();
        ERC2981Upgradeable.__ERC2981_init();

        registry = registry_;
        operator = operator_;
    }

    function setRegistry(INFTRegistry registry_) external onlyOwner {
        registry = registry_;
        emit RegistrySet(registry_);
    }

    function setRegistryDisabled(bool registryDisabled_) external onlyOwner {
        registryDisabled = registryDisabled_;
        emit RegistryDisabled(registryDisabled_);
    }

    function setOperator(INFTOperator operator_) external onlyOwner {
        operator = operator_;
        emit OperatorSet(operator_);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit DefaultRoyaltySet(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
        emit TokenRoyaltySet(tokenId, receiver, feeNumerator);
    }

    function mint(uint256 tokenId, address receiver, string calldata tokenURI_) external onlyOwner {
        _safeMint(receiver, tokenId);
        _setTokenURI(tokenId, tokenURI_);
    }

    function burn(uint256 tokenId) public override(INFT, ERC721BurnableUpgradeable) {
        super.burn(tokenId);
    }

    function transferOwnership(address newOwner) public override(INFT, OwnableUpgradeable) onlyOwner {
        super.transferOwnership(newOwner);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function isApprovedForAll(
        address owner,
        address operator_
    ) public view override(IERC721Upgradeable, ERC721Upgradeable) returns (bool) {
        return (operator_ != address(0) && address(operator) == operator_) || super.isApprovedForAll(owner, operator_);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        if (!_isValidAgainstRegistry(msg.sender)) {
            revert INFTRegistry.TransferNotAllowed(from, to, tokenId);
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _isValidAgainstRegistry(address operator_) internal view returns (bool) {
        return registryDisabled || registry.isAllowedOperator(operator_);
    }
}
