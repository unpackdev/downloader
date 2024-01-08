// SPDX-License-Identifier: Unlicensed
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, hagen@token-forge.io

pragma solidity >=0.8.0 <0.9.0;

import "./OPUS.sol";
import "./Context.sol";
import "./AccessControlEnumerable.sol";

contract ESECF1 is Context, AccessControlEnumerable {
    event TokenBuild(address result);

    mapping(address => address[]) private _tokenCreators;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function create(
        string calldata name,
        string calldata symbol,
        OPUS.ContractParameters calldata params
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        OPUS token = new OPUS(name, symbol);

        token.setParameters(params);

        // enable caller as minter role
        token.grantRole(token.MINTER_ROLE(), _msgSender());
        // renounce minting role from factory
        token.renounceRole(token.MINTER_ROLE(), address(this));

        token.grantRole(token.DEFAULT_ADMIN_ROLE(), _msgSender());

        token.grantRole(token.GOVERNANCE_ROLE(), _msgSender());
        token.renounceRole(token.GOVERNANCE_ROLE(), address(this));

        token.grantRole(token.WHITELIST_ADMIN_ROLE(), _msgSender());
        token.renounceRole(token.WHITELIST_ADMIN_ROLE(), address(this));

        token.grantRole(token.BLACKLIST_ADMIN_ROLE(), _msgSender());
        token.renounceRole(token.BLACKLIST_ADMIN_ROLE(), address(this));

        token.renounceRole(token.DEFAULT_ADMIN_ROLE(), address(this));

        _tokenCreators[_msgSender()].push(address(token));

        emit TokenBuild(address(token));
    }

    /**
     * @dev Returns one of the tokens. `index` must be a
     * value between 0 and {getTokenCount}, non-inclusive.
     *
     * Tokens are not sorted in any particular way, and their ordering may
     * change at any point.
     */
    function getToken(address creator, uint256 index) public view returns (address) {
        return _tokenCreators[creator][index];
    }

    /**
     * @dev Returns the number of accounts that have `creator`.
     */
    function getTokenCount(address creator) public view returns (uint256) {
        return _tokenCreators[creator].length;
    }
}
