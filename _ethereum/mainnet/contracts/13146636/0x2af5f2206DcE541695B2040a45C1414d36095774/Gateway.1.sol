// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./IERC20.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./Adapter.sol";
import "./Versioned.sol";
import "./Pausable.sol";
import "./Owned.sol";

/// @title GatewayV1
/// @author Iulian Rotaru
/// @notice The Gateway aggregates all adapters and helps users performs multiple actions at the same time.
contract GatewayV1 is Versioned, Pausable, Owned, ReentrancyGuardUpgradeable {
    //
    //                      _              _
    //   ___ ___  _ __  ___| |_ __ _ _ __ | |_ ___
    //  / __/ _ \| '_ \/ __| __/ _` | '_ \| __/ __|
    // | (_| (_) | | | \__ \ || (_| | | | | |_\__ \
    //  \___\___/|_| |_|___/\__\__,_|_| |_|\__|___/
    //

    // Denominator used with fee variable to compute amount kept by the gateway.
    uint256 constant FEE_DENOMINATOR = 1000000;
    //
    //      _        _
    //  ___| |_ __ _| |_ ___
    // / __| __/ _` | __/ _ \
    // \__ \ || (_| | ||  __/
    // |___/\__\__,_|\__\___|
    //

    // Store all adapters. Adapters perform purchasing logics for each supported platforms
    mapping(string => Adapter) public adapters;

    // Store all collected fees.
    mapping(address => uint256) public collectedFees;

    // Fee value.
    uint256 public fee;

    // Fee collector
    address public feeCollector;

    //
    //                       _
    //   _____   _____ _ __ | |_ ___
    //  / _ \ \ / / _ \ '_ \| __/ __|
    // |  __/\ V /  __/ | | | |_\__ \
    //  \___| \_/ \___|_| |_|\__|___/
    //

    // Emitted whenever an adapter is changed
    event AdapterChanged(string indexed actionType, address indexed adapter, address oldAdapter, address admin);

    // Emitted whenever a product is purchased
    event ExecutedAction(
        string indexed actionType,
        address indexed caller,
        address[] currencies,
        uint256[] amounts,
        uint256[] fees,
        bytes data,
        bytes outputData
    );

    //
    //      _                   _
    //  ___| |_ _ __ _   _  ___| |_ ___
    // / __| __| '__| | | |/ __| __/ __|
    // \__ \ |_| |  | |_| | (__| |_\__ \
    // |___/\__|_|   \__,_|\___|\__|___/
    //
    //

    // Input format
    struct Action {
        string actionType;
        address[] currencies;
        uint256[] amounts;
        bytes data;
    }

    //
    //                      _ _  __ _
    //  _ __ ___   ___   __| (_)/ _(_) ___ _ __ ___
    // | '_ ` _ \ / _ \ / _` | | |_| |/ _ \ '__/ __|
    // | | | | | | (_) | (_| | |  _| |  __/ |  \__ \
    // |_| |_| |_|\___/ \__,_|_|_| |_|\___|_|  |___/
    //

    // Check that caller is fee collector
    modifier isFeeCollector() {
        require(msg.sender == feeCollector, 'G9');
        _;
    }

    //
    //  _       _                        _
    // (_)_ __ | |_ ___ _ __ _ __   __ _| |___
    // | | '_ \| __/ _ \ '__| '_ \ / _` | / __|
    // | | | | | ||  __/ |  | | | | (_| | \__ \
    // |_|_| |_|\__\___|_|  |_| |_|\__,_|_|___/
    //

    /// @dev Retrieves the available balance for all used currencies.
    ///      Simply computes current effective balance and substract collected fees
    /// @param currencies Address of currencies
    /// @return A tuple with the raw current balances and usable balances
    function _getAvailableBalance(address[] memory currencies)
        internal
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory currentBalances = new uint256[](currencies.length);
        uint256[] memory availableBalances = new uint256[](currencies.length);
        for (uint256 idx = 0; idx < currencies.length; ++idx) {
            uint256 balance = _getBalance(currencies[idx]);
            currentBalances[idx] = balance;
            availableBalances[idx] = balance - collectedFees[currencies[idx]];
        }
        return (currentBalances, availableBalances);
    }

    /// @dev Retrieves the available balance for one currency.
    /// @param currency Address of the currency
    /// @return The current balance of the provided currency
    function _getBalance(address currency) internal view returns (uint256) {
        if (currency == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(currency).balanceOf(address(this));
        }
    }

    /// @dev Prepares adapter call by approving or computing amount of eth to send with call.
    ///      Also computes extracted fee.
    /// @param currencies List of currencies to send/approve
    /// @param amounts Amounts of currencies to send/approve
    /// @param adapter Address of adapter receiving the call
    /// @return A tuple containing the amount of eth to send during call, the amounts without the extracted fee and the extracted fees
    function _transferAndGetAmount(
        address[] memory currencies,
        uint256[] memory amounts,
        Adapter adapter
    )
        internal
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256[] memory amountsWithoutFees = new uint256[](amounts.length);
        uint256[] memory extractedFees = new uint256[](amounts.length);
        uint256 callValue = 0;
        for (uint256 idx; idx < currencies.length; ++idx) {
            amountsWithoutFees[idx] = (amounts[idx] * FEE_DENOMINATOR) / (FEE_DENOMINATOR + fee) + 1;
            extractedFees[idx] = amounts[idx] - amountsWithoutFees[idx];

            collectedFees[currencies[idx]] += extractedFees[idx];

            if (currencies[idx] == address(0)) {
                callValue = amountsWithoutFees[idx];
            } else {
                IERC20(currencies[idx]).approve(address(adapter), amountsWithoutFees[idx]);
            }
        }

        return (callValue, amountsWithoutFees, extractedFees);
    }

    /// @dev Retrieves all currencies for all actions provided on an execute call. If multiple actions, factorizes calls.
    /// @param actions list of received actions
    function _pull(Action[] calldata actions) internal {
        if (actions.length > 1) {
            uint256 totalCurrencies = 0;
            for (uint256 actionIdx = 0; actionIdx < actions.length; ++actionIdx) {
                Action memory action = actions[actionIdx];
                totalCurrencies += action.amounts.length;
                require(action.amounts.length == action.currencies.length, 'G1');
            }
            uint256[] memory totalAmounts = new uint256[](totalCurrencies);
            address[] memory currencies = new address[](totalCurrencies);
            for (uint256 actionIdx = 0; actionIdx < actions.length; ++actionIdx) {
                Action memory action = actions[actionIdx];
                for (uint256 currencyIdx = 0; currencyIdx < action.amounts.length; ++currencyIdx) {
                    if (action.currencies[currencyIdx] == address(0)) {
                        continue;
                    }
                    for (uint256 storedIdx; storedIdx < currencies.length; ++storedIdx) {
                        if (currencies[storedIdx] == action.currencies[currencyIdx]) {
                            totalAmounts[storedIdx] += action.amounts[currencyIdx];
                            break;
                        } else if (currencies[storedIdx] == address(0)) {
                            currencies[storedIdx] = action.currencies[currencyIdx];
                            totalAmounts[storedIdx] += action.amounts[currencyIdx];
                            break;
                        }
                    }
                }
            }
            for (
                uint256 currencyIdx = 0;
                currencyIdx < currencies.length && currencies[currencyIdx] != address(0);
                ++currencyIdx
            ) {
                IERC20(currencies[currencyIdx]).transferFrom(msg.sender, address(this), totalAmounts[currencyIdx]);
            }
        } else {
            require(actions[0].amounts.length == actions[0].currencies.length, 'G2');
            for (uint256 idx = 0; idx < actions[0].currencies.length; ++idx) {
                if (actions[0].currencies[idx] != address(0)) {
                    IERC20(actions[0].currencies[idx]).transferFrom(msg.sender, address(this), actions[0].amounts[idx]);
                }
            }
        }
    }

    //
    //            _                        _
    //   _____  _| |_ ___ _ __ _ __   __ _| |___
    //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
    // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
    //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
    //

    /// @notice Send an array of actions you want to execute from the gateway
    /// @param actions List of actions to execute
    function execute(Action[] calldata actions) external payable nonReentrant whenNotPaused {
        _pull(actions);
        for (uint256 actionIdx = 0; actionIdx < actions.length; ++actionIdx) {
            Action memory action = actions[actionIdx];

            (uint256[] memory preBalances, uint256[] memory availableBalances) = _getAvailableBalance(
                action.currencies
            );

            for (uint256 idx = 0; idx < action.amounts.length; ++idx) {
                require(availableBalances[idx] >= action.amounts[idx], 'G3');
            }

            Adapter adapter = adapters[action.actionType];

            require(address(adapter) != address(0), 'G4');

            (
                uint256 callValue,
                uint256[] memory amountsWithoutFees,
                uint256[] memory extractedFees
            ) = _transferAndGetAmount(action.currencies, action.amounts, adapter);

            (uint256[] memory usedAmount, bytes memory outputData) = adapter.run{value: callValue}(
                msg.sender,
                action.currencies,
                amountsWithoutFees,
                action.data
            );

            for (uint256 idx = 0; idx < action.currencies.length; ++idx) {
                uint256 postBalance = _getBalance(action.currencies[idx]);
                if (postBalance > preBalances[idx] - amountsWithoutFees[idx]) {
                    if (action.currencies[idx] == address(0)) {
                        (bool success, ) = payable(msg.sender).call{
                            value: postBalance - (preBalances[idx] - amountsWithoutFees[idx])
                        }('');
                        require(success, 'G5');
                    } else {
                        IERC20(action.currencies[idx]).transfer(
                            msg.sender,
                            postBalance - (preBalances[idx] - amountsWithoutFees[idx])
                        );
                    }
                }
            }

            emit ExecutedAction(
                action.actionType,
                msg.sender,
                action.currencies,
                usedAmount,
                extractedFees,
                action.data,
                outputData
            );
        }
    }

    /// @notice Register a new address as an adapter
    /// @param actionType Name of the action
    /// @param adapter Address of the new adapter
    function registerAdapter(string calldata actionType, address adapter) external isAdmin {
        require(AddressUpgradeable.isContract(adapter), 'G6');
        require(adapters[actionType] != Adapter(adapter), 'G7');

        emit AdapterChanged(actionType, adapter, address(adapters[actionType]), Owned.getAdmin());

        adapters[actionType] = Adapter(adapter);
    }

    /// @notice Changes the address able to collect fees
    /// @param newFeeCollector Address able to collect fees
    function setFeeCollector(address newFeeCollector) external isAdmin {
        require(newFeeCollector != feeCollector, 'G8');
        feeCollector = newFeeCollector;
    }

    /// @notice Withdraws collected fees by providing currency addresses to withdraw
    /// @param currencies List of currencies to withdraw
    /// @return List of withdrawn amounts
    function withdrawCollectedFees(address[] memory currencies) external isFeeCollector returns (uint256[] memory) {
        uint256[] memory withdrawnFees = new uint256[](currencies.length);
        for (uint256 idx = 0; idx < currencies.length; ++idx) {
            if (currencies[idx] == address(0)) {
                (bool success, ) = feeCollector.call{value: collectedFees[currencies[idx]]}('');
                require(success, 'G10');
            } else {
                IERC20(currencies[idx]).transfer(feeCollector, collectedFees[currencies[idx]]);
            }
            withdrawnFees[idx] = collectedFees[currencies[idx]];
            collectedFees[currencies[idx]] = 0;
        }
        return withdrawnFees;
    }

    //
    //  _       _ _
    // (_)_ __ (_) |_
    // | | '_ \| | __|
    // | | | | | | |_
    // |_|_| |_|_|\__|
    //

    function __GatewayV1__constructor() public initVersion(1) {
        fee = 1000;
        feeCollector = getAdmin();
    }
}
