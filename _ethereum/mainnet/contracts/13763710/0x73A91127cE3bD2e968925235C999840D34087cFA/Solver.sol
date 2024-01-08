// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./AdminControl.sol";
import "./ISolver.sol";

contract Solver is ISolver, AdminControl {
    /// @dev product => operation => paused
    mapping(address => mapping(string => bool)) public operationPaused;

    string private constant _ALL_OPERATIONS = "ALL_OPERATIONS";

    function initialize() external {
        AdminControl.__AdminControl_init(_msgSender());
    }

    function setOperationPaused(
        address product_,
        string calldata operation_,
        bool setPaused_
    ) external virtual override onlyAdmin {
        operationPaused[product_][operation_] = setPaused_;
        emit SetOperationPaused(product_, operation_, setPaused_);
    }

    function operationAllowed(string calldata operation_, bytes calldata data_)
        external
        virtual
        override
        returns (uint256)
    {
        data_;
        address product = _msgSender();
        require(!operationPaused[product][_ALL_OPERATIONS], "product paused");
        require(!operationPaused[product][operation_], "operation paused");
        return 0;
    }

    function operationVerify(string calldata operation_, bytes calldata data_)
        external
        virtual
        override
        returns (uint256)
    {
        operation_;
        data_;
        return 0;
    }

    function isSolver() external pure override returns (bool) {
        return true;
    }
}
