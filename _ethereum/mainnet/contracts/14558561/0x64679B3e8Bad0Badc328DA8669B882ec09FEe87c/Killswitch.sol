//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IKillswitch.sol";

contract Killswitch is Ownable, IKillswitch {
    bool private _enabled = false;

    modifier killswitch() {
        require(!!_enabled, "contract disabled");
        _;
    }

    function isEnabled() external view override returns (bool)
    {
        return _enabled;
    }

    function enableContract() public override onlyOwner {
        _enabled = true;
    }

    function disableContract() public override onlyOwner {
        _enabled = false;
    }
}
