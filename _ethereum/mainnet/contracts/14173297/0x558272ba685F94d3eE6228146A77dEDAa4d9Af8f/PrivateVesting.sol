//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

/// @author Vlaunch Team
/// @title PrivateVesting contract for a initial investors
contract PrivateVesting is Ownable {
    struct Beneficiary {
        uint256 amountStep1;
        uint256 amountStep2;
        uint256 releasedStep1;
        uint256 releasedStep2;
        bool revoked;
    }

    uint256 public startStep1;
    uint256 public durationStep1;
    uint256 public startStep2;
    uint256 public durationStep2;
    mapping(address => Beneficiary) public beneficiaries;

    IERC20 public token;
    
    /** Constructor
    @param owner_ the owner of the contract
    @param token_ the token we want to vest
    @param startStep1_ the start timestamp od the initial vesting step
    @param durationStep1_ the duration of the initial vesting step
    @param startStep2_ the start timestamp od the second vesting step
    @param durationStep2_ the duration of the second vesting step
    */
    constructor(address owner_, IERC20 token_, uint256 startStep1_, uint256 durationStep1_, uint256 startStep2_, uint256 durationStep2_) {
        require(
            startStep1_ + durationStep1_ > block.timestamp,
            "TokenVesting: final time is before current time"
        );
        require(
            startStep2_ + durationStep2_ > block.timestamp,
            "TokenVesting: final time is before current time"
        );
        require(durationStep1_ > 0, "TokenVesting 1: duration is 0");
        require(durationStep2_ > 0, "TokenVesting 2: duration is 0");
        transferOwnership(owner_);

        token = token_;
        startStep1 = startStep1_;
        durationStep1 = durationStep1_;
        startStep2 = startStep2_;
        durationStep2 = durationStep2_;
    }

    /** Revoke function
    @param beneficiary_ the beneficiary we want to revoke the vsting for
    */
    function revoke(address beneficiary_) public onlyOwner {
        require(
            !beneficiaries[beneficiary_].revoked,
            "TokenVesting: Beneficiary is already revoked"
        );

        beneficiaries[beneficiary_].revoked = true;
    }

    /** Setter
    @param startStep1_ the start timestamp od the initial vesting step
    @param durationStep1_ the duration of the initial vesting step
    @param startStep2_ the start timestamp od the second vesting step
    @param durationStep2_ the duration of the second vesting step
    */
    function setParams(uint256 startStep1_, uint256 durationStep1_, uint256 startStep2_, uint256 durationStep2_) public onlyOwner{
        require(
            startStep1_ + durationStep1_ > block.timestamp,
            "TokenVesting: final time is before current time"
        );
        require(
            startStep2_ + durationStep2_ > block.timestamp,
            "TokenVesting: final time is before current time"
        );
        require(durationStep1_ > 0, "TokenVesting 1: duration is 0");
        require(durationStep2_ > 0, "TokenVesting 2: duration is 0");

        startStep1 = startStep1_;
        durationStep1 = durationStep1_;
        startStep2 = startStep2_;
        durationStep2 = durationStep2_;
    }

    /** Create beneficiary function
    @param beneficiary_ the beneficiary we want to create a vesting plan
    @param amountStep1_ the amount to receive in step 1
    @param amountStep2_ the amount to receive in step 2
    */
    function createBeneficiary(
        address beneficiary_,
        uint256 amountStep1_,
        uint256 amountStep2_
    ) public onlyOwner {
        require(
            beneficiary_ != address(0),
            "PrivateTokenVesting: beneficiary is the zero address"
        );
        require(amountStep1_ > 0, "PrivateTokenVesting: cannot vest 0 tokens");
        require(amountStep2_ > 0, "PrivateTokenVesting: cannot vest 0 tokens");
        beneficiaries[beneficiary_].amountStep1 = amountStep1_;
        beneficiaries[beneficiary_].amountStep2 = amountStep2_;
        beneficiaries[beneficiary_].revoked = false;
    }

    /** Create multiple beneficiaries function
    @param beneficiary_ the beneficiary array we want to create a vesting plan
    @param amountStep1_ the amount array to receive in step 1
    @param amountStep2_ the amount array to receive in step 2
    */
    function createBeneficiaries(
        address[] calldata beneficiary_,
        uint256[] calldata amountStep1_,
        uint256[] calldata amountStep2_
    ) public onlyOwner {
        require(beneficiary_.length == amountStep1_.length && beneficiary_.length == amountStep2_.length,
        "The arrays in the parameters have different lengths");
        require(beneficiary_.length <= 100, "Your array exceeds 100. The function call will be reverted due to exceeding the gas limit" );
        for(uint256 i = 0; i < beneficiary_.length; i++) {
            createBeneficiary(beneficiary_[i], amountStep1_[i], amountStep2_[i]);
        }
    }

    // The release function 
    function release() public {
        releaseFor(msg.sender);
    }

    /** Public function that alows a user to release for another address
    @param user_ address to release for
     */
    function releaseFor(address user_) public{
        Beneficiary storage beneficiary = beneficiaries[user_];

        require(beneficiary.amountStep1 > 0, "PrivateTokenVesting: no amountStep1");
        require(beneficiary.amountStep2 > 0, "PrivateTokenVesting: no amountStep2");
        require(!beneficiary.revoked, "PrivateTokenVesting: revoked beneficiary");

        uint256 unreleasedStep1 = _releasableAmount(beneficiary, false);
        uint256 unreleasedStep2 = _releasableAmount(beneficiary, true);
        require(unreleasedStep1 + unreleasedStep2 > 0, "PrivateTokenVesting: no tokens are due");

        beneficiary.releasedStep1 += unreleasedStep1;
        beneficiary.releasedStep2 += unreleasedStep2;
        token.transfer(user_, unreleasedStep1 + unreleasedStep2);
    }

    /** Public function that alows a user to release for multiple addresses
    @param users_ the address array to release for
     */
    function releaseMultiple(address[] calldata users_) public {
        require(users_.length <= 100,"Your array exceeds 100. The function call will be reverted due to exceeding thegas limit" );
        for(uint256 i = 0; i < users_.length; i++) {
            releaseFor(users_[i]);
        }
    }

    /** Owner withdraw function
    @param amount_ the amount to withdraw
    @param token_ the token to withdraw
    */
    function withdraw(uint256 amount_, IERC20 token_) public onlyOwner {
        require(amount_ > 0);
        token_.transfer(msg.sender, amount_);
    }

    /** Computes the releasable amount of tokens for beneficiary
    @param beneficiary_ the beneficiary 
    @param isStep2_ if the computation should be done for step2
     */
    function _releasableAmount(Beneficiary memory beneficiary_, bool isStep2_)
        private
        view
        returns (uint256)
    {
        if(!isStep2_){
            return _vestedAmount(beneficiary_, isStep2_) - beneficiary_.releasedStep1;
        } else {
            return _vestedAmount(beneficiary_, isStep2_) - beneficiary_.releasedStep2;
        }
    }

    /** Computes the releasable amount for msg.sender
    */
    function releasableAmount()
        public
        view
        returns (uint256)
    {
        Beneficiary memory beneficiary = beneficiaries[msg.sender];
        return _releasableAmount(beneficiary, false) + _releasableAmount(beneficiary, true);
    }

    /** Computes the releasable amount for user
    @param user the beneficiary 
    */
    function releasableAmount(address user)
        public
        view
        returns (uint256)
    {
        Beneficiary memory beneficiary = beneficiaries[user];
        return _releasableAmount(beneficiary, false) + _releasableAmount(beneficiary, true);
    }

    /** Computes the vested amount
    @param beneficiary_ the beneficiary 
    @param isStep2_ if the computation should be done for step2
     */
    function _vestedAmount(Beneficiary memory beneficiary_, bool isStep2_)
        private
        view
        returns (uint256)
    {
        if(!isStep2_){
            uint256 totalBalance = beneficiary_.amountStep1;

            if (block.timestamp < startStep1) {
                return 0;
            } else if (
                block.timestamp >= (startStep1 + durationStep1)
            ) {
                return totalBalance;
            } else {
                return
                    (totalBalance * (block.timestamp - startStep1)) /
                    durationStep1;
            }
        } else {
            uint256 totalBalance = beneficiary_.amountStep2;

            if (block.timestamp < startStep2) {
                return 0;
            } else if (
                block.timestamp >= (startStep2 + durationStep2)
            ) {
                return totalBalance;
            } else {
                return
                    (totalBalance * (block.timestamp - startStep2)) /
                    durationStep2;
            }
        }
    }
}