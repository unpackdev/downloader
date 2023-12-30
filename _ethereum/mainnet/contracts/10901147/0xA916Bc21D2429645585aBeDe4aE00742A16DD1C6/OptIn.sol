// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IOptIn.sol";

contract OptIn is IOptIn, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    event OptedIn(address account, address to);
    event OptedOut(address account, address to);

    // Indicates whether the contract is in boost-mode or not. Upon first deploy,
    // it has to be activated by the owner of the contract. Once activated,
    // it cannot be deactivated again and the owner automatically renounces ownership
    // leaving the contract without an owner.
    //
    // Boost mode means that contracts who leverage opt-in functionality can impose more constraints on
    // how users perform state changes in order to e.g. provide better services off-chain.
    bool private _permaBoostActive;

    // The opt-out period is 1 day (in seconds).
    uint32 private constant _OPT_OUT_PERIOD = 86400;

    // The address every account is opted-in to by default
    address private immutable _defaultOptInAddress;

    // For each account, a mapping to a boolean indicating whether they
    // did anything that deviates from the default state or not. Used to
    // minimize reads when nothing changed.
    mapping(address => bool) private _dirty;

    // For each account, a mapping to the address it is opted-in.
    // By default every account is opted-in to `defaultOptInAddress`. Any account can opt-out
    // at any time and opt-in to a different address.
    // These non-default addresses are tracked in this mapping.
    mapping(address => address) private _optedIn;

    // A map containing all opted-in addresses that are
    // waiting to be opted-out. They are still considered opted-in
    // until the time period passed.
    // We store the timestamp of when the opt-out was initiated. An address
    // is considered opted-out when `optOutTimestamp + _optOutPeriod < block.timestamp` yields true.
    mapping(address => uint256) private _optOutPending;

    constructor(address defaultOptInAddress) public Ownable() {
        _defaultOptInAddress = defaultOptInAddress;
    }

    function getPermaBoostActive() public view returns (bool) {
        return _permaBoostActive;
    }

    /**
     * @dev Activate the perma-boost and renounce ownership leaving the contract
     * without an owner. This will irrevocably change the behavior of dependent-contracts.
     */
    function activateAndRenounceOwnership() external onlyOwner {
        _permaBoostActive = true;
        renounceOwnership();
    }

    /**
     * @dev Returns the opt-out period.
     */
    function getOptOutPeriod() external pure returns (uint32) {
        return _OPT_OUT_PERIOD;
    }

    /**
     * @dev Returns the address `account` opted-in to if any.
     */
    function getOptedInAddressOf(address account)
        public
        view
        returns (address)
    {
        (, address optedInTo, ) = _getOptInStatus(account);
        return optedInTo;
    }

    /**
     * @dev Get the OptInStatus for two accounts at once.
     */
    function getOptInStatusPair(address accountA, address accountB)
        external
        override
        view
        returns (OptInStatus memory, OptInStatus memory)
    {
        (bool isOptedInA, address optedInToA, ) = _getOptInStatus(accountA);
        (bool isOptedInB, address optedInToB, ) = _getOptInStatus(accountB);

        bool permaBoostActive = _permaBoostActive;

        return (
            OptInStatus({
                isOptedIn: isOptedInA,
                optedInTo: optedInToA,
                permaBoostActive: permaBoostActive,
                optOutPeriod: _OPT_OUT_PERIOD
            }),
            OptInStatus({
                isOptedIn: isOptedInB,
                optedInTo: optedInToB,
                permaBoostActive: permaBoostActive,
                optOutPeriod: _OPT_OUT_PERIOD
            })
        );
    }

    /**
     * @dev Use this function to get the opt-in status of a given address.
     * Returns to the caller an `OptInStatus` object that also contains whether
     * the permaboost is active or not (e.g. to create pending ops).
     */
    function getOptInStatus(address account)
        external
        override
        view
        returns (OptInStatus memory)
    {
        (bool optedIn, address optedInTo, ) = _getOptInStatus(account);

        return
            OptInStatus({
                isOptedIn: optedIn,
                optedInTo: optedInTo,
                permaBoostActive: _permaBoostActive,
                optOutPeriod: _OPT_OUT_PERIOD
            });
    }

    /**
     * @dev Opts in the caller.
     * @param to the address to opt-in to
     */
    function optIn(address to) external {
        require(to != address(0), "OptIn: address cannot be zero");
        require(to != msg.sender, "OptIn: cannot opt-in to self");
        require(
            !address(msg.sender).isContract(),
            "OptIn: sender is a contract"
        );
        require(
            msg.sender != _defaultOptInAddress,
            "OptIn: default address cannot opt-in"
        );
        (bool optedIn, , ) = _getOptInStatus(msg.sender);
        require(!optedIn, "OptIn: sender already opted-in");

        _optedIn[msg.sender] = to;

        // Always > 0 since by default anyone is opted-in
        _optOutPending[msg.sender] = 0;

        emit OptedIn(msg.sender, to);
    }

    /**
     * @dev Returns the remaining opt-out period (in seconds, if any) for the given `account`.
     * A return value > 0 means that `account` opted-in, then opted-out and is
     * still considered opted-in for the remaining period. If the return value is 0, then `account`
     * could be either: opted-in or not, but guaranteed to not be pending.
     */
    function getPendingOptOutRemaining(address account)
        external
        view
        returns (uint256)
    {
        bool dirty = _dirty[account];

        uint256 optOutPeriodRemaining = _getOptOutPeriodRemaining(
            account,
            dirty
        );
        return optOutPeriodRemaining;
    }

    function _getOptInStatus(address account)
        internal
        view
        returns (
            bool, // isOptedIn
            address, // optedInTo
            bool // dirty
        )
    {
        bool dirty = _dirty[account];
        // Take a shortcut if `account` never changed anything
        if (!dirty) {
            return (
                true, /* isOptedIn */
                _defaultOptInAddress,
                dirty
            );
        }

        address optedInTo = _getOptedInTo(account, dirty);

        // Returns 0 if `account` never opted-out or opted-in again (which resets `optOutPending`).
        uint256 optOutStartedAt = _optOutPending[account];
        bool optOutPeriodActive = block.timestamp <
            optOutStartedAt + _OPT_OUT_PERIOD;

        if (optOutStartedAt == 0 || optOutPeriodActive) {
            return (true, optedInTo, dirty);
        }

        return (false, address(0), dirty);
    }

    /**
     * @dev Returns the remaining opt-out period of `account` relative to the given
     * `optedInTo` address.
     */
    function _getOptOutPeriodRemaining(address account, bool dirty)
        private
        view
        returns (uint256)
    {
        if (!dirty) {
            // never interacted with opt-in contract
            return 0;
        }

        uint256 optOutPending = _optOutPending[account];
        if (optOutPending == 0) {
            // Opted-out and/or opted-in again to someone else
            return 0;
        }

        uint256 optOutPeriodEnd = optOutPending + _OPT_OUT_PERIOD;
        if (block.timestamp >= optOutPeriodEnd) {
            // Period is over
            return 0;
        }

        // End is still in the future, so the difference to block.timestamp is the remaining
        // duration in seconds.
        return optOutPeriodEnd - block.timestamp;
    }

    function _getOptedInTo(address account, bool dirty)
        internal
        view
        returns (address)
    {
        if (!dirty) {
            return _defaultOptInAddress;
        }

        // Might be dirty, but never opted-in to someone else and/or simply pending.
        // We need to return the default address if the mapping is zero.
        address optedInTo = _optedIn[account];
        if (optedInTo == address(0)) {
            return _defaultOptInAddress;
        }

        return optedInTo;
    }

    /**
     * @dev Opts out the caller. The opt-out does not immediately take effect.
     * Instead, the caller is marked pending and only after a 30-day period ended since
     * the call to this function he is no longer considered opted-in.
     *
     * Requirements:
     *
     * - the caller is opted-in
     */
    function optOut() external {
        (bool isOptedIn, address optedInTo, ) = _getOptInStatus(msg.sender);

        require(isOptedIn, "OptIn: sender not opted-in");
        require(
            _optOutPending[msg.sender] == 0,
            "OptIn: sender not opted-in or opt-out pending"
        );

        _optOutPending[msg.sender] = block.timestamp;

        // NOTE: we do not delete the `optedInTo` address yet, because we still need it
        // for e.g. checking `isOptedInBy` while the opt-out period is not over yet.

        emit OptedOut(msg.sender, optedInTo);

        _dirty[msg.sender] = true;
    }

    /**
     * @dev An opted-in address can opt-out an `account` instantly, so that the opt-out period
     * is skipped.
     */
    function instantOptOut(address account) external {
        (bool isOptedIn, address optedInTo, bool dirty) = _getOptInStatus(
            account
        );

        require(
            isOptedIn,
            "OptIn: cannot instant opt-out not opted-in account"
        );
        require(
            optedInTo == msg.sender,
            "OptIn: account must be opted-in to msg.sender"
        );

        emit OptedOut(account, msg.sender);

        // To make the opt-out happen instantly, subtract the waiting period of `msg.sender` from `block.timestamp` -
        // effectively making `account` having waited for the opt-out period time.
        _optOutPending[account] = block.timestamp - _OPT_OUT_PERIOD - 1;

        if (!dirty) {
            _dirty[account] = true;
        }
    }

    /**
     * @dev Check if the given `_sender` has been opted-in by `_account` and that `_account`
     * is still opted-in.
     *
     * Returns a tuple (bool,uint256) where the latter is the optOutPeriod of the address
     * `account` is opted-in to.
     */
    function isOptedInBy(address _sender, address _account)
        external
        override
        view
        returns (bool, uint256)
    {
        require(_sender != address(0), "OptIn: sender cannot be zero address");
        require(
            _account != address(0),
            "OptIn: account cannot be zero address"
        );

        (bool isOptedIn, address optedInTo, ) = _getOptInStatus(_account);
        if (!isOptedIn || _sender != optedInTo) {
            return (false, 0);
        }

        return (true, _OPT_OUT_PERIOD);
    }
}
