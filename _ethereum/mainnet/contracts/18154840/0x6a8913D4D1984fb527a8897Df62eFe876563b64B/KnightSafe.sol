// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./WhitelistManager.sol";
import "./NativeCurrencyReceiver.sol";
import "./Implementation.sol";
import "./SignatureValidator.sol";
import "./IParameterChecker.sol";

// import "./SafeMath.sol";

/**
 * @title KnightSafe contract
 * @author KnightSafeTeam
 * @notice Main point of interaction with a KnightSafe account
 */
contract KnightSafe is
    Implementation,
    NativeCurrencyReceiver,
    SignatureValidator,
    WhitelistManager
{
    // @dev `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler now has built in overflow checking.
    // using SafeMath for uint256;

    string public constant VERSION = "0.3.2";
    bool internal isGasRefund;

    event SetupComplete(
        address indexed initiator,
        address indexed owner,
        address[] initTraders,
        address[] initWhitelistAddresses,
        bytes4[][] initWhitelistSelectorLists,
        uint256[][][] initWhitelistParametersLists,
        bool refundGas
    );

    event GasRefunded(address indexed receiver, uint256 amount);
    // @dev following data should be able to achieve from transaction info
    // event ExecutedTransaction(
    //     address indexed to,
    //     uint256 value,
    //     bytes data
    // );

    // This is a empty constructor. Please create a KnightSafe using the Proxy Factory
    constructor() {
        owner = address(1);
    }

    /**
     * @notice Allow the owner to initial setup settings (e.g. traders, whitelists, gas refund) in one call. This function can be called only once.
     * @param owner The address of the owner
     * @param initTraders The list of address of authorized traders
     * @param initWhitelistAddresses The list of whitelist addresses
     * @param initWhitelistSelectorLists The list of whitelist selectors corresponding to whitelist addresses
     * @param initWhitelistParametersLists The list of whitelist parameters corresponding to whitelist selectors
     * @param refundGas Boolean indication network gas refund setting
     */
    function setup(
        address owner,
        address[] calldata initTraders,
        address[] calldata initWhitelistAddresses,
        bytes4[][] calldata initWhitelistSelectorLists,
        uint256[][][] calldata initWhitelistParametersLists,
        bool refundGas
    ) external {
        // setupOwner will revert if being called more than once. No extra checking in this function is needed.
        setupOwner(owner);
        setupTrader(initTraders);
        setupWhitelist(
            initWhitelistAddresses,
            initWhitelistSelectorLists,
            initWhitelistParametersLists
        );
        isGasRefund = refundGas;

        emit SetupComplete(
            msg.sender,
            owner,
            initTraders,
            initWhitelistAddresses,
            initWhitelistSelectorLists,
            initWhitelistParametersLists,
            refundGas
        );
    }

    /**
     * @notice Returns if the trader will be refunded for the gas spent.
     */
    function getIsGasRefund() public view returns (bool) {
        return isGasRefund;
    }

    /**
     * @notice Execute authorized transaction. Fee spent by trader will be refunded at the end if isGasRefund is set true by the owner.
     * @param to Destination address of the transaction
     * @param value Ether value of the transaction
     * @param data Data payload of the transaction
     * @return success Boolean indicating transaction's success
     */
    function execTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) public payable virtual onlyTrader returns (bool success) {
        uint256 gasAtStart = gasleft();

        validateTransaction(to, data);

        uint256 txGas = gasleft();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
        require(success, "Task failed");
        if (isGasRefund) {
            // 39686 is the gas cost that is independent of the transaction execution.
            uint256 gasRefundAmount = (gasAtStart - gasleft() + 39686) * tx.gasprice;            
            require(payable(msg.sender).send(gasRefundAmount), "Insufficient amount to refund gas spent");
            emit GasRefunded(msg.sender, gasRefundAmount);
        }
    }

    /**
     * @notice Validate the transaction. Revert if whitelist rule is violated.
     * @param to Destination address of the transaction
     * @param data Data payload of the transaction
     */
    function validateTransaction(address to, bytes memory data) internal view {
        // 1. check if the destination address is in whitelist
        require(isWhitelistAddress(to), "To address not in whitelist");
        if (data.length > 0) {
            // if the destination is a smart contract, check also the selector and the parameters.
            bytes4 selector;

            // solhint-disable-next-line no-inline-assembly
            assembly {
                selector := mload(add(data, add(0x20, 0)))
            }

            // 2. check if the address:selector is in the checklist:
            //    in the checklist => go for parameters checking,
            //    not in the checklist => validation passed.
            uint256[] memory checkList = getWhitelistFunctionParameters(
                to,
                selector
            );
            require(checkList.length != 0, "Selector not in whitelist");

            // 3. check if value of all corresponding position of parameter are in the whitelist:
            //    e.g. [1, 3] => 1st and 3rd parameter should be checked if exist in whitelisted addresses,
            //    e.g. ["0x1000000000000000000000001234567890123456789012345678901234567890"] => call external parameter checker at address 0x1234..90
            //    0 is ignored => A function without parameter checking should be [0].
            for (uint256 i = 0; i < checkList.length; i++) {                
                uint256 n = checkList[i];
                if (n != 0) {
                    if (n > 0x1000000000000000000000000000000000000000000000000000000000000000) { // check if first byte is not zero
                        // call external contract for checking
                        address extAddress = address(uint160(n));
                        address[] memory addressList = IParameterChecker(extAddress).getAddressListForChecking(to, selector, data);
                        require(addressList.length>0, "Parameter Checker should not return empty list");
                        for (uint256 j = 0; j < addressList.length; j++) {
                            require(isWhitelistAddress(addressList[j]), "Parameter address not in whitelist");
                        }
                    }
                    else {
                        // check if n-th parameter is whitelisted address
                        address _address;
                        uint256 _offset = 4 + n * 32;
                        // solhint-disable-next-line no-inline-assembly
                        assembly {
                            _address := mload(add(data, _offset))
                        }
                        require(isWhitelistAddress(_address), "Parameter address not in whitelist");
                    }
                }
            }
            
        }
    }

    /**
     * @param enableRefund Set gas refund on or off
     */
    function setOwnerRefundGasSpentToSender(
        bool enableRefund
    ) public onlyOwner {
        isGasRefund = enableRefund;
    }
}
