// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "./CommonBudgetApproval.sol";
import "./BytesLib.sol";
import "./IERC20.sol";

import "./IBudgetApprovalExecutee.sol";

contract TransferERC20BudgetApproval is CommonBudgetApproval {
    using BytesLib for bytes;

    string public constant override name = "Transfer ERC20 Budget Approval";

    bool public allowAllAddresses;
    mapping(address => bool) public addressesMapping;
    bool public allowAllTokens;
    address public token;
    bool public allowAnyAmount;
    uint256 public totalAmount;
    event ExecuteTransferERC20Transaction(uint256 indexed id, address indexed executor, address indexed toAddress, address token, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
    }

    function initialize(
        InitializeParams calldata params,
        bool _allowAllAddresses,
        address[] memory _toAddresses,
        bool _allowAllTokens,
        address _token,
        bool _allowAnyAmount,
        uint256 _totalAmount
    ) external initializer {
        __BudgetApproval_init(params);

        allowAllAddresses = _allowAllAddresses;
        for(uint i = 0; i < _toAddresses.length; i++) {
            _addToAddress(_toAddresses[i]);
        }
        allowAllTokens = _allowAllTokens;
        token = _token;
        allowAnyAmount = _allowAnyAmount;
        totalAmount = _totalAmount;
    }

    function executeParams() external pure override returns (string[] memory) {
        string[] memory arr = new string[](3);
        arr[0] = "address token";
        arr[1] = "address to";
        arr[2] = "uint256 value";
        return arr;
    }

    function _execute(
        uint256 transactionId,
        bytes memory data
    ) internal override {
        (address _token, address to, uint256 value) = abi.decode(data,(address, address, uint256));
        bytes memory executeData = abi.encodeWithSelector(IERC20.transfer.selector, to, value);
        bool _allowAnyAmount = allowAnyAmount;
        uint256 _totalAmount = totalAmount;

        IBudgetApprovalExecutee(executee()).executeByBudgetApproval(_token, executeData, 0);

        require(allowAllAddresses || addressesMapping[to], "Recipient not whitelisted in budget");
        require(allowAllTokens || token == _token, "Token not whitelisted in budget");
        require(_allowAnyAmount || value <= _totalAmount, "Exceeded max budget transferable amount");

        if(!_allowAnyAmount) {
            totalAmount = _totalAmount - value;
        }
        emit ExecuteTransferERC20Transaction(transactionId, msg.sender, to, _token, value);
    }

    function _addToAddress(address to) internal {
        require(!addressesMapping[to], "Duplicated address in target address list");
        addressesMapping[to] = true;
        emit AllowAddress(to);
    }
}