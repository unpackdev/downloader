// SPDX-License-Identifier: MPL-2.0
// Name: SolidGuardManager
// GitHub: https://github.com/SolidGuard
// Version: v1.0

pragma solidity ^0.8.3;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

interface ISolidGuardPauseable {
    function isSGPaused() external view returns (bool);
    function setSGPaused(bool _sgPaused) external;
}

/**
 * @title SolidGuardManager
 * @dev Creates a SolidGuardManager, managed by the SolidGuard API. Responsible
 * for pausing smart contracts, as well as collecting fee payments.
 */
contract SolidGuardManager is Initializable, OwnableUpgradeable {

    // State variables
    uint constant public price = 0.01 ether;
    mapping(address => uint) public dAppPauses;

    // Events
    event Deposit(address _dApp, uint _pauses);
    event Pause(address _dApp);

    /**
     * @dev Initializes an upgradeable instance of SolidGuardManager where
     * the contract deployer is the owner of the smart contract.
     *
     * NOTE: The constructor below is used for immediate initialization.
     * See https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
     */
    function initialize() public initializer {
        __Ownable_init();
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Gets number of pauses for the specified dApp
     */
    function getPauses(address dApp) external view returns (uint) {
        return dAppPauses[dApp];
    }

    /**
     * @dev Gets number of pauses for the specified dApps, in order
     */
    function batchGetPauses(address[] memory dApps) external view returns (uint[] memory) {
        uint[] memory selectedDAppPauses = new uint[](dApps.length);
        for (uint i = 0; i < dApps.length; i++){
            selectedDAppPauses[i] = dAppPauses[dApps[i]];
        }
        return selectedDAppPauses;
    }

    /**
     * @dev Pauses the following dApps that are pauseable.
     */
    function batchPause(address[] memory dApps) external onlyOwner {
        for (uint i = 0; i < dApps.length; i++){
            dAppPauses[dApps[i]]--;
            ISolidGuardPauseable(dApps[i]).setSGPaused(true);
            Pause(dApps[i]);
        }
    }

    /**
     * @dev Deposit ETH for pauses for the given dApps. 
     */
    function deposit(address[] memory dApps, uint[] memory pauses) external payable {
        // check matching input
        require(dApps.length == pauses.length, "SolidGuardManager: Input size mismatch.");

        // calculate the price
        uint totalPauses = 0;
        for (uint i = 0; i < pauses.length; i++){
            totalPauses += pauses[i];
            dAppPauses[dApps[i]] += pauses[i];
            emit Deposit(dApps[i], pauses[i]);
        }

        // pay owner
        require(msg.value >= price * totalPauses, "SolidGuardManager: Not enough ether.");
        (bool sent, ) = payable(owner()).call{value: price * totalPauses}("");
        require(sent, "SolidGuardManager: Deposit failed.");
    }

    // Padding for new variables.
    uint256[48] private __gap;
}