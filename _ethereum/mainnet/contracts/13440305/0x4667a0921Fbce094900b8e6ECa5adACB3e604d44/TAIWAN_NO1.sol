// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Counters.sol";

contract TAIWAN_NO1 is
    Context,
    AccessControlEnumerable,
    ERC721Burnable,
    ERC721Enumerable,
    ERC721Pausable
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    string internal _baseTokenURI;

    mapping(uint256 => string) public tokenHashMapping;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(address to, string calldata hash) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "TAIWAN_NO1: must have minter role to mint"
        );

        uint256 tokenId = _tokenIdTracker.current();
        tokenHashMapping[tokenId] = hash;

        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "TAIWAN_NO1: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "TAIWAN_NO1: must have pauser role to unpause"
        );
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "TAIWAN_NO1: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        string memory tokenHash = tokenHashMapping[tokenId];
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenHash))
                : "";
    }

    function setBaseTokenURI(string memory baseTokenURI) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "TAIWAN_NO1: Only MINTER_ROLE can modify baseTokenURI");
        _baseTokenURI = baseTokenURI;
    }

    function setTokenHash(uint256 tokenId, string calldata hash) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "TAIWAN_NO1: Only MINTER_ROLE can modify token hash mapping");
        tokenHashMapping[tokenId] = hash;
    }
}
