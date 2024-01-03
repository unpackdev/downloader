// File: @opengsn/gsn/contracts/interfaces/IRelayRecipient.sol

// SPDX-License-Identifier:MIT
pragma solidity ^0.5.12;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
contract IRelayRecipient {
    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public view returns (bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal view returns (bytes memory);

    function versionRecipient() external view returns (string memory);
}

// File: @opengsn/gsn/contracts/BaseRelayRecipient.sol

// SPDX-License-Identifier:MIT
// solhint-disable no-inline-assembly
pragma solidity ^0.5.12;

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
contract BaseRelayRecipient is IRelayRecipient {
    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal view returns (bytes memory ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // we copy the msg.data , except the last 20 bytes (and update the total length)
            assembly {
                let ptr := mload(0x40)
                // copy only size-20 bytes
                let size := sub(calldatasize(), 20)
                // structure RLP data as <offset> <length> <bytes>
                mstore(ptr, 0x20)
                mstore(add(ptr, 32), size)
                calldatacopy(add(ptr, 64), 0, size)
                return(ptr, add(size, 64))
            }
        } else {
            return msg.data;
        }
    }
}

// File: contracts/ExchangeProxyUpkaran.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// modified to support gasless and batched transaction by: yashnaman

pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

contract PoolInterface {
    function swapExactAmountIn(
        address,
        uint256,
        address,
        uint256,
        uint256
    ) external returns (uint256, uint256);

    function swapExactAmountOut(
        address,
        uint256,
        address,
        uint256,
        uint256
    ) external returns (uint256, uint256);

    function calcInGivenOut(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) public pure returns (uint256);

    function getDenormalizedWeight(address) external view returns (uint256);

    function getBalance(address) external view returns (uint256);

    function getSwapFee() external view returns (uint256);
}

contract TokenInterface {
    function balanceOf(address) public view returns (uint256);

    function allowance(address, address) public view returns (uint256);

    function approve(address, uint256) public returns (bool);

    function transfer(address, uint256) public returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) public returns (bool);

    function deposit() public payable;

    function withdraw(uint256) public;
}

interface IEIP2612LikePermit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IDAILikePermit {
    function nonces(address) external returns (uint256);

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract ExchangeProxyUpkaran is BaseRelayRecipient {
    string public versionRecipient = '1.0.0+balancer.exchangeproxy.gasless';
    struct DAILikePermit {
        // address holder;
        // address spender;
        // uint256 nonce;
        uint256 expiry;
        // bool allowed;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    struct EIP2612LikePermit {
        // address owner;
        // address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 swapAmount; // tokenInAmount / tokenOutAmount
        uint256 limitReturnAmount; // minAmountOut / maxAmountIn
        uint256 maxPrice;
    }
    struct Repay {
        address repayInToken;
        uint256 repayAmount;
        address repayTo;
    }

    TokenInterface weth;
    address private constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    constructor(address _trustedForwarder, address _weth) public {
        trustedForwarder = _trustedForwarder;
        weth = TokenInterface(_weth);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'ERR_ADD_OVERFLOW');
        return c;
    }

    function permit(address tokenIn, EIP2612LikePermit memory eip2612LikePermit)
        internal
    {
        if (
            TokenInterface(tokenIn).allowance(_msgSender(), address(this)) !=
            eip2612LikePermit.value
        ) {
            IEIP2612LikePermit(tokenIn).permit(
                _msgSender(),
                address(this),
                eip2612LikePermit.value,
                eip2612LikePermit.deadline,
                eip2612LikePermit.v,
                eip2612LikePermit.r,
                eip2612LikePermit.s
            );
        }
    }

    function permit(address tokenIn, DAILikePermit memory daiLikePermit)
        internal
    {
        if (
            TokenInterface(tokenIn).allowance(_msgSender(), address(this)) !=
            uint256(-1)
        ) {
            uint256 nonce = IDAILikePermit(tokenIn).nonces(_msgSender());
            IDAILikePermit(tokenIn).permit(
                _msgSender(),
                address(this),
                nonce,
                daiLikePermit.expiry,
                true,
                daiLikePermit.v,
                daiLikePermit.r,
                daiLikePermit.s
            );
        }
    }

