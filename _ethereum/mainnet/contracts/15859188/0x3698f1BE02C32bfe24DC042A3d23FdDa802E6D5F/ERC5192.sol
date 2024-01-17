// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC5192.sol";

contract ERC5192 is IERC5192 {
    bool public isLockPeriodInEffect;
    mapping(uint256 => bool) public tokenIsLocked;

    modifier whenNotLocked(uint256 tokenId) {
        if (isLockPeriodInEffect) {
            require(!tokenIsLocked[tokenId], "ERC5192: TokenId locked.");
        }
        _;
    }

    modifier whenNotLockPeriodInEffect() {
        if (isLockPeriodInEffect) {
            revert("ERC5192: Token locked.");
        }
        _;
    }

    function setLockPeriodInEffect(bool state_) public virtual {
        isLockPeriodInEffect = state_;
    }

    function lock(uint256 tokenId_) public virtual {
        tokenIsLocked[tokenId_] = true;
        emit Locked(tokenId_);
    }

    function unlock(uint256 tokenId_) public virtual {
        tokenIsLocked[tokenId_] = false;
        emit Unlocked(tokenId_);
    }

    function locked(uint256 tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return tokenIsLocked[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return interfaceId == type(IERC5192).interfaceId;
    }
}
