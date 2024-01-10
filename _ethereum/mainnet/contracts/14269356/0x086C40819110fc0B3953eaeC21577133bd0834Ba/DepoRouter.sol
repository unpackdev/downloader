// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Permitable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract DepoRouter is Permitable, Ownable {
    using SafeMath for uint256;

    uint256 private constant _TRANSFER_FROM_CALL_SELECTOR_32 =
        0x23b872dd00000000000000000000000000000000000000000000000000000000;
    uint256 private constant _WETH_DEPOSIT_CALL_SELECTOR_32 =
        0xd0e30db000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _WETH_WITHDRAW_CALL_SELECTOR_32 =
        0x2e1a7d4d00000000000000000000000000000000000000000000000000000000;
    uint256 private constant _ERC20_TRANSFER_CALL_SELECTOR_32 =
        0xa9059cbb00000000000000000000000000000000000000000000000000000000;
    uint256 private constant _ADDRESS_MASK =
        0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant _REVERSE_MASK =
        0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _WETH_MASK =
        0x4000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _NUMERATOR_MASK =
        0x0000000000000000ffffffff0000000000000000000000000000000000000000;
    uint256 private constant _WETH =
        0x000000000000000000000000C02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 private constant _UNISWAP_PAIR_RESERVES_CALL_SELECTOR_32 =
        0x0902f1ac00000000000000000000000000000000000000000000000000000000;
    uint256 private constant _UNISWAP_PAIR_SWAP_CALL_SELECTOR_32 =
        0x022c0d9f00000000000000000000000000000000000000000000000000000000;
    uint256 private constant _DENOMINATOR = 1000000000;
    uint256 private constant _NUMERATOR_OFFSET = 160;

    // treasury
    address public treasury;
    mapping(address => uint256) public userFeeCharged;

    event FeePayed(address user, uint256 amount);
    event TreasuryChanged(address oldTreasury, address newTreasury);

    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Treasury address missing");

        address oldTreasury = treasury;
        treasury = _treasury;

        emit TreasuryChanged(oldTreasury, treasury);
    }

    function unoswapWithPermit(
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata pools,
        bytes calldata permit
    ) external payable returns (uint256 returnAmount) {
        _permit(srcToken, amount, permit);
        return unoswap(srcToken, amount, minReturn, pools);
    }

    function unoswap(
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata /* pools */
    ) public payable returns (uint256 returnAmount) {
        assembly {
            // solhint-disable-line no-inline-assembly
            function reRevert() {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            function revertWithReason(m, len) {
                mstore(
                    0,
                    0x08c379a000000000000000000000000000000000000000000000000000000000
                )
                mstore(
                    0x20,
                    0x0000002000000000000000000000000000000000000000000000000000000000
                )
                mstore(0x40, m)
                revert(0, len)
            }

            function swap(emptyPtr, swapAmount, pair, reversed, numerator, dst)
                -> ret
            {
                mstore(emptyPtr, _UNISWAP_PAIR_RESERVES_CALL_SELECTOR_32)
                if iszero(
                    staticcall(gas(), pair, emptyPtr, 0x4, emptyPtr, 0x40)
                ) {
                    reRevert()
                }

                let reserve0 := mload(emptyPtr)
                let reserve1 := mload(add(emptyPtr, 0x20))
                if reversed {
                    let tmp := reserve0
                    reserve0 := reserve1
                    reserve1 := tmp
                }
                ret := mul(swapAmount, numerator)
                ret := div(
                    mul(ret, reserve1),
                    add(ret, mul(reserve0, _DENOMINATOR))
                )

                mstore(emptyPtr, _UNISWAP_PAIR_SWAP_CALL_SELECTOR_32)
                switch reversed
                case 0 {
                    mstore(add(emptyPtr, 0x04), 0)
                    mstore(add(emptyPtr, 0x24), ret)
                }
                default {
                    mstore(add(emptyPtr, 0x04), ret)
                    mstore(add(emptyPtr, 0x24), 0)
                }
                mstore(add(emptyPtr, 0x44), dst)
                mstore(add(emptyPtr, 0x64), 0x80)
                mstore(add(emptyPtr, 0x84), 0)
                if iszero(call(gas(), pair, 0, emptyPtr, 0xa4, 0, 0)) {
                    reRevert()
                }
            }

            let emptyPtr := mload(0x40)
            mstore(0x40, add(emptyPtr, 0xc0))

            let poolsOffset := add(calldataload(0x64), 0x4)
            let poolsEndOffset := calldataload(poolsOffset)
            poolsOffset := add(poolsOffset, 0x20)
            poolsEndOffset := add(poolsOffset, mul(0x20, poolsEndOffset))
            let rawPair := calldataload(poolsOffset)
            switch srcToken
            case 0 {
                mstore(emptyPtr, _WETH_DEPOSIT_CALL_SELECTOR_32)
                if iszero(call(gas(), _WETH, amount, emptyPtr, 0x4, 0, 0)) {
                    reRevert()
                }

                mstore(emptyPtr, _ERC20_TRANSFER_CALL_SELECTOR_32)
                mstore(add(emptyPtr, 0x4), and(rawPair, _ADDRESS_MASK))
                mstore(add(emptyPtr, 0x24), amount)
                if iszero(call(gas(), _WETH, 0, emptyPtr, 0x44, 0, 0)) {
                    reRevert()
                }
            }
            default {
                mstore(emptyPtr, _TRANSFER_FROM_CALL_SELECTOR_32)
                mstore(add(emptyPtr, 0x4), caller())
                mstore(add(emptyPtr, 0x24), and(rawPair, _ADDRESS_MASK))
                mstore(add(emptyPtr, 0x44), amount)
                if iszero(call(gas(), srcToken, 0, emptyPtr, 0x64, 0, 0)) {
                    reRevert()
                }
            }

            returnAmount := amount

            for {
                let i := add(poolsOffset, 0x20)
            } lt(i, poolsEndOffset) {
                i := add(i, 0x20)
            } {
                let nextRawPair := calldataload(i)

                returnAmount := swap(
                    emptyPtr,
                    returnAmount,
                    and(rawPair, _ADDRESS_MASK),
                    and(rawPair, _REVERSE_MASK),
                    shr(_NUMERATOR_OFFSET, and(rawPair, _NUMERATOR_MASK)),
                    and(nextRawPair, _ADDRESS_MASK)
                )

                rawPair := nextRawPair
            }

            switch and(rawPair, _WETH_MASK)
            case 0 {
                returnAmount := swap(
                    emptyPtr,
                    returnAmount,
                    and(rawPair, _ADDRESS_MASK),
                    and(rawPair, _REVERSE_MASK),
                    shr(_NUMERATOR_OFFSET, and(rawPair, _NUMERATOR_MASK)),
                    caller()
                )
            }
            default {
                returnAmount := swap(
                    emptyPtr,
                    returnAmount,
                    and(rawPair, _ADDRESS_MASK),
                    and(rawPair, _REVERSE_MASK),
                    shr(_NUMERATOR_OFFSET, and(rawPair, _NUMERATOR_MASK)),
                    address()
                )

                mstore(emptyPtr, _WETH_WITHDRAW_CALL_SELECTOR_32)
                mstore(add(emptyPtr, 0x04), returnAmount)
                if iszero(call(gas(), _WETH, 0, emptyPtr, 0x24, 0, 0)) {
                    reRevert()
                }

                if iszero(call(gas(), caller(), returnAmount, 0, 0, 0, 0)) {
                    reRevert()
                }
            }

            if lt(returnAmount, minReturn) {
                revertWithReason(
                    0x000000164d696e2072657475726e206e6f742072656163686564000000000000,
                    0x5a
                ) // "Min return not reached"
            }
        }

        uint256 fee = srcToken != IERC20(0) ? msg.value : msg.value - amount;
        safeTransferETH(treasury, fee);

        emit FeePayed(msg.sender, fee);
    }

    /**
     * @dev Transfer eth
     * @param _to     receipnt address
     * @param _value  amount
     */
    function safeTransferETH(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        require(success, "SafeTransferETH: ETH transfer failed");
    }
}
