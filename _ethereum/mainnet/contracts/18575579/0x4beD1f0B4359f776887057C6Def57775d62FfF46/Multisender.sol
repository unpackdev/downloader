// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";

/**
 * @dev Send ERC20/ERC721 to multiple account at once
 *
 * Features:
 *  - No transaction fees
 *  - Protection against gas griefing
 *  - User-friendly error messages: Lists each address if transfer fails
 *  - Audited using the reputable tool(=`slither`)
 *
 */
contract Multisender {
    using Strings for uint256;
    using Strings for address;

    // Fixed gas consumption when `transfer` is called
    uint256 public constant TRANSFER_GAS = 2300;

    // Default gas consumption when utilizing Openzeppelin mesured by `GasMeter.sol`
    uint256 public constant BASE_ERC20_TRANSFER_GAS = 28384;
    uint256 public constant BASE_ERC721_TRANSFER_GAS = 37573;

    // The multiplier to calculate max consumable gas
    uint256 public constant MAX_GAS_MULTIPLIER = 3;

    /**
     * @dev Transfer native token to multiple receipients
     * Revert if the transferring operation consume larger gas then standard
     * The native opcode `transfer` consume 2300 gas, but the actual gas consumption
     * become larger than it when the receipient is a contract.
     * Ref: https://consensys.io/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
     *
     * @param tos list of receipient addresses
     * @param amounts list of amounts
     * @param baseGas_ the basic gas consumption of transferring operation
     */
    function multisend(
        address[] calldata tos,
        uint256[] calldata amounts,
        uint256 baseGas_
    ) public payable {
        require(tos.length == amounts.length, "tos and amounts must have the same length");

        uint256 baseGas = baseGas_ != 0 ? baseGas_ : TRANSFER_GAS;

        string memory failedList = "";
        uint256 sum = 0;
        for (uint256 i = 0; i < tos.length; i++) {
            sum += amounts[i];
            if (!_transfer(tos[i], amounts[i], baseGas)) {
                failedList = string.concat(failedList, tos[i].toHexString(), ",");
            }
        }

        require(sum == msg.value, "sum of amounts must be equal to msg.value");

        _assertFailedList(failedList);
    }

    /**
     * @dev Transfer erc20 to multiple receipients
     * Revert if the transferring operation consume `MAX_GAS_MULTIPLIER` times larger gas then standard
     *
     * @param token address of token
     * @param tos list of receipient addresses
     * @param amounts list of amounts
     * @param baseGas_ the basic gas consumption of transferring operation
     */
    function multisendERC20(
        address token,
        address[] calldata tos,
        uint256[] calldata amounts,
        uint256 baseGas_
    ) public {
        require(token != address(0), "token address cannot be 0");
        require(tos.length == amounts.length, "tos and amounts must have the same length");

        uint256 baseGas = baseGas_ != 0 ? baseGas_ : BASE_ERC20_TRANSFER_GAS;

        string memory failedList = "";
        for (uint256 i = 0; i < tos.length; i++) {
            if (
                !_transferGeneric(
                    token,
                    baseGas,
                    "transferFrom(address,address,uint256)",
                    abi.encode(msg.sender, tos[i], amounts[i])
                )
            ) {
                // if (!_transferERC20(token, tos[i], amounts[i], baseGas)) {
                failedList = string.concat(failedList, tos[i].toHexString(), ",");
            }
        }

        _assertFailedList(failedList);
    }

    /**
     * @dev Transfer erc721 to multiple receipients
     * Revert if the transferring operation consume `MAX_GAS_MULTIPLIER` times larger gas then standard
     *
     * @param token address of token
     * @param tos list of receipient addresses
     * @param tokenIds list of tokenIds
     * @param data list of data
     * @param baseGas_ the basic gas consumption of transferring operation
     */
    function multisendERC721(
        address token,
        address[] calldata tos,
        uint256[] calldata tokenIds,
        bytes[] calldata data,
        uint256 baseGas_
    ) public {
        require(token != address(0), "token address cannot be 0");
        require(tos.length == tokenIds.length, "tos and tokenIds must have the same length");
        require(tos.length == data.length, "tos and data must have the same length");

        uint256 baseGas = baseGas_ != 0 ? baseGas_ : BASE_ERC721_TRANSFER_GAS;

        string memory failedList = "";
        for (uint256 i = 0; i < tos.length; i++) {
            if (
                !_transferGeneric(
                    token,
                    baseGas,
                    "safeTransferFrom(address,address,uint256,bytes)",
                    abi.encode(msg.sender, tos[i], tokenIds[i], data[i])
                )
            ) {
                failedList = string.concat(failedList, tos[i].toHexString(), ",");
            }
        }

        _assertFailedList(failedList);
    }

    // function _validateLeftgas(uint256 i, uint256 total, uint256 requiredGas) internal view {
    //     if (gasleft() < requiredGas) {
    //         revert(
    //             string.concat(
    //                 "will run out of gas at index ",
    //                 (i + 1).toString(),
    //                 " in ",
    //                 total.toString(),
    //                 ", left: ",
    //                 gasleft().toString(),
    //                 " required: ",
    //                 requiredGas.toString()
    //             )
    //         );
    //     }
    // }

    function _assertFailedList(string memory failedList) internal pure {
        uint256 length = bytes(failedList).length;

        if (length > 0) {
            revert(
                string.concat(
                    "failed to transfer to ",
                    // NOTE: 43 length = address + ","
                    (length / 43).toString(),
                    " addresses: ",
                    failedList
                )
            );
        }
    }

    function _transfer(address to, uint256 amount, uint256 baseGas) internal returns (bool) {
        // NOTE: call transferFrom with gas limit to avoid gas greefing
        // slither-disable-next-line arbitrary-send-eth
        (bool success, ) = to.call{gas: baseGas, value: amount}("");
        return success;
    }

    function _transferGeneric(
        address target,
        uint256 baseGas,
        string memory functionSignature,
        bytes memory args
    ) internal returns (bool) {
        // NOTE: call with gas limit to avoid gas greefing
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = target.call{gas: baseGas * MAX_GAS_MULTIPLIER}(
            abi.encodePacked(bytes4(keccak256(bytes(functionSignature))), args)
        );

        // If the function returns a boolean, decode it. Otherwise, just return the success flag.
        if (data.length == 32) {
            return success && abi.decode(data, (bool));
        }
        return success;
    }
}
