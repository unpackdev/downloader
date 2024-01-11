// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./IERC721Metadata.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./DecimalConvert.sol";
import "./IIRO.sol";

/// Introducing RealEstate OnChain
/// Tracks commitments and distributions from a successful IRO
contract IRO is IIRO, Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using DecimalConvert for uint256;

    /// Emitted for each commit
    event Commit(address indexed addr, uint256 amount);
    /// Funding token refunded
    event Refund(address indexed addr, uint256 amount);
    /// Listing token withdrawn
    event WithdrawTokens(address indexed addr, uint256 amount);
    /// Funding token withdrawn
    event WithdrawFunds(address indexed addr, uint256 amount);

    IERC20MetadataUpgradeable public fundingToken; // ERC20 token used for funding

    uint256 public softCap; // minimum required to succeed
    uint256 public hardCap; // maximum allowed to be committed
    address public escrow; // on success, only this address can claim funds
    uint256 public fundingDeadline; // if non-zero, when funding period ends
    uint256 public expiryDeadline; // if non-zero, when nft must be attached
    uint256 public committed; // amount committed
    mapping(address => uint256) internal _walletCommitAmounts; // total amount by address
    bool internal _escrowWithdrawn; //has escrow withdrawn committed funds?

    // ERC20 token (fractions) used for distributions.
    // Set after NFT has been presented and distributions can start
    IERC20MetadataUpgradeable public listingToken;

    modifier onlyStatus(IIRO.Status s) {
        require(status() == s, "BAD_STATUS");
        _;
    }

    function initialize(
        IERC20MetadataUpgradeable _fundingToken,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _fundingDurationSeconds,
        uint256 _expiryDurationSeconds,
        address _escrow
    ) public {
        require(
            _fundingDurationSeconds < _expiryDurationSeconds,
            "INVALID_DURATIONS"
        );
        require(_softCap <= _hardCap, "INVALID_CAPS");
        OwnableUpgradeable.__Ownable_init();
        escrow = _escrow;
        fundingToken = _fundingToken;
        softCap = _softCap;
        hardCap = _hardCap;
        fundingDeadline = block.timestamp + _fundingDurationSeconds;
        expiryDeadline = block.timestamp + _expiryDurationSeconds;
        committed = 0;
    }

    function status() public view override returns (Status s) {
        if (block.timestamp < fundingDeadline) {
            s = Status.FUNDING;
        } else if (committed < softCap) {
            s = Status.FAILED;
        } else if (address(listingToken) == address(0)) {
            if (block.timestamp < expiryDeadline) {
                s = Status.AWAITING_TOKENS;
            } else {
                s = Status.FAILED;
            }
        } else {
            s = Status.DISTRIBUTION;
        }
    }

    /// Commit to IRO, capped to remaining hardCap
    function commit(uint256 amount) public onlyStatus(Status.FUNDING) {
        require(amount > 0, "NO_COMMIT");

        // Cap contribution to remaining goal
        uint256 remaining = hardCap - committed;

        if (amount > remaining) {
            amount = remaining;
        }

        // Record commitment
        committed = committed + amount;
        _walletCommitAmounts[msg.sender] += amount;

        fundingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Commit(msg.sender, amount);
    }

    /// Enables distribution (called from parent contract only)
    function enableDistribution(IERC20MetadataUpgradeable _listingToken)
        public
        override
        onlyStatus(Status.AWAITING_TOKENS)
        onlyOwner
    {
        require(address(_listingToken) != address(0), "BAD_LISTINGTOKEN");

        listingToken = _listingToken;
    }

    /// In the event of a failed IRO (softCap not hit within the 28-day window),
    /// withdraw committed funds in the event IRO fails to hit the target in the
    /// 28 day window.
    function withdrawRefunds() public onlyStatus(Status.FAILED) {
        uint256 amount = _walletCommitAmounts[msg.sender];
        _walletCommitAmounts[msg.sender] = 0;

        fundingToken.safeTransfer(msg.sender, amount);

        emit Refund(msg.sender, amount);
    }

    /// Withdraw committed funds and vendor committed tokens upon a successful IRO
    function escrowWithdrawal() public onlyStatus(Status.DISTRIBUTION) {
        require(msg.sender == escrow, "NOT_ESCROW");
        require(_escrowWithdrawn == false, "ESCROW_ALREADY_WITHDRAWN");

        _escrowWithdrawn = true;

        // vendor commitment tokens
        uint256 remainingFunding = hardCap - committed;

        fundingToken.safeTransfer(escrow, committed);

        uint256 listingOwed = remainingFunding.convertDecimal(
            fundingToken.decimals(),
            listingToken.decimals()
        );

        if (remainingFunding > 0) {
            listingToken.safeTransfer(escrow, listingOwed);
        }

        emit WithdrawFunds(escrow, committed);
        emit WithdrawTokens(escrow, listingOwed);
    }

    /// Withdraw distributed property tokens upon a successful IRO
    function withdrawTokens() public onlyStatus(Status.DISTRIBUTION) {
        uint256 amount = _walletCommitAmounts[msg.sender];
        require(amount > 0, "NO_COMMITMENTS_OR_ALREADY_DISTRIBUTED");

        _walletCommitAmounts[msg.sender] = 0;

        uint256 listingAmount = amount.convertDecimal(
            fundingToken.decimals(),
            listingToken.decimals()
        );

        listingToken.safeTransfer(msg.sender, listingAmount);

        emit WithdrawTokens(msg.sender, listingAmount);
    }
}
