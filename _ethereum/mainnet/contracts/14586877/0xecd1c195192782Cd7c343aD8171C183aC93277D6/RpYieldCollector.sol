// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Context.sol";
import "./Math.sol";
import "./IERC20.sol";

import "./IRaid.sol";

/**
 * @title Raid Party pending rewards batch collection
 * @author xanewok.eth
 * @dev
 *
 * Batch claiming can be optionally:
 * - (`taxed` prefix) taxed by an external entity such as guilds and/or
 * - (`To` suffix) collected into a single address to save on gas.
 *
 * Because $CFTI is an ERC-20 token, we still need to approve this contract
 * from each account where we will draw the funds from for spending in order to
 * move the funds - however, since this contract will be (probably) fully
 * authorized to manage the funds, we need to be extra careful where those funds
 * will be withdrawn.
 *
 * To address this issue, we introduce a concept of *operators* (poor man's
 * ERC-777 operators) which are authorized accounts that can act (and withdraw
 * tokens, among others) on behalf of the token *owner* accounts via this contract.
 *
 */
contract RpYieldCollector is Context, Ownable {
    uint256 public _collectedFee;
    IERC20 public immutable _confetti;
    IRaid public immutable _raid;
    uint16 public constant BP_PRECISION = 1e4;
    uint16 public _feeBasisPoints = 50; // 0.5%

    // For each account, a mapping of its operators.
    mapping(address => mapping(address => bool)) private _operators;

    constructor(address confetti, address raid) {
        _confetti = IERC20(confetti);
        _raid = IRaid(raid);
    }

    function setFee(uint16 amount) public onlyOwner {
        require(amount <= 100, "Fee is never going to be more than 1%");
        _feeBasisPoints = amount;
    }

    function withdrawFee() public onlyOwner {
        _confetti.transfer(msg.sender, _collectedFee);
        _collectedFee = 0;
    }

    /// @notice Claims RP pending rewards for each wallet in a single transaction
    function claimMultipleRewards(address[] calldata wallets) public {
        // NOTE: It's safe to simply collect pending rewards for given wallets,
        // - worst case we simply pay for their gas fees lol
        for (uint256 i = 0; i < wallets.length; i++) {
            _raid.claimRewards(wallets[i]);
        }
    }

    /// @notice Claims RP pending rewards for each wallet in a single transaction
    function taxedClaimMultipleRewards(
        address[] calldata wallets,
        uint16 taxBasisPoints,
        address taxRecipient
    ) public authorized(wallets) {
        require(
            taxBasisPoints + _feeBasisPoints <= BP_PRECISION,
            "Can't collect over 100%"
        );
        require(taxRecipient != address(0x0), "Tax recipient can't be zero");

        // Firstly, claim all the pending rewards for the wallets
        uint256 claimedRewards = getPendingRewards(wallets);
        claimMultipleRewards(wallets);

        // Secondly, collect the tax and the service fee from the rewards.
        // To save on gas, we try to minimize the amount of token transfers.
        uint256 tax = (claimedRewards * taxBasisPoints) / BP_PRECISION;
        amortizedCollectFrom(wallets, taxRecipient, tax);
        // To save on gas, fees are accumulated and pulled when needed.
        uint256 fee = (claimedRewards * _feeBasisPoints) / BP_PRECISION;
        amortizedCollectFrom(wallets, address(this), fee);
        _collectedFee += fee;
    }

    /// @dev You should read `isApproved` first to make sure each wallet has ERC20 approval
    function claimMultipleRewardsTo(
        address[] calldata wallets,
        address recipient
    ) public authorized(wallets) returns (uint256) {
        // TODO:
        uint256 totalClaimedRewards = 0;
        for (uint256 i = 0; i < wallets.length; i++) {
            uint256 pendingRewards = _raid.getPendingRewards(wallets[i]);
            totalClaimedRewards += pendingRewards;

            _raid.claimRewards(wallets[i]);
            _confetti.transferFrom(wallets[i], address(this), pendingRewards);
        }

        uint256 fee = (totalClaimedRewards * _feeBasisPoints) / BP_PRECISION;
        _confetti.transfer(recipient, totalClaimedRewards - fee);
        _collectedFee += fee;

        return totalClaimedRewards - fee;
    }

    /// @notice Claims rewards from the wallets to a single wallet, while also
    /// collecting a tax. Tax is in basis points, i.e. value of 100 means the
    /// tax is 1%, value of 10 means 0.1% etc.
    function taxedClaimMultipleRewardsTo(
        address[] calldata wallets,
        address recipient,
        uint16 taxBasisPoints,
        address taxRecipient
    ) public authorized(wallets) {
        require(
            taxBasisPoints + _feeBasisPoints <= BP_PRECISION,
            "Can't collect over 100%"
        );
        require(taxRecipient != address(0x0), "Tax recipient can't be zero");

        uint256 claimedRewards = 0;
        for (uint256 i = 0; i < wallets.length; i++) {
            uint256 pendingRewards = _raid.getPendingRewards(wallets[i]);
            claimedRewards += pendingRewards;

            _raid.claimRewards(wallets[i]);
            _confetti.transferFrom(wallets[i], address(this), pendingRewards);
        }

        uint256 tax = (claimedRewards * taxBasisPoints) / BP_PRECISION;
        uint256 fee = (claimedRewards * _feeBasisPoints) / BP_PRECISION;
        if (tax > 0) {
            _confetti.transfer(taxRecipient, tax);
        }
        _collectedFee += fee;

        // Finally, send the claimed reward to the recipient
        _confetti.transfer(recipient, claimedRewards - tax - fee);
    }

    /// @notice Bundles all of the tokens at the `recipient` address, optionally
    /// claiming any pending rewards.
    function bundleTokens(
        address[] calldata wallets,
        address recipient,
        bool alsoClaim
    ) public authorized(wallets) {
        if (alsoClaim) {
            uint256 claimedRewards = getPendingRewards(wallets);
            claimMultipleRewards(wallets);

            uint256 fee = (claimedRewards * _feeBasisPoints) / BP_PRECISION;
            amortizedCollectFrom(wallets, address(this), fee);
            _collectedFee += fee;
        }

        for (uint256 i = 0; i < wallets.length; i++) {
            if (wallets[i] != recipient) {
                uint256 amount = _confetti.balanceOf(wallets[i]);
                _confetti.transferFrom(wallets[i], recipient, amount);
            }
        }
    }

    // To minimize the amount of ERC-20 token transfers (which are costly), we
    // use a greedy algorithm of sending as much as we can until we transfer
    // a total, specified amount.
    // NOTE: The caller must ensure that wallets are safe to transfer from by the
    // transaction sender.
    function amortizedCollectFrom(
        address[] calldata wallets,
        address recipient,
        uint256 amount
    ) private {
        uint256 collected = 0;
        for (uint256 i = 0; i < wallets.length && collected < amount; i++) {
            uint256 collectedNow = Math.min(
                _confetti.balanceOf(wallets[i]),
                amount - collected
            );

            _confetti.transferFrom(wallets[i], recipient, collectedNow);
            collected += collectedNow;
        }
    }

    /// @notice Returns whether given wallets authorized this contract to move at least
    /// their current pending rewards
    function isApproved(address[] calldata wallets)
        external
        view
        returns (bool)
    {
        for (uint256 i = 0; i < wallets.length; i++) {
            uint256 pendingRewards = _raid.getPendingRewards(wallets[i]);
            if (
                _confetti.allowance(wallets[i], address(this)) < pendingRewards
            ) {
                return false;
            }
        }
        return true;
    }

    /// @notice Convenient function that returns total pending rewards for given wallets
    function getPendingRewards(address[] calldata wallets)
        public
        view
        returns (uint256)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < wallets.length; i++) {
            sum += _raid.getPendingRewards(wallets[i]);
        }
        return sum;
    }

    // Ensure that the transaction sender is authorized to move the funds
    // from these wallets
    modifier authorized(address[] calldata wallets) {
        require(
            isOperatorForWallets(_msgSender(), wallets),
            "Not authorized to manage wallets"
        );
        _;
    }

    /// @notice Returns whether the transaction sender can manage given wallets
    function isOperatorForWallets(address operator, address[] calldata wallets)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < wallets.length; i++) {
            if (!isOperatorFor(operator, wallets[i])) {
                return false;
            }
        }
        return true;
    }

    // ERC-777-inspired operators.
    function isOperatorFor(address operator, address tokenHolder)
        public
        view
        returns (bool)
    {
        return operator == tokenHolder || _operators[tokenHolder][operator];
    }

    /// @notice Authorize a given address to move funds in the name of the
    /// transaction sender.
    function authorizeOperator(address operator) public {
        require(_msgSender() != operator, "authorizing self as operator");

        _operators[_msgSender()][operator] = true;

        emit AuthorizedOperator(operator, _msgSender());
    }

    /// @notice Revoke a given address to move funds in the name of the
    /// transaction sender.
    function revokeOperator(address operator) public {
        require(operator != _msgSender(), "revoking self as operator");

        delete _operators[_msgSender()][operator];

        emit RevokedOperator(operator, _msgSender());
    }

    event AuthorizedOperator(
        address indexed operator,
        address indexed tokenHolder
    );
    event RevokedOperator(
        address indexed operator,
        address indexed tokenHolder
    );
}
