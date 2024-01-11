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
import "./ProxyRegistry.sol";

contract ERC721Core is ERC721, ContextMixin, NativeMetaTransaction, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _kazuWack;
    string private _saishoURL;
    string private _uchiroURL;
  
    constructor(string memory name, string memory symbol, string memory tokenURIPrefix, string memory tokenURISuffix) ERC721(name, symbol) {
        _saishoURL = tokenURIPrefix;
        _uchiroURL = tokenURISuffix;
    }

    function comeOnWack(uint256 tokenId) public nonReentrant {
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
        address registry;
        uint256 chainId;

        assembly {
            chainId := chainid()
            switch chainId
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 137 {
                // polygon
                registry := 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE
            }
            case 4 {
                // rinkeby
                // https://github.com/ProjectOpenSea/opensea-creatures/blob/master/migrations/2_deploy_contracts.js#L29
                registry := 0x1E525EEAF261cA41b809884CBDE9DD9E1619573A
            }
            case 80001 {
                // mumbai
                registry := 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
            }
            case 1337 {
                registry := 0xE1a2bbc877b29ADBC56D2659DBcb0ae14ee62071
            }
        }

        if (registry == address(0)) {
            return super.isApprovedForAll(owner, operator);
        } else if (chainId == 1 || chainId == 4 || chainId == 1337) {
            return address(ProxyRegistry(registry).proxies(owner)) == operator;
        }
        return registry == operator;
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
}
