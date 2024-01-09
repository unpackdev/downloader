// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IVestedNil.sol";
import "./IMasterMint.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context, Ownable {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _ethTotalShares;
    uint256 private _erc20TotalShares;

    uint256 private _ethTotalReleased;
    // uint256 private _erc20TotalReleased;

    IVestedNil public immutable vNil;
    IMasterMint public immutable masterMint;

    mapping(address => uint256) private _ethShares;
    mapping(address => uint256) private _erc20Shares;

    mapping(address => uint256) private _ethReleased;

    address[] private _ethPayees;
    address[] private _erc20Payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(
        address[] memory ethPayees,
        uint256[] memory ethShares_,
        address[] memory erc20Payees,
        uint256[] memory erc20Shares_,
        address vNilAddress_,
        address masterMintAddress_
    ) payable {
        require(ethPayees.length == ethShares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(erc20Payees.length == erc20Shares_.length, "PaymentSplitter: payees and shares length mismatch");

        require(ethPayees.length > 0, "PaymentSplitter: no payees");
        require(erc20Payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < ethPayees.length; i++) {
            _addEthPayee(ethPayees[i], ethShares_[i]);
        }

        for (uint256 i = 0; i < erc20Payees.length; i++) {
            _addErc20Payee(erc20Payees[i], erc20Shares_[i]);
        }

        vNil = IVestedNil(vNilAddress_);
        masterMint = IMasterMint(masterMintAddress_);
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function ethTotalShares() public view returns (uint256) {
        return _ethTotalShares;
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function erc20TotalShares() public view returns (uint256) {
        return _erc20TotalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function ethTotalReleased() public view returns (uint256) {
        return _ethTotalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function erc20TotalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of ETH shares held by an account.
     */
    function ethShares(address account) public view returns (uint256) {
        return _ethShares[account];
    }

    /**
     * @dev Getter for the amount of ERC20 shares held by an account.
     */
    function erc20Shares(address account) public view returns (uint256) {
        return _erc20Shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function ethReleased(address account) public view returns (uint256) {
        return _ethReleased[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function erc20Released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function ethPayee(uint256 index) public view returns (address) {
        return _ethPayees[index];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function erc20Payee(uint256 index) public view returns (address) {
        return _erc20Payees[index];
    }

    /**
     * @dev Claim Nil tokens.
     */
    function claimvNil() public {
        vNil.claim(address(this));
    }

    /**
     * @dev Track how many vNil tokens can be claimed.
     */
    function vNilClaimableOf() public view returns (uint256) {
        return vNil.claimableOf(address(this));
    }

    /**
     * @dev Withdraw all Nil proceeds.
     * mintId Id of the collection in the Nil register.
     * withNil vNil should be included or not.
     */
    function withdrawNilProceeds(uint256 mintId, bool withNil) public {
        masterMint.creatorWithdraw(mintId, withNil);
    }

    /**
     * @dev Set new owner on Nil collection.
     * mintId Id of the collection in the Nil register.
     * newCreator the address of the new collection owner.
     */
    function setNilCollectionOwner(uint256 mintId, address newCreator) public onlyOwner {
        masterMint.setMintCreator(mintId, newCreator);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_ethShares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + ethTotalReleased();
        uint256 payment = _ethPendingPayment(account, totalReceived, ethReleased(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _ethReleased[account] += payment;
        _ethTotalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_erc20Shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + erc20TotalReleased(token);
        uint256 payment = _erc20PendingPayment(account, totalReceived, erc20Released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _ethPendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _ethShares[account]) / _ethTotalShares - alreadyReleased;
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _erc20PendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _erc20Shares[account]) / _erc20TotalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee for ETH to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addEthPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_ethShares[account] == 0, "PaymentSplitter: account already has shares");

        _ethPayees.push(account);
        _ethShares[account] = shares_;
        _ethTotalShares = _ethTotalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    /**
     * @dev Add a new payee for ERC20 tokens to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addErc20Payee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_erc20Shares[account] == 0, "PaymentSplitter: account already has shares");

        _erc20Payees.push(account);
        _erc20Shares[account] = shares_;
        _erc20TotalShares = _erc20TotalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}
