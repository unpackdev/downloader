// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./EnumerableSet.sol";
import "./Proxied.sol";
import "./ILinearVestingHub.sol";
import "./SVesting.sol";
import "./VestingFormulaFunctions.sol";

interface IToken {
    function getCurrentVotes(address account_) external view returns (uint96);
}

interface ITokenSale {
    function gelLockedByWhale(address whale_) external view returns (uint256);
}

contract LinearVestingHubSnapshot is Proxied {
    using EnumerableSet for EnumerableSet.AddressSet;

    // solhint-disable-next-line var-name-mixedcase
    ILinearVestingHub public immutable LINEAR_VESTING_HUB;

    // solhint-disable-next-line var-name-mixedcase
    ITokenSale public immutable TOKEN_SALE;

    // delegate => List of receivers who delegated their tokens to delegate
    mapping(address => EnumerableSet.AddressSet) internal _receiversByDelegate;
    // receivers => delegate
    mapping(address => address) public delegateByReceiver;

    modifier onlyProxyAdminOrReceiver(address _receiver) {
        require(
            msg.sender == _proxyAdmin() || msg.sender == _receiver,
            "LinearVestingHubSnapshot:: only owner or receiver"
        );
        _;
    }

    constructor(ILinearVestingHub linearVestingHub_, ITokenSale tokenSale_) {
        LINEAR_VESTING_HUB = linearVestingHub_;
        TOKEN_SALE = tokenSale_;
    }

    /// @notice Adds a vestedTokenOwners delegation to a delegate
    /// @param vestedTokenOwner_ Account to that has vested tokens which wants to add its delegation
    /// @param delegate_ Account which should receive the delegated TOKEN voting power
    function setDelegate(address vestedTokenOwner_, address delegate_)
        external
        onlyProxyAdminOrReceiver(vestedTokenOwner_)
    {
        require(
            delegate_ != address(0),
            "LinearVestingHubSnapshot:: cannot remove delegate_"
        );

        // Get tokens locked in LinearVestingHub
        uint256 nextVestingId = LINEAR_VESTING_HUB.nextVestingIdByReceiver(
            vestedTokenOwner_
        );

        uint256 amount;
        for (uint256 i = 0; i < nextVestingId; i++) {
            amount += getVestingBalance(vestedTokenOwner_, i);
        }

        require(
            amount > 0,
            "LinearVestingHubSnapshot:: no vested tokens avail for delegation"
        );

        // Check if receiver already delegated, if so, remove old delegation
        address oldDelegate = delegateByReceiver[vestedTokenOwner_];
        if (oldDelegate != address(0)) {
            // Remove old delegate
            _receiversByDelegate[oldDelegate].remove(vestedTokenOwner_);
            delete delegateByReceiver[vestedTokenOwner_];
        }

        // Add new delegation
        _receiversByDelegate[delegate_].add(vestedTokenOwner_);
        delegateByReceiver[vestedTokenOwner_] = delegate_;
    }

    /// @notice Removes a vestedTokenOwners delegation
    /// @param vestedTokenOwner_ Account to that has vested tokens which wants to remove its delegation
    function removeDelegate(address vestedTokenOwner_)
        external
        onlyProxyAdminOrReceiver(vestedTokenOwner_)
    {
        address delegate = delegateByReceiver[vestedTokenOwner_];
        require(
            delegate != address(0),
            "LinearVestingHubSnapshot:: No delegate set"
        );
        require(
            _receiversByDelegate[delegate].contains(vestedTokenOwner_),
            "LinearVestingHubSnapshot:: Can only have one receiver mapped to delegate"
        );

        // Remove delegation
        delete delegateByReceiver[vestedTokenOwner_];
        _receiversByDelegate[delegate].remove(vestedTokenOwner_);
    }

    /// @notice Helper func used in TOKEN Snapshot voting to derive the total voting power of an address
    /// @param account_ Account to check total TOKEN voting power for
    function balanceOf(address account_)
        external
        view
        returns (uint256 balance)
    {
        // 1. Add tokens delegated in Vesting Hub
        balance = getVestingHubDelegations(account_);

        // 2. Add tokens delegated in TOKEN token contract
        balance += IToken(address(LINEAR_VESTING_HUB.TOKEN())).getCurrentVotes(
            account_
        );

        // 3. Add whale pool balance
        balance += TOKEN_SALE.gelLockedByWhale(account_);
    }

    /// @notice Get total amount of TOKEN delegated to an account_ on Linear Vesting Hub
    /// @param account_ Account to check total delegated TOKEN voting power in LVH
    function getVestingHubDelegations(address account_)
        public
        view
        returns (uint256 balance)
    {
        address[] memory receivers = getReceiversByDelegate(account_);

        if (receivers.length > 0) {
            for (uint256 i; i < receivers.length; i++) {
                address receiver = receivers[i];
                uint256 nextVestingId = LINEAR_VESTING_HUB
                    .nextVestingIdByReceiver(receiver);

                for (uint256 j = 0; j < nextVestingId; j++) {
                    balance += getVestingBalance(receiver, j);
                }
            }
        }
    }

    /// @notice Helper func to get all receivers that delegated to a certain address
    /// @param delegate_ Delegate for locked receiver tokens
    function getReceiversByDelegate(address delegate_)
        public
        view
        returns (address[] memory)
    {
        uint256 length = _receiversByDelegate[delegate_].length();
        address[] memory receivers = new address[](length);

        for (uint256 i; i < length; i++) {
            receivers[i] = _receiversByDelegate[delegate_].at(i);
        }
        return receivers;
    }

    function getVestingBalance(address receiver_, uint256 vestingId_)
        public
        view
        returns (uint256)
    {
        try
            LINEAR_VESTING_HUB.vestingsByReceiver(receiver_, vestingId_)
        returns (Vesting memory vesting) {
            return vesting.receiver != address(0) ? vesting.tokenBalance : 0;
        } catch {
            return 0;
        }
    }
}
