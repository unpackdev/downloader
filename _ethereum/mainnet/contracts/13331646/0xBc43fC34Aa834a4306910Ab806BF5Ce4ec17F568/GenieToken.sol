// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./IMagicLampERC721.sol";
import "./Context.sol";
import "./Ownable.sol";

/**
 *
 * GenieToken Contract (The native token of MagicLamp)
 * @dev Extends standard ERC20 and Ownable contract
 */
contract GenieToken is ERC20, Ownable {
    using SafeMath for uint256;

    // Constants
    uint256 public SECONDS_IN_A_DAY = 86400;

    // Public variables
    mapping(address => bool) public emissionTargets;
    mapping(address => uint256) public emissionInitialAllotments;       // ex: 1337 * (10 ** 18)
    mapping(address => uint256) public emissionPreRevealMultipliers;    // ex: 3
    mapping(address => uint256) public emissionStarts;                  // ex: 1626307200
    mapping(address => uint256) public emissionEnds;                    // ex: 1626307200 + (86400 * 365 * 5); // 5 Years
    mapping(address => uint256) public emissionPerDays;                 // ex: 7.37 * (10 ** 18)

    mapping(address => mapping(uint256 => uint256)) private _lastClaims;

    // Events    
    event NameChange(uint256 indexed magicLampIndex, string newName);
    event EmissionSet(address indexed token, bool enabled, uint256 initialAllotment, uint256 preRevealMultiplier, uint256 startTimestamp, uint256 durationTime, uint256  emissionPerDay);

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) ERC20(name_, symbol_) {
    }
    

    /**
     * @dev When accumulated GNIs have last been claimed for a MagicLamp token index
     */
    function lastClaim(address token, uint256 tokenIndex) public view returns (uint256) {
        require(emissionTargets[token], "Emission disabled");
        require(IMagicLampERC721(token).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < IMagicLampERC721(token).totalSupply(), "NFT at index has not been minted yet");

        uint256 lastClaimed = uint256(_lastClaims[token][tokenIndex]) != 0 ? uint256(_lastClaims[token][tokenIndex]) : emissionStarts[token];
        return lastClaimed;
    }

    /**
     * @dev Accumulated GNI tokens for a MagicLamp token index.
     */
    function accumulated(address token, uint256 tokenIndex) public view returns (uint256) {
        require(emissionTargets[token], "Emission disabled");
        require(block.timestamp > emissionStarts[token], "Emission has not started yet");
        require(IMagicLampERC721(token).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < IMagicLampERC721(token).totalSupply(), "NFT at index has not been minted yet");

        uint256 lastClaimed = lastClaim(token, tokenIndex);

        // Sanity check if last claim was on or after emission end
        if (lastClaimed >= emissionEnds[token]) return 0;

        uint256 accumulationPeriod = block.timestamp < emissionEnds[token] ? block.timestamp : emissionEnds[token]; // Getting the min value of both
        uint256 totalAccumulated = accumulationPeriod.sub(lastClaimed).mul(emissionPerDays[token]).div(SECONDS_IN_A_DAY);

        // If claim hasn't been done before for the index, add initial allotment (plus prereveal multiplier if applicable)
        if (lastClaimed == emissionStarts[token]) {
            uint256 initialAllotment = IMagicLampERC721(token).isMintedBeforeReveal(tokenIndex) == true ? emissionInitialAllotments[token].mul(emissionPreRevealMultipliers[token]) : emissionInitialAllotments[token];
            totalAccumulated = totalAccumulated.add(initialAllotment);
        }

        return totalAccumulated;
    }

    /**
     * @dev Claim mints GNIs and supports multiple MagicLamp token indices at once.
     */
    function claim(address token, uint256[] memory tokenIndices) public returns (uint256) {
        require(emissionTargets[token], "Emission disabled");
        require(block.timestamp > emissionStarts[token], "Emission has not started yet");

        uint256 totalClaimQty = 0;
        for (uint i = 0; i < tokenIndices.length; i++) {
            // Sanity check for non-minted index
            require(tokenIndices[i] < IMagicLampERC721(token).totalSupply(), "NFT at index has not been minted yet");
            // Duplicate token index check
            for (uint j = i + 1; j < tokenIndices.length; j++) {
                require(tokenIndices[i] != tokenIndices[j], "Duplicate token index");
            }

            uint tokenIndex = tokenIndices[i];
            require(IMagicLampERC721(token).ownerOf(tokenIndex) == _msgSender(), "Sender is not the owner");

            uint256 claimQty = accumulated(token, tokenIndex);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty.add(claimQty);
                _lastClaims[token][tokenIndex] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "No accumulated GNI");
        _mint(_msgSender(), totalClaimQty);
        return totalClaimQty;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        // Approval check is skipped if the caller of transferFrom is the MagicLamp contract. For better UX.
        if (emissionTargets[_msgSender()] == false) {
            uint256 currentAllowance = allowance(sender, _msgSender());
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    
    function setEmission(address target, bool enabled, uint256 initialAllotment, uint256 preRevealMultiplier, uint256 startTimestamp, uint256 durationTime, uint256 emissionPerDay) public onlyOwner {
        emissionTargets[target] = enabled;
        emissionInitialAllotments[target] = initialAllotment;
        emissionPreRevealMultipliers[target] = preRevealMultiplier;
        emissionStarts[target] = startTimestamp;
        emissionEnds[target] = startTimestamp + durationTime;
        emissionPerDays[target] = emissionPerDay;

        emit EmissionSet(target, enabled, initialAllotment, preRevealMultiplier, startTimestamp, durationTime, emissionPerDay);
    }
}
