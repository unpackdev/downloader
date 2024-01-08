// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Presale is Context {
    event PresaleStarted(address account);
    event SaleStarted(address account);

    event PresaleStopped(address account);
    event SaleStopped(address account);

    bool private _presaleStarted;
    bool private _saleStarted;

    mapping(address => bool) private _whitelistedAccounts;

    /**
     * @dev Initializes the contract in disabled sales state.
     */
    constructor() {
        _presaleStarted = false;
        _saleStarted = false;
    }

    function saleStarted() public view virtual returns (bool) {
        return _saleStarted;
    }

    function presaleStarted() public view virtual returns (bool) {
        return _presaleStarted;
    }

    modifier whenPresaleNotStarted() {
        require(!presaleStarted(), "Presale is started");
        _;
    }

    modifier whenPresaleStarted() {
        require(presaleStarted(), "Presale is not started");
        _;
    }

    modifier whenSaleNotStarted() {
        require(!saleStarted(), "Sale is started");
        _;
    }

    modifier whenSaleStarted() {
        require(saleStarted(), "Sale is not started");
        _;
    }

    function _stopPresale() internal virtual whenPresaleStarted {
        _presaleStarted = false;
        emit PresaleStopped(_msgSender());
    }

    function _startPresale() internal virtual whenPresaleNotStarted {
        _presaleStarted = true;
        emit PresaleStarted(_msgSender());
    }

    function _stopSale() internal virtual whenSaleStarted {
        _saleStarted = false;
        emit SaleStopped(_msgSender());
    }

    function _startSale() internal virtual whenSaleNotStarted {
        _saleStarted = true;
        emit SaleStarted(_msgSender());
    }

    function _whitelist(address account) internal virtual {
        require(!whitelisted(account), "Address already whitelisted");

        _whitelistedAccounts[account] = true;
    }

    function _removeFromWhitelist(address account) internal virtual {
        require(whitelisted(account), "Address is not whitelisted");

        delete _whitelistedAccounts[account];
    }

    function whitelisted(address account) public view returns (bool) {
        return _whitelistedAccounts[account];
    }

    modifier whenWhitelisted() {
        require(whitelisted(_msgSender()), "Address is not whitelisted for presale");
        _;
    }
}
