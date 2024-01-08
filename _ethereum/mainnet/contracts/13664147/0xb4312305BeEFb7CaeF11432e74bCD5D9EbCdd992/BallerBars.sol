// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
// import "./ERC165.sol";

import "./IChains.sol";


/**
 *
 * FT Contract (The native token of our NFT)
 * @dev Extends standard ERC20 contract
 */
contract BallerBars is Context, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    // Constants
    uint256 public SECONDS_IN_A_DAY = 86400;

    // uint256 public constant INITIAL_ALLOTMENT = 30 * (10**18);
    
    // Public variables

    uint256 public emissionEnd = 1735689661; 

    // uint256 public emissionPerDay = 1 * (10**18);

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(uint256 => uint256) private _lastClaim;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address public _nftAddress;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18. Also initalizes {emissionStart}
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    
    constructor() ERC20("BallerBars", "BB") { }
 
    /**
     * @dev When accumulated FTs have last been claimed for a NFT index
     */
    function lastClaim(uint256 tokenIndex) public view returns (uint256) {
        require(
            IChains(_nftAddress).ownerOf(tokenIndex) != address(0),
            "Owner cannot be 0 address"
        );
        require(
            tokenIndex < IChains(_nftAddress).totalSupply(),
            "NFT at index has not been minted yet"
        );

        uint256 emissionStart = IChains(_nftAddress).getTokenTimestamp(tokenIndex); 

        uint256 lastClaimed =
            uint256(_lastClaim[tokenIndex]) != 0
                ? uint256(_lastClaim[tokenIndex])
                : emissionStart; 
        return lastClaimed;
    }

    /**
     * @dev Accumulated fungible tokens for a non-fungible token index.
     */
    function accumulated(uint256 tokenIndex) public view returns (uint256) {
        
        require(
            IChains(_nftAddress).ownerOf(tokenIndex) != address(0),
            "Owner cannot be 0 address"
        );
        require(
            tokenIndex < IChains(_nftAddress).totalSupply(),
            "NFT at index has not been minted yet"
        );

        uint256 lastClaimed = lastClaim(tokenIndex);

        // Sanity check if last claim was on or after emission end
        if (lastClaimed >= emissionEnd) return 0;

        uint256 accumulationPeriod =
            block.timestamp < emissionEnd ? block.timestamp : emissionEnd; // Getting the min value of both


        // check multiplier for the tokenIndex 
        uint256 rarityCount = IChains(_nftAddress).getTokenRarityCount(tokenIndex); 
        
        // uint256 thisTokenEmissionPerDay = 1 + (rarityCount * 0.33) * (10**18); 
        uint256 thisTokenEmissionPerDay = ( 100 + (rarityCount * 33) ) * (10**16);

        uint256 totalAccumulated =
            accumulationPeriod.sub(lastClaimed).mul(thisTokenEmissionPerDay).div(
                SECONDS_IN_A_DAY
            );

        return totalAccumulated;
    }



    /**
     * @dev It is set right after deployment.
     */
    function setChainsAddress(address nftAddress) onlyOwner public {
        _nftAddress = nftAddress;
    }
 
 
    /**
     * @dev Changes the last time of the BB emission.
     */
    function setEmissionEnd(uint256 _emissionEnd) onlyOwner public {
        emissionEnd = _emissionEnd;
    }

    /**
     * @dev Claim mints FTs and supports multiple NFT indices at once.
     */
    function claim(uint256[] memory tokenIndices) public returns (uint256) {
        uint256 totalClaimQty = 0;
        for (uint256 i = 0; i < tokenIndices.length; i++) {
            // Sanity check for non-minted index
            require(
                tokenIndices[i] < IChains(_nftAddress).totalSupply(),
                "NFT at index has not been minted yet"
            );
            
            // Duplicate token index check
            for (uint256 j = i + 1; j < tokenIndices.length; j++) {
                require(
                    tokenIndices[i] != tokenIndices[j],
                    "Duplicate token index"
                );
            }

            uint256 tokenIndex = tokenIndices[i];
            require(
                IChains(_nftAddress).ownerOf(tokenIndex) == msg.sender,
                "Sender is not the owner"
            );

            uint256 claimQty = accumulated(tokenIndex);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty.add(claimQty);
                _lastClaim[tokenIndex] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "No accumulated tokens");
        _mint(msg.sender, totalClaimQty);
        return totalClaimQty;
    }
}
