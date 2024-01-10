// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./Address.sol";

error AmountRequestedExceedsMaxSupply();
error ExceedsMaxAllowableSupply();
error MustBeGreaterThanCurrentMaxSupply();
error RaiseNotOpen();
error RaiseHasNotSucceeded();
error RefundsNotOpen();
error ValueUnchanged();
error ZeroBalance();

/**
 * @notice A representation of the state of the raise.
 *
 * @dev Definitions -
 *
 * Open: Funds are currently being accepted for minting.
 *
 * Failed: The raise was unsuccessful and refunds are open.
 *
 * Succeeded: The raise has entered a phase of success, where minting is no longer available.
 * Funds will be transferred when the appropriate destination(s) have been coordinated.
 *
 */
enum RaiseState {
    Open,
    Failed,
    Succeeded
}

/**
 * @notice A readable ERC20 token contract with mint, voting, and refund features.
 *
 *
 * Minting is public at a rate of 1:1 with ether.
 *
 * A simple 1:1 refund mechanism is in place with the following rules:
 * Refunds are open upon a failed raise, or
 * Raise is still open and the raise deadline has passed.
 *
 * @author Alpha Audits
 * https://alphaaudits.com
 * https://twitter.com/alphaaudits
 * https://alphaaudits.medium.com
 *
 */
contract ChelseaDAOERC20 is
    Ownable,
    ReentrancyGuard,
    ERC20,
    ERC20Permit,
    ERC20Votes
{
    using SafeERC20 for IERC20;

    /** @notice An upper limit on maxSupply.
     *
     * @dev Necessary for maintaining ERC20Votes compatibility
     */
    uint256 public constant MAX_ALLOWABLE_SUPPLY = 2**224 - 1;

    /**
     * @notice The maximum number of tokens available to mint.
     *
     * @dev Mutable.
     */
    uint256 public maxSupply = (2 * 1_000_000) * (10**decimals());

    /// @notice Current state. See RaiseState enum for details
    RaiseState public raiseState = RaiseState.Open;

    /**
     * @notice The deadline upon which refunds will open automatically if the raise has not succeeded.
     *
     * @dev Mutable.
     */
    // solhint-disable-next-line not-rely-on-time
    uint256 public raiseEndTimestamp = block.timestamp + 31 days;

    event RaiseStateUpdated(RaiseState oldRaiseState, RaiseState newRaiseState);
    event RaiseEndTimestampUpdated(
        uint256 oldRaiseEndTimestamp,
        uint256 newRaiseEndTimestamp
    );
    event MaxSupplyUpdated(uint256 oldMaxSupply, uint256 newMaxSupply);
    event PostSuccessEtherTransfer(address indexed to, uint256 amount);

    // solhint-disable-next-line no-empty-blocks
    constructor() ERC20("ChelseaDAO", "CFCDAO") ERC20Permit("ChelseaDAO") {}

    /**
     * @notice Use this function to obtain DAO tokens/rights at a rate of 1:1 with ether.
     */
    function mint() external payable {
        if (raiseState != RaiseState.Open) revert RaiseNotOpen();
        if (totalSupply() + msg.value > maxSupply)
            revert AmountRequestedExceedsMaxSupply();

        _mint(_msgSender(), msg.value);
    }

    /**
     * @notice Burns and returns to the user an ether amount equal to their token balance.
     *
     * @dev We transfer ether in this same transaction, taking extra care to protect against
     * reentrancy and to follow the check-effects-interaction pattern.
     */
    function refund() external nonReentrant {
        if (refundsOpen() != true) revert RefundsNotOpen();

        uint256 balance = balanceOf(_msgSender());
        if (balance == 0) revert ZeroBalance();

        _burn(_msgSender(), balance);
        Address.sendValue(payable(_msgSender()), balance);
    }

    function setRaiseState(RaiseState raiseState_) external onlyOwner {
        if (raiseState == raiseState_) revert ValueUnchanged();

        RaiseState oldRaiseState = raiseState;
        raiseState = raiseState_;

        emit RaiseStateUpdated(oldRaiseState, raiseState);
    }

    function setRaiseEndTimestamp(uint256 raiseEndTimestamp_)
        external
        onlyOwner
    {
        if (raiseEndTimestamp == raiseEndTimestamp_) revert ValueUnchanged();

        uint256 oldRaiseEndTimestamp = raiseEndTimestamp;
        raiseEndTimestamp = raiseEndTimestamp_;

        emit RaiseEndTimestampUpdated(oldRaiseEndTimestamp, raiseEndTimestamp);
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        if (maxSupply_ > MAX_ALLOWABLE_SUPPLY)
            revert ExceedsMaxAllowableSupply();
        if (maxSupply_ <= maxSupply) revert MustBeGreaterThanCurrentMaxSupply();

        uint256 oldMaxSupply = maxSupply;
        maxSupply = maxSupply_;

        emit MaxSupplyUpdated(oldMaxSupply, maxSupply);
    }

    /**
     * @notice Following a successful raise, we use this function to transfer funds to
     * seller/broker's account(s).
     */
    function postSuccessTransfer(address account, uint256 amount)
        external
        nonReentrant
        onlyOwner
    {
        if (raiseState != RaiseState.Succeeded) revert RaiseHasNotSucceeded();

        Address.sendValue(payable(account), amount);

        emit PostSuccessEtherTransfer(account, amount);
    }

    /**
     * @dev This function is public for simple inspection by dApps.
     */
    function refundsOpen() public view returns (bool open) {
        return
            raiseState == RaiseState.Failed ||
            (raiseState == RaiseState.Open &&
                block.timestamp >= raiseEndTimestamp); // solhint-disable-line not-rely-on-time
    }

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Votes)
    {
        super._mint(account, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }
}
