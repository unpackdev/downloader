// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./AccessControlUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./CountersUpgradeable.sol";

/**
 * @title AERC721
 *
 */

contract AERC721 is AccessControlUpgradeable, ERC721BurnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    event Mint(address indexed _to, uint256 indexed _tokenId);
    event ToggleMintpause(bool _mPaused);
    event ToggleTransferpause(bool _tPaused);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

    CountersUpgradeable.Counter private _tokenIdCounter;

    uint256 private _maxSupply;
    string private _baseTokenURI;
    bool private _tPaused;
    bool private _mPaused;

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        string memory baseTokenURI_,
        address controlleraddress_
    ) external initializer {
        __ERC721_init(name_, symbol_);
        __AccessControl_init();
        __ERC721Burnable_init();
        __AERC721_init(maxSupply_, baseTokenURI_, controlleraddress_);

        _tokenIdCounter.increment();
        _mint(tx.origin, 1);
    }

    function __AERC721_init(
        uint256 maxSupply_,
        string memory baseTokenURI_,
        address controlleraddress_
    ) internal onlyInitializing {
        __AERC721_init_unchained(maxSupply_, baseTokenURI_, controlleraddress_);
    }

    function __AERC721_init_unchained(
        uint256 maxSupply_,
        string memory baseTokenURI_,
        address controlleraddress_
    ) internal onlyInitializing {
        _maxSupply = maxSupply_;
        _baseTokenURI = baseTokenURI_;
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(MINTER_ROLE, controlleraddress_);
        _setupRole(MAINTAINER_ROLE, tx.origin);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) {
        require(!_tPaused, "token transfer while paused");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function toggleMintpause() external virtual {
        require(
            hasRole(MAINTAINER_ROLE, _msgSender()),
            "must have maintainer role to pause mint"
        );
        _mPaused = !_mPaused;
        emit ToggleMintpause(_mPaused);
    }

    function toggleTransferpause() external virtual {
        require(
            hasRole(MAINTAINER_ROLE, _msgSender()),
            "must have maintainer role to pause transfer"
        );
        _tPaused = !_tPaused;
        emit ToggleTransferpause(_tPaused);
    }

    function mint(address to, uint256 tokenId) external returns (uint256) {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "must have minter role to mint"
        );

        require(!_mPaused, "token mint while paused");

        require(
            _tokenIdCounter.current() < _maxSupply,
            "token maxSupply reached"
        );

        require(tokenId > 0 && tokenId <= _maxSupply, "tokenId unavailable");

        _tokenIdCounter.increment();

        _mint(to, tokenId);

        emit Mint(to, tokenId);
        return tokenId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseURI();
    }

    function tPaused() public view returns (bool) {
        return _tPaused;
    }

    function mPaused() public view returns (bool) {
        return _mPaused;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    // /**
    //  * @dev Link to Contract metadata https://docs.opensea.io/docs/contract-level-metadata
    //  */
    function contractURI() public view returns (string memory) {
        return
            bytes(_baseTokenURI).length > 0
                ? string(abi.encodePacked(_baseTokenURI, "metadata"))
                : "";
    }
}
