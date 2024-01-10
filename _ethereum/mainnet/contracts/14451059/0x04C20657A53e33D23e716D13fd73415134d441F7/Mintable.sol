// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./ERC721Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./Config.sol";

abstract contract Mintable is Initializable, ERC721Upgradeable, OwnableUpgradeable, Config {
    enum Sale {
        Closed,
        PreSale,
        Public
    }

    using ECDSAUpgradeable for bytes32;
    Sale public sale;
    mapping(address => uint256) public preSaleMintedTokens;
    address private _preSaleSigner;
    uint256 private _nextTokenId;
    bool private _hasMintedReserved;

    function totalSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function burn(uint256 id) external onlyOwner {
        _burn(id);
    }
}
