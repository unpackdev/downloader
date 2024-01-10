// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

abstract contract ContentManageable {
    address private _contentManager;

    constructor(address manager) {
        _contentManager = manager;
    }

    /**
     * @dev Returns the address of the content manager.
     */
    function contentManager() public view virtual returns (address) {
        return _contentManager;
    }

    /**
     * @dev Throws if called by any account other than the content manager.
     */
    modifier onlyContentManager {
        require(
            msg.sender == _contentManager,
            "ContentManageable: caller is not the content manager"
        );
        _;
    }
}
