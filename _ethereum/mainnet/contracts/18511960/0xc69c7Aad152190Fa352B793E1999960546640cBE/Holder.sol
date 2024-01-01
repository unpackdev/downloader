// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

abstract contract Holder {
    event ChangeHolderEvent(address holder);

    address private _holder;

    constructor() {
        _setHolder(msg.sender);
    }

    function changeHolder(address newHolder) external virtual onlyHolder {
        require(newHolder != address(0), "New holder is the zero address");
        _setHolder(newHolder);
    }

    modifier onlyHolder() {
        _checkHolder();
        _;
    }

    function holder() public view virtual returns (address) {
        return _holder;
    }

    function _checkHolder() internal view virtual {
        require(holder() == msg.sender, "Caller is not the holder");
    }

    function _setHolder(address newHolder) internal virtual {
        _holder = newHolder;
        emit ChangeHolderEvent(newHolder);
    }
}