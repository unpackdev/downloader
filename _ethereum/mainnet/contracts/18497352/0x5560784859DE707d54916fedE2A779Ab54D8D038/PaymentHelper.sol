// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./IPaymentSplitter.sol";

struct TokenPayment {
    address token;
    uint256 amount;
}

interface ICollectionPaymentReader {
    function paymentSplitter() external view returns (IPaymentSplitter);
    function paymentSplitterRoyalties() external view returns (IPaymentSplitter);
}

/**
 * @notice Helper functions for claiming payments.
 * @dev This is intentionally agnostic from Alba and should be independently replaceable
 * for another solution later if needed.
 */
contract PaymentHelper {
    event PaymentsClaimed(address indexed collection, address user);

    /**
     * @notice Returns the payment splitters for a collection.
     */
    function splittersForCollection(address collection) internal view returns (IPaymentSplitter, IPaymentSplitter) {
        IPaymentSplitter paymentSplitter = ICollectionPaymentReader(collection).paymentSplitter();
        IPaymentSplitter paymentSplitterRoyalties = ICollectionPaymentReader(collection).paymentSplitterRoyalties();

        return (paymentSplitter, paymentSplitterRoyalties);
    }

    /**
     * @notice Returns the amount of ETH that can be claimed by the caller for a collection.
     * @return (primaryEth, secondaryEth) amounts.
     */
    function availableETH(address collection) public view returns (uint256, uint256) {
        (IPaymentSplitter paymentSplitter, IPaymentSplitter paymentSplitterRoyalties) =
            splittersForCollection(collection);

        uint256 available = paymentSplitter.releasable(msg.sender);
        uint256 availableRoyalties = 0;
        if (address(paymentSplitterRoyalties) != address(0)) {
            availableRoyalties = paymentSplitterRoyalties.releasable(msg.sender);
        }
        return (available, availableRoyalties);
    }

    /**
     * @notice Returns the amount of payments that can be claimed by the user.
     * @dev The uses msg.sender so can be called by the artist or by Alba.
     */
    function availableERC20(address collection, address[] calldata primaryTokens, address[] calldata secondaryTokens)
        public
        view
        returns (TokenPayment[] memory, TokenPayment[] memory)
    {
        TokenPayment[] memory primaryAmounts = new TokenPayment[](primaryTokens.length);
        TokenPayment[] memory secondaryAmounts = new TokenPayment[](secondaryTokens.length);

        if (primaryTokens.length == 0 && secondaryTokens.length == 0) {
            return (primaryAmounts, secondaryAmounts);
        }

        (IPaymentSplitter paymentSplitter, IPaymentSplitter paymentSplitterRoyalties) =
            splittersForCollection(collection);

        for (uint256 i = 0; i < primaryTokens.length; i++) {
            primaryAmounts[i] =
                TokenPayment(primaryTokens[i], paymentSplitter.releasable(IERC20(primaryTokens[i]), msg.sender));
        }

        for (uint256 i = 0; i < secondaryTokens.length; i++) {
            secondaryAmounts[i] = TokenPayment(
                secondaryTokens[i], paymentSplitterRoyalties.releasable(IERC20(secondaryTokens[i]), msg.sender)
            );
        }

        return (primaryAmounts, secondaryAmounts);
    }

    /**
     * @notice Convenience function to claim all payments for a collection.
     */
    function claimPayments(address collection, address[] calldata primaryTokens, address[] calldata secondaryTokens)
        external
    {
        _claimPayments(collection, primaryTokens, secondaryTokens);
    }

    /**
     * @notice Convenience function to claim all payments for multiple collections.
     * @dev To reduce gas, don't pass token addresses if there is no available balance for that token.
     */
    function claimPaymentsBatch(
        address[] calldata collections,
        address[][] calldata primaryTokens,
        address[][] calldata secondaryTokens
    ) external {
        uint256 numCollections = collections.length;
        for (uint256 i = 0; i < numCollections; i++) {
            _claimPayments(collections[i], primaryTokens[i], secondaryTokens[i]);
        }
    }

    /**
     * @notice Convenience function to claim all payments for a collection.
     * @dev This can be used by both the artist and Alba to claim their payments.
     * When upgraded to 4.8.X, we can use the `releasable` function to check payments
     * for the specific caller rather than just checking the balance.
     * Note that we don't authz as that is done by the splitters directly.
     * TODO: We can make this more gas efficient by passing flags for which splitter to claim, and doing the
     * available calls off-chain.
     */
    function _claimPayments(address collection, address[] calldata primaryTokens, address[] calldata secondaryTokens)
        internal
    {
        (IPaymentSplitter paymentSplitter, IPaymentSplitter paymentSplitterRoyalties) =
            splittersForCollection(collection);
        bool claimed = false;

        // Claim ETH payments.
        (uint256 ethPrimary, uint256 ethSecondary) = availableETH(collection);
        if (ethPrimary > 0) {
            paymentSplitter.release(payable(msg.sender));
            claimed = true;
        }
        if (ethSecondary > 0) {
            paymentSplitterRoyalties.release(payable(msg.sender));
            claimed = true;
        }

        // Claim ERC20 payments if given.
        if (primaryTokens.length != 0 || secondaryTokens.length != 0) {
            (TokenPayment[] memory primaryTokenAmounts, TokenPayment[] memory secondaryTokenAmounts) =
                availableERC20(collection, primaryTokens, secondaryTokens);

            uint256 numPrimaryTokens = primaryTokenAmounts.length;
            for (uint256 i = 0; i < numPrimaryTokens; i++) {
                if (primaryTokenAmounts[i].amount > 0) {
                    paymentSplitter.release(IERC20(primaryTokenAmounts[i].token), payable(msg.sender));
                    claimed = true;
                }
            }

            uint256 numSecondaryTokens = secondaryTokenAmounts.length;
            for (uint256 i = 0; i < numSecondaryTokens; i++) {
                if (secondaryTokenAmounts[i].amount > 0) {
                    paymentSplitterRoyalties.release(IERC20(secondaryTokenAmounts[i].token), payable(msg.sender));
                    claimed = true;
                }
            }
        }

        if (claimed) {
            emit PaymentsClaimed(collection, msg.sender);
        }
    }
}