    function transferFromAll(
        TokenInterface token,
        uint256 amount,
        Repay memory repay
    ) internal returns (bool) {
        if (isETH(token)) {
            weth.deposit.value(msg.value)();
        } else {
            require(
                token.transferFrom(
                    _msgSender(),
                    address(this),
                    add(amount, repay.repayAmount)
                ),
                'ERR_TRANSFER_FAILED'
            );
            if (repay.repayAmount > 0 && repay.repayInToken != address(0)) {
                require(
                    TokenInterface(repay.repayInToken).transfer(
                        repay.repayTo,
                        repay.repayAmount
                    ),
                    'ERR_TRANSFER_FAILED'
                );
            }
        }
    }

    function getBalance(TokenInterface token) internal view returns (uint256) {
        if (isETH(token)) {
            return address(this).balance;
        } else {
            return token.balanceOf(address(this));
        }
    }

    function transferAll(TokenInterface token, uint256 amount)
        internal
        returns (bool)
    {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            weth.withdraw(amount);
            (bool xfer, ) = _msgSender().call.value(amount)('');
            require(xfer, 'ERR_ETH_FAILED');
        } else {
            require(
                token.transfer(_msgSender(), amount),
                'ERR_TRANSFER_FAILED'
            );
        }
    }

    function isETH(TokenInterface token) internal pure returns (bool) {
        return (address(token) == ETH_ADDRESS);
    }

    function multihopBatchSwapExactIn(
        Swap[][] memory swapSequences,
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        Repay memory repay
    ) public payable returns (uint256 totalAmountOut) {
        transferFromAll(tokenIn, totalAmountIn, repay);

        for (uint256 i = 0; i < swapSequences.length; i++) {
            uint256 tokenAmountOut;
            for (uint256 k = 0; k < swapSequences[i].length; k++) {
                Swap memory swap = swapSequences[i][k];
                TokenInterface SwapTokenIn = TokenInterface(swap.tokenIn);
                if (k == 1) {
                    // Makes sure that on the second swap the output of the first was used
                    // so there is not intermediate token leftover
                    swap.swapAmount = tokenAmountOut;
                }

                PoolInterface pool = PoolInterface(swap.pool);
                if (SwapTokenIn.allowance(address(this), swap.pool) > 0) {
                    SwapTokenIn.approve(swap.pool, 0);
                }
                SwapTokenIn.approve(swap.pool, swap.swapAmount);
                (tokenAmountOut, ) = pool.swapExactAmountIn(
                    swap.tokenIn,
                    swap.swapAmount,
                    swap.tokenOut,
                    swap.limitReturnAmount,
                    swap.maxPrice
                );
            }
            // This takes the amountOut of the last swap
            totalAmountOut = add(tokenAmountOut, totalAmountOut);
        }

        require(totalAmountOut >= minTotalAmountOut, 'ERR_LIMIT_OUT');

        transferAll(tokenOut, totalAmountOut);
        transferAll(tokenIn, getBalance(tokenIn));
    }

    function multihopBatchSwapExactInDAILike(
        Swap[][] memory swapSequences,
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        Repay memory repay,
        DAILikePermit memory daiLikePermit
    ) public payable returns (uint256 totalAmountOut) {
        permit(address(tokenIn), daiLikePermit);
        return
            multihopBatchSwapExactIn(
                swapSequences,
                tokenIn,
                tokenOut,
                totalAmountIn,
                minTotalAmountOut,
                repay
            );
    }

    function multihopBatchSwapExactInEIP2612Like(
        Swap[][] memory swapSequences,
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        Repay memory repay,
        EIP2612LikePermit memory eip2612LikePermit
    ) public payable returns (uint256 totalAmountOut) {
        permit(address(tokenIn), eip2612LikePermit);
        return
            multihopBatchSwapExactIn(
                swapSequences,
                tokenIn,
                tokenOut,
                totalAmountIn,
                minTotalAmountOut,
                repay
            );
    }

    function multihopBatchSwapExactOut(
        Swap[][] memory swapSequences,
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint256 maxTotalAmountIn,
        Repay memory repay
    ) public payable returns (uint256 totalAmountIn) {
        transferFromAll(tokenIn, maxTotalAmountIn, repay);

        for (uint256 i = 0; i < swapSequences.length; i++) {
            uint256 tokenAmountInFirstSwap;
            // Specific code for a simple swap and a multihop (2 swaps in sequence)
            if (swapSequences[i].length == 1) {
                Swap memory swap = swapSequences[i][0];
                TokenInterface SwapTokenIn = TokenInterface(swap.tokenIn);

                PoolInterface pool = PoolInterface(swap.pool);
                if (SwapTokenIn.allowance(address(this), swap.pool) > 0) {
                    SwapTokenIn.approve(swap.pool, 0);
                }
                SwapTokenIn.approve(swap.pool, swap.limitReturnAmount);

                (tokenAmountInFirstSwap, ) = pool.swapExactAmountOut(
                    swap.tokenIn,
                    swap.limitReturnAmount,
                    swap.tokenOut,
                    swap.swapAmount,
                    swap.maxPrice
                );
            } else {
                // Consider we are swapping A -> B and B -> C. The goal is to buy a given amount
                // of token C. But first we need to buy B with A so we can then buy C with B
                // To get the exact amount of C we then first need to calculate how much B we'll need:
                uint256 intermediateTokenAmount; // This would be token B as described above
                Swap memory secondSwap = swapSequences[i][1];
                PoolInterface poolSecondSwap = PoolInterface(secondSwap.pool);
                intermediateTokenAmount = poolSecondSwap.calcInGivenOut(
                    poolSecondSwap.getBalance(secondSwap.tokenIn),
                    poolSecondSwap.getDenormalizedWeight(secondSwap.tokenIn),
                    poolSecondSwap.getBalance(secondSwap.tokenOut),
                    poolSecondSwap.getDenormalizedWeight(secondSwap.tokenOut),
                    secondSwap.swapAmount,
                    poolSecondSwap.getSwapFee()
                );

                //// Buy intermediateTokenAmount of token B with A in the first pool
                Swap memory firstSwap = swapSequences[i][0];
                TokenInterface FirstSwapTokenIn =
                    TokenInterface(firstSwap.tokenIn);
                PoolInterface poolFirstSwap = PoolInterface(firstSwap.pool);
                if (
                    FirstSwapTokenIn.allowance(address(this), firstSwap.pool) <
                    uint256(-1)
                ) {
                    FirstSwapTokenIn.approve(firstSwap.pool, uint256(-1));
                }

                (tokenAmountInFirstSwap, ) = poolFirstSwap.swapExactAmountOut(
                    firstSwap.tokenIn,
                    firstSwap.limitReturnAmount,
                    firstSwap.tokenOut,
                    intermediateTokenAmount, // This is the amount of token B we need
                    firstSwap.maxPrice
                );

                //// Buy the final amount of token C desired
                TokenInterface SecondSwapTokenIn =
                    TokenInterface(secondSwap.tokenIn);
                if (
                    SecondSwapTokenIn.allowance(
                        address(this),
                        secondSwap.pool
                    ) < uint256(-1)
                ) {
                    SecondSwapTokenIn.approve(secondSwap.pool, uint256(-1));
                }

                poolSecondSwap.swapExactAmountOut(
                    secondSwap.tokenIn,
                    secondSwap.limitReturnAmount,
                    secondSwap.tokenOut,
                    secondSwap.swapAmount,
                    secondSwap.maxPrice
                );
            }
            totalAmountIn = add(tokenAmountInFirstSwap, totalAmountIn);
        }

        require(totalAmountIn <= maxTotalAmountIn, 'ERR_LIMIT_IN');

        transferAll(tokenOut, getBalance(tokenOut));
        transferAll(tokenIn, getBalance(tokenIn));
    }

    function multihopBatchSwapExactOutDAILike(
        Swap[][] memory swapSequences,
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint256 maxTotalAmountIn,
        Repay memory repay,
        DAILikePermit memory daiLikePermit
    ) public payable returns (uint256 totalAmountIn) {
        permit(address(tokenIn), daiLikePermit);
        return
            multihopBatchSwapExactOut(
                swapSequences,
                tokenIn,
                tokenOut,
                maxTotalAmountIn,
                repay
            );
    }

    function multihopBatchSwapExactOutEIP2612Like(
        Swap[][] memory swapSequences,
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint256 maxTotalAmountIn,
        Repay memory repay,
        EIP2612LikePermit memory eip2612LikePermit
    ) public payable returns (uint256 totalAmountIn) {
        permit(address(tokenIn), eip2612LikePermit);
        return
            multihopBatchSwapExactOut(
                swapSequences,
                tokenIn,
                tokenOut,
                maxTotalAmountIn,
                repay
            );
    }

    function() external payable {}
}