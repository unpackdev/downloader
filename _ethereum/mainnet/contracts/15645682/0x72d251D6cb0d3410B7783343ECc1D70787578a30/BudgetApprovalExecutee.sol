// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;
import "./ERC1967Proxy.sol";
import "./ICommonBudgetApproval.sol";
import "./Initializable.sol";

import "./RevertMsg.sol";
import "./Concat.sol";

contract BudgetApprovalExecutee is Initializable {
    using Concat for string;

    address private _team;

    mapping(address => bool) private _budgetApprovals;

    event CreateBudgetApproval(address budgetApproval, bytes data);
    event ExecuteByBudgetApproval(address budgetApproval, bytes data);

    modifier onlyBudgetApproval {
        require(budgetApprovals(msg.sender), "BudgetApprovalExecutee: access denied");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
    }

    function ___BudgetApprovalExecutee_init(address __team) internal onlyInitializing {
        _team = __team;
    }

    function team() public view virtual returns (address) {
        return _team;
    }

    function budgetApprovals(address template) public view virtual returns (bool) {
        return _budgetApprovals[template];
    }

    function executeByBudgetApproval(address _to, bytes memory _data, uint256 _value) external onlyBudgetApproval returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{ value: _value }(_data);
        if(!success) {
            revert(string("Reverted by external contract").concat(RevertMsg.ToString(result)));
        }
        emit ExecuteByBudgetApproval(msg.sender, _data);

        return result;
    }

    function _beforeCreateBudgetApproval(address) virtual internal {}

    function createBudgetApprovals(address[] memory __budgetApprovals, bytes[] memory data) external virtual {
        require(__budgetApprovals.length == data.length, "Incorrect Calldata");

        for(uint i = 0; i < __budgetApprovals.length; i++) {
            _beforeCreateBudgetApproval(__budgetApprovals[i]);

            ERC1967Proxy ba = new ERC1967Proxy(__budgetApprovals[i], data[i]);
            _budgetApprovals[address(ba)] = true;
            emit CreateBudgetApproval(address(ba), data[i]);

            ICommonBudgetApproval(address(ba)).afterInitialized();
        }
    }

    uint256[50] private __gap;
}
