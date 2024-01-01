// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./StringsUpgradeable.sol";

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BetterHooksUpgradeable.sol";

contract ERC721Base is Initializable, OwnableUpgradeable, AccessControlEnumerableUpgradeable, ERC721BetterHooksUpgradeable, ERC721EnumerableUpgradeable {

    using StringsUpgradeable for uint160;
    using StringsUpgradeable for uint256;

    bytes32 public constant DEPLOYER_ROLE = keccak256('DEPLOYER_ROLE');

    string public domain;

    function __ERC721Base_init(string calldata name, string calldata shortName, string calldata _domain, address admin) public initializer {
        __ERC721_init(name, shortName);
        __Ownable_init();
        __ERC721Base_init_unchained(_domain, admin);
    }

    function __ERC721Base_init_unchained(string calldata _domain, address admin) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DEPLOYER_ROLE, msg.sender);
        domain = _domain;
    }

    function setDomain(string calldata _domain) external onlyRole(DEFAULT_ADMIN_ROLE) {
        domain = _domain;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), "/metadata"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControlEnumerableUpgradeable, ERC721EnumerableUpgradeable, ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return string(abi.encodePacked(domain, "/contract/", uint160(address(this)).toHexString(), "/token/"));
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override (ERC721BetterHooksUpgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[10] private __gap;

}
