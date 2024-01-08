// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./IERC20.sol";

import "./IKeeperSubsidyPool.sol";
import "./ControllerMixin.sol";

contract KeeperSubsidyPool is ControllerMixin, IKeeperSubsidyPool {
    using SafeERC20 for IERC20;

    mapping(address => bool) internal beneficiaries;

    event SetBeneficiary(address beneficiary, bool canRequest);

    constructor(IController _controller) ControllerMixin(_controller) {}

    /**
     * @notice Returns the address of the current Aggregator which provides the exchange rate between TokenA and TokenB
     * @return Address of aggregator
     */
    function getController() external view override returns (address) {
        return address(controller);
    }

    /**
     * @notice Updates the Controller
     * @dev Can only called by an authorized sender
     * @param _controller Address of the new Controller
     * @return True on success
     */
    function setController(address _controller) external override onlyDao("KeeperSubsidyPool: not dao") returns (bool) {
        _setController(_controller);
        return true;
    }

    /**
     * @notice Set `can request` status of beneficiary
     * @dev Can only be called by an authorized sender
     * @param beneficiary Address of the beneficiary
     * @param canRequest Bool whether address can request or not
     * @return True on Success
     */
    function setBeneficiary(
        address beneficiary,
        bool canRequest
    ) external override onlyDaoOrGuardian("KeeperSubsidyPool: not dao or guardian") returns (bool) {
        beneficiaries[beneficiary] = canRequest;
        emit SetBeneficiary(beneficiary, canRequest);
        return true;
    }

    /**
     * @notice Return whether an address can request subsidy
     * @param beneficiary Address of beneficiary
     * @return True if it can request subsidy
     */
    function isBeneficiary(address beneficiary) external view override returns (bool) {
        return (beneficiaries[beneficiary]);
    }

    /**
     * @notice Requests subsidy from pool
     * @dev Can only be called if address is set as a beneficiary
     * @param token Address of the subsidy token
     * @param amount Subsidy amount
     * @return True on Success
     */
    function requestSubsidy(address token, uint256 amount) external override returns (bool) {
        require(beneficiaries[msg.sender], "KeeperSubsidyPool: not beneficiary");
        IERC20(token).safeTransfer(msg.sender, amount);
        return true;
    }
}
