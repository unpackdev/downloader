pragma solidity 0.7.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./TokenVesting.sol";
import "./IDogiraLegacyToken.sol";

/*
    DogeCity manages our funds. It will be initialized with around 19 million DOGIRA.
    There are several payout mechanism:
    * FEG Vesting Contract:
      * Pays out 3 million DOGIRA starting immediately over the course of 1 year (linear payout).
      * This honours our partnership agreement with FEG and shall be used for that purpose exclusively
      * Any excess tokens not used for that partnership must be contributed back into the community fund.
    * Community Fund:
      * Manages around 12 million DOGIRA
      * A maximum of 100,000 DOGIRA can be withdrawn per day and only a single withdrawal per day is possible.
      * These tokens will be used for marketing purposes, rewarding community members and exchange listings and
        whatever else helps DOGIRA to be a boss! Generally, all withdrawals should have a publicly stated reason,
        however all withdrawals in excess of 10,000 DOGIRA per day, shall be explicitly announced to the community.
    * Founding Member Vesting Contracts:
      * Each founding member has a separate vesting contract paying into their own wallet.
      * There are 500,000 DOGIRA allocated for each founding member and they will be paid out over 2 years, with
        the first payment commencing after 6 months from now. This should give a long-term incentive for each
        founding member to contribute to the projects success, while also rewarding them for their involvement.
        Please keep in mind that we need to be able to quit our day jobs to make this project succeed long-term.
    * Payroll Vesting Contract:
      * Two million DOGIRA will be paid out linearly, starting immediately over 3 years into a payroll wallet.
      * This payroll wallet may only be used to pay people contributing to Dogira. This payroll may NOT be used
        to pay founding members, as they have their own vesting contract. This fund is meant to pay external people
        and community managers.
*/
contract DogeCity is Ownable {
    TokenVesting fegPartnershipVestingContract;
    TokenVesting foundingMember1VestingContract;
    TokenVesting foundingMember2VestingContract;
    TokenVesting foundingMember3VestingContract;
    TokenVesting foundingMember4VestingContract;
    TokenVesting payrollVestingContract;
    IDogira dogira;
    uint256 lastWithdrawalFromCommunityFund;
    bool wasInitialized;

    constructor(
        address dogiraToken,
        address foundingMember1RewardAddress,
        address foundingMember2RewardAddress,
        address foundingMember3RewardAddress,
        address foundingMember4RewardAddress,
        address fegPartnershipAddress,
        address payrollRewardAddress
    ) {
        dogira = IDogira(dogiraToken);

        foundingMember1VestingContract = _createFoundingMemberVestingContract(foundingMember1RewardAddress);
        foundingMember2VestingContract = _createFoundingMemberVestingContract(foundingMember2RewardAddress);
        foundingMember3VestingContract = _createFoundingMemberVestingContract(foundingMember3RewardAddress);
        foundingMember4VestingContract = _createFoundingMemberVestingContract(foundingMember4RewardAddress);
        fegPartnershipVestingContract = _createFegVestingContract(fegPartnershipAddress);
        payrollVestingContract = _createPayrollVestingContract(payrollRewardAddress);
    }

    function getBlockTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getDogiraToken() public view returns (address) {
        return address(dogira);
    }

    function getCommunityFund() public view returns (address) {
        return address(this);
    }

    function getFegPartnershipVestingContract() public view returns (address) {
        return address(fegPartnershipVestingContract);
    }

    function getFoundingMember1VestingContract() public view returns (address) {
        return address(foundingMember1VestingContract);
    }

    function getFoundingMember2VestingContract() public view returns (address) {
        return address(foundingMember2VestingContract);
    }

    function getFoundingMember3VestingContract() public view returns (address) {
        return address(foundingMember3VestingContract);
    }

    function getFoundingMember4VestingContract() public view returns (address) {
        return address(foundingMember4VestingContract);
    }

    function getPayrollVestingContract() public view returns (address) {
        return address(payrollVestingContract);
    }

    function withdrawFromCommunityFund(address recipient, uint256 amount) external onlyOwner {
        require(lastWithdrawalFromCommunityFund < block.timestamp - 1 days, "You can only withdraw from the fund once per day.");
        require(amount <= 100_000 ether, "You can only withdraw up to 100k tokens at a time.");

        dogira.transferFrom(getCommunityFund(), recipient, amount);

        lastWithdrawalFromCommunityFund = block.timestamp;
    }

    function _createPayrollVestingContract(address payrollRewardAddress) private returns (TokenVesting) {
        return new TokenVesting(
            payrollRewardAddress,
            block.timestamp,
            0,
            3 * 365 * (1 days),
            false
        );
    }

    function _createFegVestingContract(address fegPartnershipAddress) private returns (TokenVesting) {
        return new TokenVesting(
            fegPartnershipAddress,
            block.timestamp,
            0,
            365 days,
            false
        );
    }

    function _createFoundingMemberVestingContract(address foundingMemberWalletAddress) private returns (TokenVesting) {
        return new TokenVesting(
            foundingMemberWalletAddress,
            block.timestamp + 180 days,
            0,
            2 * 365 * (1 days),
            false
        );
    }

    function initialize(address fundingWallet) external onlyOwner {
        require(!wasInitialized, "DogeCity was already initialized!");

        // You notice fees when it's too late. The amount of money we transfer here is too big to allow for accidental fees.
        require(dogira.getFeeless(fundingWallet), "The funding wallet should be feeless.");
        require(dogira.getFeeless(address(foundingMember1VestingContract)), "The member 1 vesting contract should be set to feeless.");
        require(dogira.getFeeless(address(foundingMember2VestingContract)), "The member 2 vesting contract should be set to feeless.");
        require(dogira.getFeeless(address(foundingMember3VestingContract)), "The member 3 vesting contract should be set to feeless.");
        require(dogira.getFeeless(address(foundingMember4VestingContract)), "The member 4 vesting contract should be set to feeless.");
        require(dogira.getFeeless(address(payrollVestingContract)), "The payroll vesting contract should be set to feeless.");
        require(dogira.getFeeless(address(fegPartnershipVestingContract)), "The FEG vesting contract should be set to feeless.");
        require(dogira.getFeeless(address(this)), "This contract should be set to feeless.");

        wasInitialized = true;

        dogira.transferFrom(fundingWallet, address(foundingMember1VestingContract), 500_000 ether);
        dogira.transferFrom(fundingWallet, address(foundingMember2VestingContract), 500_000 ether);
        dogira.transferFrom(fundingWallet, address(foundingMember3VestingContract), 500_000 ether);
        dogira.transferFrom(fundingWallet, address(foundingMember4VestingContract), 500_000 ether);
        dogira.transferFrom(fundingWallet, address(payrollVestingContract), 2_000_000 ether);
        dogira.transferFrom(fundingWallet, address(fegPartnershipVestingContract), 3_000_000 ether);

        require(dogira.balanceOf(fundingWallet) >= 6_000_000 ether, "After deducting all other funds, there must be at least 6 million DOGIRA left for the community fund.");
        dogira.transferFrom(fundingWallet, address(this), dogira.balanceOf(fundingWallet));
    }
}
