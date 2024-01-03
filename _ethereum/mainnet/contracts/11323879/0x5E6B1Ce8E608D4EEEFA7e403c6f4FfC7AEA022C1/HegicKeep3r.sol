// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

import "./IHegicKeep3r.sol";
import "./IHegic.sol";
import "./Governable.sol";
import "./CollectableDust.sol";

import "./Keep3rAbstract.sol";

contract HegicKeep3r is Governable, CollectableDust, Keep3r, IHegicKeep3r {
    using SafeMath for uint256;

    address public ethOptions = address(0xEfC0eEAdC1132A12c9487d800112693bf49EcfA2);
    address public wbtcOptions = address(0x3961245DB602eD7c03eECcda33eA3846bD8723BD);

    constructor(address _keep3r) public Governable(msg.sender) CollectableDust() Keep3r(_keep3r) {}

    function setKeep3r(address _keep3r) external override onlyGovernor {
        _setKeep3r(_keep3r);
        emit Keep3rSet(_keep3r);
    }

    // Getters
    function name() external pure override returns (string memory) {
        return "Hegic Keep3r";
    }

    function ethOptionUnlockable(uint256 _optionId) external override view returns (bool) {
        Option memory option = IHegic(ethOptions).options(_optionId);
        return option.state == State.Active && option.expiration < block.timestamp;
    }

    function wbtcOptionUnlockable(uint256 _optionId) external override view returns (bool) {
        Option memory option = IHegic(wbtcOptions).options(_optionId);
        return option.state == State.Active && option.expiration < block.timestamp;
    }

    // Keep3r actions
    function ethUnlock(uint256 _optionId) external override paysKeeper {
        IHegic(ethOptions).unlock(_optionId);
    }

    function wbtcUnlock(uint256 _optionId) external override paysKeeper {
        IHegic(wbtcOptions).unlock(_optionId);
    }

    // Governable
    function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
        _setPendingGovernor(_pendingGovernor);
    }

    function acceptGovernor() external override onlyPendingGovernor {
        _acceptGovernor();
    }

    // Collectable Dust
    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external override onlyGovernor {
        _sendDust(_to, _token, _amount);
    }
}
