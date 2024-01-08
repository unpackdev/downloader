//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC20.sol";

/// @title Diamonds of the Realm for Loot holders
/// @custom:unaudited This contract has not been audited. Use at your own risk.
contract DiamondsOfTheRealm is Context, Ownable, ERC20, ReentrancyGuard {
    // Loot contract is available at https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7
    IERC721Enumerable public lootContract;

    uint256 public diamondOfTheRealmPerTokenId = 100 * (10**decimals());
    uint256 public tokenIdStart = 1;
    uint256 public tokenIdEnd = 10000;
    mapping(uint256 => bool) private _allowances;
    bool private _ownerClaim;

    constructor() Ownable() ERC20("Diamonds of the Realm", "DOTR") {
        lootContract = IERC721Enumerable(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7);
        _ownerClaim = false;
    }

    function claimForLootId(uint256 lootTokenId) nonReentrant external {
        require(
            _msgSender() == lootContract.ownerOf(lootTokenId),
            "MUST_OWN_TOKEN_ID"
        );
        _claim(lootTokenId, _msgSender());
    }

    function claimForId(uint256 tokenId) nonReentrant external {
        require(tokenId > 8000 && tokenId <= 10000, "INVALID_TOKEN_ID");
        require(!_allowances[tokenId], "TOKEN_ALREADY_CLAIMED");
        _claim(tokenId, _msgSender());
        _allowances[tokenId] = true;
    }

    function ownerClaim() external onlyOwner {
        require(!_ownerClaim, "OWNER_CLAIM_CAN_ONLY_BE_CALLED_ONCE");
        uint256 ownerClaimAmount = 1337 * diamondOfTheRealmPerTokenId;
        _mint(owner(), ownerClaimAmount);
        _ownerClaim = true;
    }

    function _claim(uint256 tokenId, address addr) internal {
        require(
            tokenId >= tokenIdStart && tokenId <= tokenIdEnd,
            "TOKEN_ID_OUT_OF_RANGE"
        );
        _mint(addr, diamondOfTheRealmPerTokenId);
    }
}

