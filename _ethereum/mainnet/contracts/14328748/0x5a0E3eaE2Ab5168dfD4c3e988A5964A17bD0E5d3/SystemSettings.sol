// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Inheritance
import "./OwnedwManager.sol";
import "./MixinResolver.sol";
import "./MixinSystemSettings.sol";

interface ISystemSettings {
    // Views

}
// Libraries
import "./SafeDecimalMath.sol";

contract SystemSettings is OwnedwManager, MixinSystemSettings, ISystemSettings {
    using SafeMath for uint;
    using SafeDecimalMath for uint;


    constructor(address _owner, address _resolver) public OwnedwManager(_owner,_owner) MixinSystemSettings(_resolver) {}

}
