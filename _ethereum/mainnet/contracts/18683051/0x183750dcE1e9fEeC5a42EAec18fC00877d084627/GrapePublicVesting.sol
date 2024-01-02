// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./Ownable.sol";
import "./IERC20.sol";
import "./MessageHashUtils.sol";
import "./SignatureChecker.sol";

contract GrapePublicVesting is Ownable {
    /**
     * @dev Public immutable state
     */
    IERC20 public immutable grapeToken;
    uint256 public immutable tgeUnlockPercent = 25;
    uint256 public immutable bonusPercent = 10;
    address public immutable signerWallet;
    uint256 public immutable signatureValidity = 1 hours;

    /**
     * @dev Public mutable state
     */
    uint256 public tgeDate;
    uint256 public vestingEndDate;
    mapping(address investor => uint256 amountWithoutBonus) public withdraws; // managed internally

    /**
     * @notice Emitted when a investor withdraws
     */
    event Withdraw(
        address indexed investor,
        uint256 amount,
        uint256 bonusAmount
    );

    /**
     * @dev Errors
     */
    error ExpiredSignature();
    error InvalidSignature();
    error TGEPending();
    error ZeroWithdrawAmount();

    /**
     * @notice Initializes a new Grape Token Vesting contract.
     * @dev Sets up the Grape token vesting contract with the specified parameters.
     *      This includes the Grape token address, the initial owner of the contract, the TGE (Token Generation Event) date,
     *      the end date for the vesting period, and the signer wallet address.
     *      The constructor sets the initial state of the contract and transfers ownership to the specified initial owner.
     * @param grapeToken_ The address of the Grape ERC20 token that will be vested through this contract.
     * @param initialOwner_ The address of the initial owner of the contract, typically the deployer or the main administrative account.
     * @param tgeDate_ The date of the Token Generation Event (TGE), represented as a Unix timestamp,
     *        indicating when token distribution begins.
     * @param vestingEndDate_ The end date of the vesting period, represented as a Unix timestamp.
     * @param signerWallet_ The address of the wallet used for signing transactions or authorizations related to this contract.
     */
    constructor(
        address grapeToken_,
        address initialOwner_,
        uint256 tgeDate_,
        uint256 vestingEndDate_,
        address signerWallet_
    ) Ownable(initialOwner_) {
        grapeToken = IERC20(grapeToken_);
        tgeDate = tgeDate_;
        vestingEndDate = vestingEndDate_;
        signerWallet = signerWallet_;
    }

    /**
     * @dev Public functions
     */

    /**
     * @notice Calculates the amount of tokens that have vested for a user based on their NFT and referral purchases.
     * @dev This function computes the vested token amount using a linear vesting schedule. It takes into account
     *      both NFT and referral purchases. The vested amount depends on whether the cliff period has ended and
     *      if the vesting period is still ongoing.
     *      - If the cliff period (TGE date) hasn't started, no tokens are vested.
     *      - If the vesting period has ended, the total of NFT and referral purchases is returned.
     *      - Otherwise, a linear vesting calculation is applied.
     * @param nftAmountPurchased_ The total amount of tokens purchased through NFTs.
     * @param referralAmountPurchased_ The total amount of tokens purchased using referral codes.
     * @return uint256 The total vested amount of tokens for the given purchases at the current time.
     */
    function vestedAmount(
        uint256 nftAmountPurchased_,
        uint256 referralAmountPurchased_
    ) public view returns (uint256) {
        // check if cliff period has ended
        if (block.timestamp < tgeDate) return 0;

        // check if vesting period has ended
        if (block.timestamp >= vestingEndDate)
            return nftAmountPurchased_ + referralAmountPurchased_;

        // calculate vested amount using a linear vesting schedule
        uint256 _allowance = nftAmountPurchased_ + referralAmountPurchased_;
        return
            ((_allowance * tgeUnlockPercent) / 100) + // 25% unlocked at TGE
            (((_allowance * (100 - tgeUnlockPercent)) / 100) * // rest linearly unlocked
                (block.timestamp - tgeDate)) /
            (vestingEndDate - tgeDate);
    }

    /**
     * @notice Calculates the amount of tokens that an investor can currently withdraw, excluding any bonus amounts.
     * @dev This function determines the withdrawable amount by subtracting the total amount already withdrawn
     *      by the investor from their total vested amount. The vested amount is calculated based on the sum of
     *      NFT and referral purchases. This function does not account for any additional bonuses that might apply.
     * @param investor_ The address of the investor for whom the withdrawable amount is being calculated.
     * @param nftAmountPurchased_ The total amount of tokens purchased by the investor through NFTs.
     * @param referralAmountPurchased_ The total amount of tokens purchased by the investor using referral codes.
     * @return uint256 The total amount of tokens that the investor can withdraw at the current time,
     * excluding any bonus amounts.
     */
    function withdrawableAmountWithoutBonus(
        address investor_,
        uint256 nftAmountPurchased_,
        uint256 referralAmountPurchased_
    ) public view returns (uint256) {
        return
            vestedAmount(nftAmountPurchased_, referralAmountPurchased_) -
            withdraws[investor_];
    }

    /**
     * @notice Allows an investor to withdraw their vested tokens, with an option to apply a bonus.
     * @dev This function enables investors to withdraw their vested tokens based on their NFT and referral purchases.
     *      It checks the validity of a signature to authorize the withdrawal, ensures the token generation event (TGE) has occurred,
     *      and calculates the amount to withdraw, potentially including a bonus.
     *      - The signature is validated for expiry and authenticity.
     *      - The function reverts if the TGE hasn't occurred or if the signature is invalid or expired.
     *      - If there's nothing to withdraw, it also reverts.
     * @param nftAmountPurchased_ The amount of tokens purchased through NFTs by the investor.
     * @param referralAmountPurchased_ The amount of tokens purchased using referral codes by the investor.
     * @param applyBonus_ A boolean indicating whether to apply a bonus to the withdrawal amount.
     * @param signature_ The signature to validate the withdrawal request.
     * @param signatureTimestamp_ The timestamp associated with the signature.
     */
    function withdraw(
        uint256 nftAmountPurchased_,
        uint256 referralAmountPurchased_,
        bool applyBonus_,
        bytes calldata signature_,
        uint256 signatureTimestamp_
    ) external {
        // check signature is not expired
        if (block.timestamp > signatureTimestamp_ + signatureValidity) {
            revert ExpiredSignature();
        }

        // check signature is signed by signerWallet
        if (
            !SignatureChecker.isValidSignatureNow(
                signerWallet,
                MessageHashUtils.toEthSignedMessageHash(
                    keccak256(
                        abi.encodePacked(
                            msg.sender,
                            signatureTimestamp_,
                            nftAmountPurchased_,
                            referralAmountPurchased_,
                            applyBonus_
                        )
                    )
                ),
                signature_
            )
        ) {
            revert InvalidSignature();
        }

        // check if token generation event is reached
        if (block.timestamp < tgeDate) {
            revert TGEPending();
        }

        // calculate withdrawable amount without bonus
        uint256 _withdrawableAmountWithoutBonus = withdrawableAmountWithoutBonus(
                msg.sender,
                nftAmountPurchased_,
                referralAmountPurchased_
            );

        // check if there is anything to withdraw
        if (_withdrawableAmountWithoutBonus == 0) {
            revert ZeroWithdrawAmount();
        }

        // update withdraws state
        withdraws[msg.sender] += _withdrawableAmountWithoutBonus;

        // calculate bonus amount
        uint256 _bonusAmount = applyBonus_
            ? (((_withdrawableAmountWithoutBonus * bonusPercent) / 100) *
                nftAmountPurchased_) /
                (nftAmountPurchased_ + referralAmountPurchased_) // apply bonus only on nftAmountPurchased
            : 0;

        // transfer tokens
        grapeToken.transfer(
            msg.sender,
            _withdrawableAmountWithoutBonus + _bonusAmount
        );

        // emit event
        emit Withdraw(
            msg.sender,
            _withdrawableAmountWithoutBonus,
            _bonusAmount
        );
    }

    /**
     * @dev Only owner functions
     */

    /**
     * @notice Updates the Token Generation Event (TGE) date of the contract.
     * @dev Allows the contract owner to change the TGE date. This function can only be called by the owner.
     *      Changing the TGE date affects when investors can start withdrawing their vested tokens.
     * @param tgeDate_ The new TGE date, represented as a Unix timestamp.
     */
    function changeTgeDate(uint256 tgeDate_) external onlyOwner {
        tgeDate = tgeDate_;
    }

    /**
     * @notice Sets a new vesting end date for the contract.
     * @dev This function allows the contract owner to update the end date of the vesting period.
     *      It can only be called by the contract owner. Changing the vesting end date affects when the vesting period
     *      concludes and, as a result, impacts how vested amounts are calculated for investors.
     * @param vestingEndDate_ The new vesting end date, represented as a Unix timestamp.
     */
    function changeVestingEndDate(uint256 vestingEndDate_) external onlyOwner {
        vestingEndDate = vestingEndDate_;
    }

    /**
     * @notice Allows the contract owner to withdraw all Grape tokens held by the contract.
     * @dev This function enables the owner of the contract to transfer all Grape tokens currently stored in the contract
     *      to their own address. It's a mechanism for retrieving tokens from the contract, possibly for redistribution or other purposes.
     *      The transfer is executed via the Grape token's `transfer` method.
     */
    function withdrawAllGrapeToken() external onlyOwner {
        grapeToken.transfer(owner(), grapeToken.balanceOf(address(this)));
    }
}
