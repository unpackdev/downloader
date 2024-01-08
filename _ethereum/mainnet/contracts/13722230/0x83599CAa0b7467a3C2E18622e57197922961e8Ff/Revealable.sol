// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

abstract contract Revealable {
    /**
     * @dev Indicates that the contract has been revealed.
     */
    bool private _revealed;

    /**
     * @dev Indicates that the contract is in the process of being revealed.
     */
    bool private _revealing;

    /**
     * @dev Modifier to protect an reveal function from being invoked twice.
     */
    modifier revealer() {
        require(_revealing || !_revealed, "Revealable: contract is already revealed!");

        bool isTopLevelCall = !_revealing;
        if (isTopLevelCall) {
            _revealing = true;
            _revealed = true;
        }

        _;

        if (isTopLevelCall) {
            _revealing = false;
        }
    }
}
