// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./console.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Counters.sol";
import "./Initializable.sol";

contract ProxyERC721 is Initializable, ERC721Upgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, ERC721PausableUpgradeable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private baseTokenURI;

    function initialize(address _owner, string calldata _name, string calldata _symbol, string calldata _baseuri) public initializer {
        __Ownable_init_unchained();
        transferOwnership(_owner);
        __ERC721_init_unchained(_name, _symbol);
        baseTokenURI = _baseuri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory __baseURI) external onlyOwner() {
        baseTokenURI = __baseURI;
    }

    function mint(address to_) external onlyOwner() {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(to_, newItemId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function pause() public virtual onlyOwner() {
        _pause();
    }

    function unpause() public virtual onlyOwner() {
        _unpause();
    }
}
