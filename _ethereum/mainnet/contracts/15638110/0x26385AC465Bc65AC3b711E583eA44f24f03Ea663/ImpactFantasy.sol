// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract ImpactFantasy is
    ERC721,
    ReentrancyGuard,
    Pausable,
    AccessControl,
    Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public IMPACT_FANTASY_MAX;

    Counters.Counter private _tokenIdCounter;
    
    address public proxyRegistryAddress;

    string public baseURI;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _IMPACT_FANTASY_MAX
    ) ERC721(name, symbol) {
        IMPACT_FANTASY_MAX = _IMPACT_FANTASY_MAX;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function currentSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
    function mintTo(address to) public onlyRole(MINTER_ROLE) {
        require(
            _tokenIdCounter.current()+1 <= IMPACT_FANTASY_MAX,
            "ImpactFantasy: Max supply exceeded"
        );
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(to, tokenId);
    }

    function setBaseURI(string calldata _tokenBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
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
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
