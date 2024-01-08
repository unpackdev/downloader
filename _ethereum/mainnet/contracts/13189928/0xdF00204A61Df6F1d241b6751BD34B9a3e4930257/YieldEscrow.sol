// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./VoteDelegator.sol";

contract YieldEscrow is Ownable, ERC20 {
    using SafeERC20 for ERC20;

    /// @notice Governance token contract.
    address public immutable governanceToken;

    address public voteDelegatorPrototype;

    /// @dev Created vote delegators by account.
    mapping(address => address) internal _voteDelegators;

    /// @dev Addresses that are allowed to transfer tokens.
    mapping(address => bool) internal _allowedTransferAddresses;

    event VoteDelegatorCreated(address indexed account, address voteDelegator);

    event VoteDelegatorDestroyed(address indexed account);

    event TransferAllowed(address indexed account);

    event TransferDenied(address indexed account);

    event Deposit(address indexed account, uint256 amount);

    event Withdraw(address indexed account, uint256 amount);

    /**
     * @param _governanceToken Governance token contract address.
     */
    constructor(address _governanceToken, address _voteDelegatorPrototype) public ERC20("BondAppetit Governance yield", "yBAG") {
        governanceToken = _governanceToken;
        voteDelegatorPrototype = _voteDelegatorPrototype;
    }

    /**
     * @param account Target account.
     * @return Address of vote delegator (zero if not delegate).
     */
    function voteDelegatorOf(address account) public view returns (address) {
        return _voteDelegators[account];
    }

    /**
     * @notice Create vote delegator contract for sender account.
     * @return Address of vote delegator.
     */
    function createVoteDelegator() external returns (address) {
        address account = _msgSender();
        address accountVoteDelegator = voteDelegatorOf(account);
        require(accountVoteDelegator == address(0), "YieldEscrow::createVoteDelegator: votes delegator already created");

        bytes20 targetBytes = bytes20(voteDelegatorPrototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            accountVoteDelegator := create(0, clone, 0x37)
        }
        _voteDelegators[account] = accountVoteDelegator;
        VoteDelegator(accountVoteDelegator).initialize(account);

        uint256 accountBalance = balanceOf(account);
        if (accountBalance > 0) {
            ERC20(governanceToken).safeTransfer(accountVoteDelegator, accountBalance);
        }
        emit VoteDelegatorCreated(account, accountVoteDelegator);

        return accountVoteDelegator;
    }

    /**
     * @notice Allow transfer tokens for account.
     * @param account Target account.
     */
    function allowTransfer(address account) external onlyOwner {
        _allowedTransferAddresses[account] = true;
        emit TransferAllowed(account);
    }

    /**
     * @notice Deny transfer tokens for account.
     * @param account Target account.
     */
    function denyTransfer(address account) external onlyOwner {
        _allowedTransferAddresses[account] = false;
        emit TransferDenied(account);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        // solhint-disable-next-line no-unused-vars
        uint256 amount
    ) internal override {
        require(
            _allowedTransferAddresses[from] ||
                _allowedTransferAddresses[to] ||
                from == address(0) || // mint
                to == address(0), // burn
            "YieldEscrow: transfer of tokens is prohibited"
        );
    }

    /**
     * @notice Deposit governance token.
     * @param amount Deposit amount.
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "YieldEscrow::deposit: negative or zero amount");
        address account = _msgSender();
        require(voteDelegatorOf(account) == address(0), "YieldEscrow::deposit: vote delegator only deposit for this account");

        ERC20(governanceToken).safeTransferFrom(account, address(this), amount);
        _mint(account, amount);
        emit Deposit(account, amount);
    }

    /**
     * @notice Deposit governance token from vote delegator only.
     * @param account Target account.
     * @param amount Deposit amount.
     */
    function depositFromDelegator(address account, uint256 amount) external {
        require(amount > 0, "YieldEscrow::depositFromDelegator: negative or zero amount");
        require(_msgSender() == voteDelegatorOf(account), "YieldEscrow::depositFromDelegator: caller is not a vote delegator");

        _mint(account, amount);
        emit Deposit(account, amount);
    }

    /**
     * @notice Withdraw governance token.
     * @param amount Withdraw amount.
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "YieldEscrow::withdraw: negative or zero amount");
        address account = _msgSender();
        require(voteDelegatorOf(account) == address(0), "YieldEscrow::withdraw: vote delegator only deposit for this account");

        _burn(account, amount);
        ERC20(governanceToken).safeTransfer(account, amount);
        emit Withdraw(account, amount);
    }

    /**
     * @notice Withdraw governance token from vote delegator only.
     * @param account Target account.
     * @param amount Withdraw amount.
     */
    function withdrawFromDelegator(address account, uint256 amount) external {
        require(amount > 0, "YieldEscrow::withdrawFromDelegator: negative or zero amount");
        require(_msgSender() == voteDelegatorOf(account), "YieldEscrow::withdrawFromDelegator: caller is not a vote delegator");

        _burn(account, amount);
        emit Withdraw(account, amount);
    }
}
