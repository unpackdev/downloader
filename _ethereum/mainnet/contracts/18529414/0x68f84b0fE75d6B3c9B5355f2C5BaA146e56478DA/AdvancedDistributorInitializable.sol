// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Initializable.sol";
import "./Ownable.sol";
import "./ERC20Votes.sol";
import "./SafeERC20.sol";

import "./DistributorInitializable.sol";
import "./IAdjustable.sol";
import "./IVoting.sol";
import "./Sweepable.sol";
import "./FairQueueInitializable.sol";

/**
 * @title AdvancedDistributor
 * @notice Distributes tokens to beneficiaries with voting-while-vesting and administrative controls.
 * The contract owner can control these distribution parameters:
 * - the merkle root determining all distribution details
 * - adjustments to specific distributions
 * - the token being distributed
 * - the total amount to distribute
 * - the metadata URI
 * - the voting power of undistributed tokens
 * - the recipient of swept funds
 *
 * This contract also allows owners to perform several other admin functions
 * - updating the contract owner
 * - sweeping tokens and native currency to a recipient
 *
 * This contract tracks beneficiary voting power through an internal ERC20Votes token that cannot be transferred. The
 * beneficiary must delegate to an address to use this voting power. Their voting power decreases when the token is claimed.
 *
 * @dev Updates to the contract must follow these constraints:
 * - If a merkle root update alters the total token quantity to distribute across all users, also adjust the total value.
 *   The DistributionRecord for each beneficiary updated in the merkle root will be incorrect until a claim is executed.
 * - If the total changes, make sure to add or withdraw tokens being distributed to match the new total.
 */
abstract contract AdvancedDistributorInitializable is
    Initializable,
    Ownable,
    Sweepable,
    ERC20Votes,
    DistributorInitializable,
    IAdjustable,
    IVoting,
    FairQueueInitializable
{
    using SafeERC20 for IERC20;

    uint256 private voteFactor;

    constructor()
        ERC20Permit("Internal vote tracker")
        ERC20("Internal vote tracker", "IVT")
        Sweepable(payable(msg.sender))
    {}

    function __AdvancedDistributor_init(
        IERC20 _token,
        uint256 _total,
        string memory _uri,
        uint256 _voteFactor,
        uint256 _fractionDenominator,
        uint160 _maxDelayTime,
        uint160 _salt,
        address _owner
    ) internal onlyInitializing {
        _setSweepRecipient(payable(_owner));
        voteFactor = _voteFactor;
        emit SetVoteFactor(voteFactor);

        __Distributor_init(_token, _total, _uri, _fractionDenominator);
        __FairQueue_init(_maxDelayTime, _salt);
    }

    /**
     * convert a token quantity to a vote quantity
     */
    function tokensToVotes(uint256 tokenAmount) private view returns (uint256) {
        return (tokenAmount * voteFactor) / fractionDenominator;
    }

    // Update voting power based on distribution record initialization or claims
    function _reconcileVotingPower(address beneficiary) private {
        // current potential voting power
        uint256 currentVotes = balanceOf(beneficiary);
        // correct voting power after initialization, claim, or adjustment
        DistributionRecord memory record = records[beneficiary];
        uint256 newVotes = record.claimed >= record.total ? 0 : tokensToVotes(record.total - record.claimed);

        if (currentVotes > newVotes) {
            // reduce voting power through ERC20Votes extension
            _burn(beneficiary, currentVotes - newVotes);
        } else if (currentVotes < newVotes) {
            // increase voting power through ERC20Votes extension
            _mint(beneficiary, newVotes - currentVotes);
        }
    }

    function _initializeDistributionRecord(address beneficiary, uint256 totalAmount) internal virtual override {
        super._initializeDistributionRecord(beneficiary, totalAmount);
        _reconcileVotingPower(beneficiary);
    }

    function _executeClaim(address beneficiary, uint256 totalAmount)
        internal
        virtual
        override
        returns (uint256 _claimed)
    {
        _claimed = super._executeClaim(beneficiary, totalAmount);
        _reconcileVotingPower(beneficiary);
    }

    /**
     * @dev Adjust the quantity claimable by a user, overriding the value in the distribution record.
     *
     * Note: If used in combination with merkle proofs, adjustments to a beneficiary's total could be
     * reset by anyone to the value in the merkle leaf at any time. Update the merkle root instead.
     *
     * Amount is limited to type(uint120).max to allow each DistributionRecord to be packed into a single storage slot.
     */
    function adjust(address beneficiary, int256 amount) external onlyOwner {
        DistributionRecord memory distributionRecord = records[beneficiary];
        require(distributionRecord.initialized, "must initialize before adjusting");

        uint256 diff = uint256(amount > 0 ? amount : -amount);
        require(diff < type(uint120).max, "adjustment > max uint120");

        if (amount < 0) {
            // decreasing claimable tokens
            require(total >= diff, "decrease greater than distributor total");
            require(distributionRecord.total >= diff, "decrease greater than distributionRecord total");
            total -= diff;
            records[beneficiary].total -= uint120(diff);
            token.safeTransfer(owner(), diff);
        } else {
            // increasing claimable tokens
            total += diff;
            records[beneficiary].total += uint120(diff);
        }
        _reconcileVotingPower(beneficiary);
        emit Adjust(beneficiary, amount);
    }

    function _setToken(IERC20 _token) internal virtual {
        require(address(_token) != address(0), "token is address(0)");
        token = _token;
        emit SetToken(token);
    }

    // Set the token being distributed
    function setToken(IERC20 _token) external virtual onlyOwner {
        _setToken(_token);
    }

    function _setTotal(uint256 _total) internal virtual {
        total = _total;
        emit SetTotal(total);
    }

    // Set the total to distribute
    function setTotal(uint256 _total) external virtual onlyOwner {
        _setTotal(_total);
    }

    // Set the distributor metadata URI
    function setUri(string memory _uri) external onlyOwner {
        uri = _uri;
        emit SetUri(uri);
    }

    // set the recipient of swept funds
    function setSweepRecipient(address payable _recipient) external onlyOwner {
        _setSweepRecipient(_recipient);
    }

    function getTotalVotes() external view returns (uint256) {
        // supply of internal token used to track voting power
        return totalSupply();
    }

    function getVoteFactor(address) external view returns (uint256) {
        return voteFactor;
    }

    /**
     * @notice Set the voting power of undistributed tokens
     * @param _voteFactor The voting power multiplier as a fraction of fractionDenominator
     * @dev The vote factor can be any integer. If voteFactor / fractionDenominator == 1,
     * one unclaimed token provides one vote. If voteFactor / fractionDenominator == 2, one
     * unclaimed token counts as two votes.
     */
    function setVoteFactor(uint256 _voteFactor) external onlyOwner {
        voteFactor = _voteFactor;
        emit SetVoteFactor(voteFactor);
    }

    /**
     * @dev the internal token used only for tracking voting power cannot be transferred
     */
    function _approve(address, address, uint256) internal pure override {
        revert("disabled for voting power");
    }

    /**
     * @dev the internal token used only for tracking voting power cannot be transferred
     */
    function _transfer(address, address, uint256) internal pure override {
        revert("disabled for voting power");
    }
}
