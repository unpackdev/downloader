//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";

contract InsideWorldNFT is
    Initializable, ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721PausableUpgradeable
{
    address private treasury;

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) public virtual initializer {
        treasury = 0xd76eF9516Fa937C062DD7a08a5fAf73e12e05f07;

        __ERC721PresetMinterPauserAutoId_init(name, symbol, baseTokenURI);
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    string private _baseTokenURI;

    function __ERC721PresetMinterPauserAutoId_init(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __ERC721Enumerable_init_unchained();
        __ERC721Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();
        __ERC721PresetMinterPauserAutoId_init_unchained(name, symbol, baseTokenURI);
    }

    function __ERC721PresetMinterPauserAutoId_init_unchained(
        string memory,
        string memory,
        string memory baseTokenURI
    ) internal onlyInitializing {
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(address to, uint256 tokenId) public virtual payable {
        require(msg.value == 0.1 ether, "InsideWorldNFT: Minting incurs a 0.1 ETH fee");
        require(tokenId > 0 && tokenId < 4001, "InsideWorldNFT: Invalid token id provided");

        payable(treasury).transfer(msg.value);

        _mint(to, tokenId);
    }

    function bulkMint(address to, uint256[] memory tokenIds) external payable {
        require(tokenIds.length < 50, "InsideWorldNFT: Maximum of 50 mints allowed in bulk");
        require(msg.value == 0.1 ether * tokenIds.length, "InsideWorldNFT: Minting incurs a 0.1 ETH fee per token");

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(tokenId > 0 && tokenId < 4001, "InsideWorldNFT: Invalid token id provided");
            _mint(to, tokenId);
        }

        payable(treasury).transfer(msg.value);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "InsideWorldNFT: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "InsideWorldNFT: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}