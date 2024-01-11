// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ContextMixin.sol";
import "./NativeMetaTransaction.sol";
import "./ApproveDelegator.sol";

contract ERC721Core is ERC721, ContextMixin, NativeMetaTransaction, Ownable, ReentrancyGuard, ApproveDelegator {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _kazuWack;
    string private _saishoURL;
    string private _uchiroURL;
  
    constructor(string memory name, string memory symbol, string memory tokenURIPrefix, string memory tokenURISuffix) ERC721(name, symbol) {
        _saishoURL = tokenURIPrefix;
        _uchiroURL = tokenURISuffix;
        _initializeEIP712(name);
        _initializeApproveDelegator();
    }

    function movingWack(address oldHome) external onlyOwner {
        ERC721 erc721 = ERC721(oldHome);
        for (uint256 tokenId = 1; tokenId <= 15; ++tokenId) {
            try erc721.ownerOf(tokenId) returns (address tokenOwner) {
                _safeMint(tokenOwner, tokenId);
                _kazuWack.increment();
            } catch { // solhint-disable no-empty-blocks
                // wack is freedom.
            }
        }
    }

    function comeOnWack(uint256 tokenId) external nonReentrant {
        require(0 < tokenId && tokenId <= 15, "Invalid Token ID.");
        _safeMint(msg.sender, tokenId);
        _kazuWack.increment();
    }

    function totalSupply() external view returns (uint256) {
        return _kazuWack.current();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "not exist token");
        return string(
            abi.encodePacked(
                _saishoURL,
                tokenId.toString(),
                _uchiroURL
            )
        );
    }

    function setBaseTokenURI(string memory tokenURIPrefix, string memory tokenURISuffix) external onlyOwner {
        _saishoURL = tokenURIPrefix;
        _uchiroURL = tokenURISuffix;
    }

    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
        if (_isApprovedForAllByDelegator(owner, operator) == true) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function existsAll() external view returns (bool[15] memory flags) {
        for (uint256 i = 0; i < flags.length; i++) {
            flags[i] = _exists(i + 1);
        }
        return flags;
    }

    function setApproveDelegator(address proxyRegistryAddress, address allOperatorAddress) external onlyOwner {
        _setApproveDelegator(proxyRegistryAddress, allOperatorAddress);
    }
}
