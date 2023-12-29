// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./Ownable.sol";

abstract contract AwaitingTheUNMUTOOOOR is Ownable {
    error CallerIsNotTheUNMUTOOOOR();
    error SoundscapeAlreadyUnmuted();
    error UnmuteFailed();
    error ___0_0_0___();

    bool public _SOUNDSCAPE_MUTED_ = true;

    address public constant _THE_UNMUTOOOOR_ = 0x4832344Cf14896818229d81C44C2040AAf1F1a95;

    bytes private ___3_3_3___;

    function ___THESE_GO_TO_ELEVEN___()
        external
    {
        if (false == _SOUNDSCAPE_MUTED_) revert SoundscapeAlreadyUnmuted();
        if (_msgSender() != _THE_UNMUTOOOOR_) revert CallerIsNotTheUNMUTOOOOR();
        if (___3_3_3___.length == 0) revert ___0_0_0___();

        _SOUNDSCAPE_MUTED_ = false;
        (bool success, ) = address(this).call(___3_3_3___);
        if (!success) revert UnmuteFailed();
    }

    function _THREE_THREE_THREE_(
        bytes calldata _3_3_3_
    )
        external
        onlyOwner
    {
        ___3_3_3___ = _3_3_3_;
    }
}
