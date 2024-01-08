pragma solidity 0.7.6;

// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./SafeMath.sol";

import "./cBSN.sol";

contract Claim is Ownable {
    using SafeMath for uint256;

    event ClaimableTokensUpdated(address indexed beneficiary, uint256 newValue);
    event TokensClaimed(address indexed beneficiary, uint256 amount);

    uint256 public immutable cBSNTotalSupply;

    /// @notice beneficiary -> claimable tokens
    mapping(address => uint256) public claimableTokens;

    /// @notice beneficiary -> whether they have claimed their tokens
    mapping(address => bool) public claimed;

    /// @notice Total tokens locked for all beneficiaries
    uint256 public totalLockedTokens;

    /// @notice From this block number afterwards, tokens can be claimed
    uint256 public claimBlockNumber;

    /// @notice Claim token
    cBSN public token;

    constructor(cBSN _token, uint256 _claimBlockNumber) {
        token = _token;
        cBSNTotalSupply = _token.totalSupply();
        claimBlockNumber = _claimBlockNumber;
    }

    /// @notice For a given list of beneficiaries, specifies an amount of tokens that can be claimed after claimBlockNumber
    /// @dev Only owner
    /// @param _beneficiaries List of addresses receiving tokens
    /// @param _claimableTokens Tokens each beneficiary will receive
    function updateClaimableTokensForBeneficiaries(address[] calldata _beneficiaries, uint256[] calldata _claimableTokens) external onlyOwner {
        require(_beneficiaries.length == _claimableTokens.length, "Inconsistent array length");
        require(_beneficiaries.length > 0, "Empty arrays");

        for(uint i = 0; i < _beneficiaries.length; i++) {
            _updateClaimableTokensForBeneficiary(_beneficiaries[i], _claimableTokens[i]);
        }
    }

    /// @notice Allows a beneficiary to claim unlocked tokens
    function claim() external {
        _claim(msg.sender);
    }

    /// @notice Allows contract owner to pay for the GAS for a list of beneficiary's claim
    /// @dev Only contract owner
    function claimOnBehalfOfManyBeneficiaries(address[] calldata _claimants) external onlyOwner {
        require(_claimants.length > 0, "Empty array");

        for(uint256 i = 0; i < _claimants.length; i++) {
            address claimant = _claimants[i];
            _claim(claimant);
        }
    }

    /// @notice Updates a beneficiaries tokens to a specified amount
    /// @param _beneficiary Address receiving token
    /// @param _claimableTokens Tokens beneficiary will receive
    function _updateClaimableTokensForBeneficiary(address _beneficiary, uint256 _claimableTokens) private {
        require(block.number < claimBlockNumber, "Only before claim block number");

        totalLockedTokens = totalLockedTokens.sub(claimableTokens[_beneficiary]).add(_claimableTokens);
        require(totalLockedTokens <= cBSNTotalSupply, "Cannot exceed max token supply");

        claimableTokens[_beneficiary] = _claimableTokens;
        emit ClaimableTokensUpdated(_beneficiary, _claimableTokens);
    }

    /// @notice Facilitates a claim and ensures that the claim can only happen after claimBlockNumber
    function _claim(address _claimant) private {
        require(claimableTokens[_claimant] > 0, "Nothing available");
        require(claimed[_claimant] == false, "Already claimed");
        require(block.number >= claimBlockNumber, "Cannot claim tokens yet");

        claimed[_claimant] = true;
        token.transfer(_claimant, claimableTokens[_claimant]);

        emit TokensClaimed(_claimant, claimableTokens[_claimant]);
    }
}
