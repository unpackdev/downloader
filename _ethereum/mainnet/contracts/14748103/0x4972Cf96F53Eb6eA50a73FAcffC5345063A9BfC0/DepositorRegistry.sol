// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./IZapDepositor.sol";
import "./IAMM.sol";
import "./IAMMRegistry.sol";

contract DepositorRegistry is Initializable, OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private zaps;
    mapping(address => IZapDepositor) public ZapDepositorsPerAMM;
    IAMMRegistry public registry;

    event ZapDepositorSet(address _amm, IZapDepositor _zapDepositor);

    modifier isValidAmm(address _amm) {
        require(
            registry.isRegisteredAMM(_amm),
            "AMMRouter: invalid amm address"
        );
        _;
    }

    function initialize(IAMMRegistry _registry) public virtual initializer {
        __Ownable_init();
        registry = _registry;
    }

    function setZapDepositor(address _amm, IZapDepositor _zapDepositor)
        public
        onlyOwner
        isValidAmm(_amm)
    {
        ZapDepositorsPerAMM[_amm] = _zapDepositor;
        emit ZapDepositorSet(_amm, _zapDepositor);
    }

    function isRegisteredZap(address _zapAddress) external view returns (bool) {
        return zaps.contains(_zapAddress);
    }

    function addZap(address _zapAddress) external onlyOwner returns (bool) {
        return zaps.add(_zapAddress);
    }

    function removeZap(address _zapAddress) external onlyOwner returns (bool) {
        return zaps.remove(_zapAddress);
    }

    function zapLength() external view returns (uint256) {
        return zaps.length();
    }

    function zapAt(uint256 _index) external view returns (address) {
        return zaps.at(_index);
    }
}
