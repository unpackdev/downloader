// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "SafeERC20.sol";
import "ITroveManager.sol";
import "ISortedTroves.sol";
import "IBorrowerOperations.sol";

/**
    @title Mint and Repay Zap
    @notice Mint and repay mkUSD in a single transaction
    @dev Untested, unofficial, use at your own risk
 */
contract MintAndRepayZap {
    using SafeERC20 for IERC20;

    IBorrowerOperations public immutable borrowerOps;
    IERC20 public immutable debtToken;
    address public immutable tokenRecoveryReceiver;

    constructor(IBorrowerOperations _bo, IERC20 _debt) {
        borrowerOps = _bo;
        debtToken = _debt;
        tokenRecoveryReceiver = msg.sender;
    }

    function recoverToken(IERC20 token) external {
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(tokenRecoveryReceiver, amount);
    }

    function mintAndRepay(
        address troveManager,
        uint256 maxFeePercentage,
        uint256 debtChange,
        address[2] calldata mintHints,
        address[2] calldata repayHints
    ) external {
        borrowerOps.withdrawDebt(troveManager, msg.sender, maxFeePercentage, debtChange, mintHints[0], mintHints[1]);
        borrowerOps.repayDebt(troveManager, msg.sender, debtChange, repayHints[0], repayHints[1]);
    }

    /// @dev Must have at least `repayAmount` balance of mkUSD and approve the zap to transfer
    function repayAndMint(
        address troveManager,
        uint256 maxFeePercentage,
        uint256 repayAmount,
        uint256 mintAmount,
        address[2] calldata repayHints,
        address[2] calldata mintHints
    ) external {
        debtToken.transferFrom(msg.sender, address(this), repayAmount);
        borrowerOps.repayDebt(troveManager, msg.sender, repayAmount, repayHints[0], repayHints[1]);
        borrowerOps.withdrawDebt(troveManager, msg.sender, maxFeePercentage, mintAmount, mintHints[0], mintHints[1]);
        debtToken.transfer(msg.sender, mintAmount);
    }

    /// @dev call as a view method
    function getRepayAndMintHints(
        ITroveManager troveManager,
        address account,
        uint256 repayAmount,
        uint256 mintAmount
    ) external returns (address[2] memory repayHints, address[2] memory mintHints) {
        uint256 price = troveManager.fetchPrice();
        (uint256 coll, uint256 debt) = troveManager.getTroveCollAndDebt(account);
        mintAmount += troveManager.getBorrowingFee(mintAmount);
        uint256 repayCR = (coll * price) / (debt - repayAmount);
        uint256 mintCR = (coll * price) / (debt - repayAmount + mintAmount);

        repayHints = _findHintWithHigherCR(account, account, troveManager, price, repayCR);
        if (repayAmount > mintAmount) mintHints = _findHintWithHigherCR(account, account, troveManager, price, mintCR);
        else mintHints = _findHintWithLowerCR(account, account, troveManager, price, mintCR);

        return (repayHints, mintHints);
    }

    /// @dev call as a view method
    function getMintAndRepayHints(
        ITroveManager troveManager,
        address account,
        uint256 debtChange
    ) external returns (address[2] memory mintHints, address[2] memory repayHints) {
        uint256 price = troveManager.fetchPrice();
        (uint256 coll, uint256 debt) = troveManager.getTroveCollAndDebt(account);
        uint256 mintAmount = debtChange + troveManager.getBorrowingFee(debtChange);
        uint256 mintCR = (coll * price) / (debt + mintAmount);
        uint256 repayCR = (coll * price) / (debt + mintAmount - debtChange);

        mintHints = _findHintWithLowerCR(account, account, troveManager, price, mintCR);
        repayHints = _findHintWithHigherCR(account, account, troveManager, price, repayCR);

        return (mintHints, repayHints);
    }

    function _findHintWithLowerCR(
        address account,
        address traverseFrom,
        ITroveManager tm,
        uint256 price,
        uint256 collRatio
    ) internal view returns (address[2] memory hints) {
        address last = traverseFrom;
        ISortedTroves st = ISortedTroves(tm.sortedTroves());
        while (true) {
            last = st.getNext(last);
            if (last == address(0)) return [st.getLast(), st.getLast()];
            if (last == account) continue;
            if (collRatio > tm.getCurrentICR(last, price)) {
                address prev = st.getPrev(last);
                if (prev == account) prev = st.getPrev(prev);
                return [prev, last];
            }
        }
    }

    function _findHintWithHigherCR(
        address account,
        address traverseFrom,
        ITroveManager tm,
        uint256 price,
        uint256 collRatio
    ) internal view returns (address[2] memory hints) {
        address last = traverseFrom;
        ISortedTroves st = ISortedTroves(tm.sortedTroves());
        while (true) {
            last = st.getPrev(last);
            if (last == address(0)) return [st.getFirst(), st.getFirst()];
            if (collRatio < tm.getCurrentICR(last, price)) {
                address next = st.getNext(last);
                if (next == account) next = st.getNext(next);
                return [last, next];
            }
        }
    }
}
