// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20Metadata} from "ERC20.sol";
import {IAutomatedLineOfCredit} from "IAutomatedLineOfCredit.sol";
import {PortfolioFactory} from "PortfolioFactory.sol";
import {ITransferController} from "ITransferController.sol";
import {IDepositController} from "IDepositController.sol";
import {IWithdrawController} from "IWithdrawController.sol";
import {Clones} from "Clones.sol";
import {Address} from "Address.sol";

contract AutomatedLineOfCreditFactory is PortfolioFactory {
    using Address for address;

    struct ControllersData {
        /// @dev Implementation of the controller applied when calling deposit-related functions
        address depositControllerImplementation;
        /// @dev Encoded args with initialize method selector from deposit controller
        bytes depositControllerInitData;
        /// @dev Implementation of the controller applied when calling withdraw-related functions
        address withdrawControllerImplementation;
        /// @dev Encoded args with initialize method selector from withdraw controller
        bytes withdrawControllerInitData;
        /// @dev Implementation of the controller used when calling transfer-related functions
        address transferControllerImplementation;
        /// @dev Encoded args with initialize method selector from transfer controller
        bytes transferControllerInitData;
    }

    function createPortfolio(
        uint256 _duration,
        IERC20Metadata _asset,
        uint256 _maxSize,
        IAutomatedLineOfCredit.InterestRateParameters calldata _interestRateParameters,
        ControllersData calldata controllersData,
        string calldata name,
        string calldata symbol
    ) external onlyRole(MANAGER_ROLE) {
        IAutomatedLineOfCredit.Controllers memory controllers = setupControllers(controllersData);
        bytes memory initCalldata = abi.encodeWithSelector(
            IAutomatedLineOfCredit.initialize.selector,
            protocolConfig,
            _duration,
            _asset,
            msg.sender,
            _maxSize,
            _interestRateParameters,
            controllers,
            name,
            symbol
        );
        _deployPortfolio(initCalldata);
    }

    function setupControllers(ControllersData memory controllersData) internal returns (IAutomatedLineOfCredit.Controllers memory) {
        address depositController = Clones.clone(controllersData.depositControllerImplementation);
        depositController.functionCall(controllersData.depositControllerInitData);

        address withdrawController = Clones.clone(controllersData.withdrawControllerImplementation);
        withdrawController.functionCall(controllersData.withdrawControllerInitData);

        address transferController = Clones.clone(controllersData.transferControllerImplementation);
        transferController.functionCall(controllersData.transferControllerInitData);

        return
            IAutomatedLineOfCredit.Controllers(
                IDepositController(depositController),
                IWithdrawController(withdrawController),
                ITransferController(transferController)
            );
    }
}
