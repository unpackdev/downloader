// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract CrownyVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Claimed(address _address, uint256 _amount);
    event ReturnUnallocated(address _address, uint256 _amount);
    event EmergencyClaim(address _address, uint256 _amount);
    event Vesting(address _address, uint256 _amount);
    event Revoked(address _address);

    mapping (address => uint32[])  internal __junctures;
    mapping (address => bool)      internal __vesters;
    mapping (address => uint256)   internal __claimed;
    mapping (address => uint256)   internal __vestingIncrements;
    mapping (address => uint256)   internal __initialClaims;
    mapping (address => uint256)   internal __vestingAmounts;
    mapping (address => uint256)   internal __vestingEnds;

    uint256 public __balanceAllocated;

    IERC20 internal __token;

    constructor (IERC20 _token) {
        __token = _token;
    }

    /**
     * Admin functions
     */

    function setVesting(address _beneficiary, uint32[] calldata _junctures, uint256 _vestingAmount, uint256 _vestingIncrement, uint256 _initialClaim) external onlyOwner {
        require (_junctures.length > 0, "CrownyVesting: junctures cannot be empty");
        require (__vesters[_beneficiary] == false, "CrownyVesting: address already vesting");

        __balanceAllocated                = __balanceAllocated.add(_vestingAmount);
        __vestingEnds[_beneficiary]       = _junctures[_junctures.length - 1];
        __junctures[_beneficiary]         = _junctures;
        __initialClaims[_beneficiary]     = _initialClaim;
        __vestingIncrements[_beneficiary] = _vestingIncrement;
        __vestingAmounts[_beneficiary]    = _vestingAmount;
        __vesters[_beneficiary]           = true;

        emit Vesting(_beneficiary, _vestingAmount);
    }

    function changeVestingAddress(address _from, address _to) isVesting(_from) external onlyOwner {
        require (__vesters[_to] == false, "CrownyVesting: address already vesting");

        __junctures[_to]         = __junctures[_from];
        __vesters[_to]           = true;
        __claimed[_to]           = __claimed[_from];
        __vestingIncrements[_to] = __vestingIncrements[_from];
        __initialClaims[_to]     = __initialClaims[_from];
        __vestingAmounts[_to]    = __vestingAmounts[_from];
        __vestingEnds[_to]       = __vestingEnds[_from];

        delete __junctures[_from];
        delete __vesters[_from];
        delete __claimed[_to];
        delete __vestingIncrements[_from];
        delete __initialClaims[_from];
        delete __vestingAmounts[_from];
        delete __vestingEnds[_from];
    }

    function emergencyClaim(address _beneficiary, uint256 _amount) isVesting(_beneficiary) external onlyOwner {
        uint256 maximumClaimable = __vestingAmounts[_beneficiary].sub(__claimed[_beneficiary]);

        require(_amount <= maximumClaimable, "CrownyVesting: nope, even in emergencies you can't claim more than you deserve");

        __handleClaim(_beneficiary, _amount);

        emit EmergencyClaim(_beneficiary, _amount);
    }

    function revokeVesting(address _beneficiary, address _to) isVesting(_beneficiary) external onlyOwner {
        require(block.timestamp < __vestingEnds[_beneficiary], "CrownyVesting: all tokens have been vested");

        __handleRevoke(_beneficiary, _to);
        
        emit Revoked(_beneficiary);
    }

    function returnUnallocatedTokens(address _to) external onlyOwner {
        uint256 unallocatedAmount = __token.balanceOf(address(this)).sub(__balanceAllocated);
        
        __token.safeTransfer(_to, unallocatedAmount);

        emit ReturnUnallocated(_to, unallocatedAmount);
    }

    /**
     * Public functions
     */

    function claimTokens(uint256 _amount) external {
        require (_amount > 0, "CrownyVesting: only positivity here!");
        require (_amount <= allowedToClaim(_msgSender()), "CrownyVesting: can't claim more than you have unlocked");

        __handleClaim(_msgSender(), _amount);

        emit Claimed(_msgSender(), _amount);
    }

    function vestingAmount(address _beneficiary) isVesting(_beneficiary) external view returns (uint256) {
        return __vestingAmounts[_beneficiary];
    }

    function vestedAmount(address _beneficiary) isVesting(_beneficiary) external view returns (uint256) {
        return __claimed[_beneficiary].add(allowedToClaim(_beneficiary));
    }

    function claimed(address _beneficiary) isVesting(_beneficiary) external view returns (uint256) {
        return __claimed[_beneficiary];
    }

    function incrementAmount(address _beneficiary) isVesting(_beneficiary) external view returns (uint256) {
        return __vestingIncrements[_beneficiary];
    }

    function nextJuncture(address _beneficiary) isVesting(_beneficiary) external view returns (uint32) {
        if (block.timestamp >= __vestingEnds[_beneficiary]) {
            return 0;
        }
        if (block.timestamp < __junctures[_beneficiary][0]) {
            return __junctures[_beneficiary][0];
        }

        return __junctures[_beneficiary][__getJunctureIndex(_beneficiary) + 1];
    }

    function tokenAddress() external view returns (address) {
        return address(__token);
    }

    function allowedToClaim(address _beneficiary) isVesting(_beneficiary) public view returns (uint256) {
        if (block.timestamp < __junctures[_beneficiary][0]) {
            return 0;
        }

        if (block.timestamp >= __vestingEnds[_beneficiary]) {
            return __vestingAmounts[_beneficiary].sub(__claimed[_beneficiary]);
        }

        uint256 vestedTokens = __initialClaims[_beneficiary]
            .add(__vestingIncrements[_beneficiary].mul(__getJunctureIndex(_beneficiary)));

        // In case of an emergency claim, the claimed tokens can be higher the vested amount.
        if (__claimed[_beneficiary] >= vestedTokens) {
            return 0;
        } else {
            return vestedTokens.sub(__claimed[_beneficiary]);
        }
    }

    /**
     * Internal functions
     */

    function __handleClaim(address _beneficiary, uint256 _amount) internal {
        __claimed[_beneficiary] = __claimed[_beneficiary].add(_amount);
        __balanceAllocated      = __balanceAllocated.sub(_amount);

        __token.safeTransfer(_beneficiary, _amount);
    }

    function __handleRevoke(address _beneficiary, address _to) internal {
        uint256 vestedTokens    = __claimed[_beneficiary].add(allowedToClaim(_beneficiary));
        uint256 tokenDifference = __vestingAmounts[_beneficiary].sub(vestedTokens);
        uint junctureIndex      = __getJunctureIndex(_beneficiary);
        
        __balanceAllocated             = __balanceAllocated.sub(tokenDifference);
        __vestingAmounts[_beneficiary] = vestedTokens;
        __vestingEnds[_beneficiary]    = __junctures[_beneficiary][junctureIndex];
        __junctures[_beneficiary]      = [__junctures[_beneficiary][junctureIndex]];

        __token.safeTransfer(_to, tokenDifference);
    }

    function __getJunctureIndex(address _beneficiary) internal view returns (uint) {
        uint arrayLength = __junctures[_beneficiary].length;
        uint index;

        for (uint i = 0; i < arrayLength; i++) {
            if (block.timestamp >= __junctures[_beneficiary][i]) {
                index = i;
            } else if (block.timestamp < __junctures[_beneficiary][i]) {
                break;
            }
        }

        return index;
    }

    /**
     * Modifiers
     */

    modifier isVesting(address addr) {
        require(__vesters[addr] == true, "CrownyVesting: this address is not vesting");
        _;
    }
}