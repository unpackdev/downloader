// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./Mars.sol";

/**
 * Mars26 Contract
 * @dev Extends standard ERC20 contract
 */
contract Mars26 is ERC20Burnable, Ownable {
    using SafeMath for uint256;

    uint256 public constant INITIAL_ALLOTMENT = 2026 * (10 ** 18);
    uint256 public constant PRE_REVEAL_MULTIPLIER = 2;

    uint256 private constant _SECONDS_IN_A_DAY = 86400;

    uint256 private _emissionStartTimestamp;
    uint256 private _emissionEndTimestamp; 
    uint256 private _emissionPerDay;
    
    mapping(uint256 => uint256) private _lastClaim;

    Mars private _mars;

    /**
     * @dev Sets immutable values of contract.
     */
    constructor (
        uint256 emissionStartTimestamp_,
        uint256 emissionEndTimestamp_,
        uint256 emissionPerDay_
    ) ERC20("Mars26", "M26") {
        _emissionStartTimestamp = emissionStartTimestamp_;
        _emissionEndTimestamp = emissionEndTimestamp_;
        _emissionPerDay = emissionPerDay_;
    }

    function emissionStartTimestamp() public view returns (uint256) {
        return _emissionStartTimestamp;
    }

    function emissionEndTimestamp() public view returns (uint256) {
        return _emissionEndTimestamp;
    }

    function emissionPerDay() public view returns (uint256) {
        return _emissionPerDay;
    }

    function marsAddress() public view returns (address) {
        return address(_mars);
    }

    /**
     * @dev Sets Mars contract address. Can only be called once by owner.
     */
    function setMarsAddress(address payable marsAddress_) public onlyOwner {
        require(address(_mars) == address(0), "Already set");
        
        _mars = Mars(marsAddress_);
    }

    /**
     * @dev Returns timestamp at which accumulated M26s have last been claimed for a {tokenIndex}.
     */
    function lastClaim(uint256 tokenIndex) public view returns (uint256) {
        require(_mars.ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < _mars.totalSupply(), "NFT at index has not been minted yet");

        uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0 ? uint256(_lastClaim[tokenIndex]) : _emissionStartTimestamp;
        return lastClaimed;
    }
    
    /**
     * @dev Returns amount of accumulated M26s for {tokenIndex}.
     */
    function accumulated(uint256 tokenIndex) public view returns (uint256) {
        require(block.timestamp > _emissionStartTimestamp, "Emission has not started yet");
        require(_mars.ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < _mars.totalSupply(), "NFT at index has not been minted yet");

        uint256 lastClaimed = lastClaim(tokenIndex);

        // Sanity check if last claim was on or after emission end
        if (lastClaimed >= _emissionEndTimestamp) return 0;

        uint256 accumulationPeriod = block.timestamp < _emissionEndTimestamp
            ? block.timestamp
            : _emissionEndTimestamp; // Getting the min value of both
        uint256 totalAccumulated = accumulationPeriod
            .sub(lastClaimed)
            .mul(_emissionPerDay)
            .div(_SECONDS_IN_A_DAY);

        // If claim hasn't been done before for the index, add initial allotment (plus prereveal multiplier if applicable)
        if (lastClaimed == _emissionStartTimestamp) {
            uint256 initialAllotment = _mars.isMintedBeforeReveal(tokenIndex) == true
                ? INITIAL_ALLOTMENT.mul(PRE_REVEAL_MULTIPLIER)
                : INITIAL_ALLOTMENT;
            totalAccumulated = totalAccumulated.add(initialAllotment);
        }

        return totalAccumulated;
    }

    /**
     * @dev Claim mints M26s and supports multiple token indices at once.
     */
    function claim(uint256[] memory tokenIndices) public returns (uint256) {
        require(block.timestamp > _emissionStartTimestamp, "Emission has not started yet");

        uint256 totalClaimQty = 0;
        for (uint i = 0; i < tokenIndices.length; i++) {
            // Sanity check for non-minted index
            require(tokenIndices[i] < _mars.totalSupply(), "NFT at index has not been minted yet");
            // Duplicate token index check
            for (uint j = i + 1; j < tokenIndices.length; j++) {
                require(tokenIndices[i] != tokenIndices[j], "Duplicate token index");
            }

            uint tokenIndex = tokenIndices[i];
            require(_mars.ownerOf(tokenIndex) == msg.sender, "Sender is not the owner");

            uint256 claimQty = accumulated(tokenIndex);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty.add(claimQty);
                _lastClaim[tokenIndex] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "No accumulated M26");
        _mint(msg.sender, totalClaimQty);
        increaseAllowance(address(_mars), totalClaimQty);
        return totalClaimQty;
    }
}