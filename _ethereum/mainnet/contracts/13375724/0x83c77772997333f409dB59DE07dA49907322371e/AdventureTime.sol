// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";
import "./ERC20Burnable.sol";

/// @title Adventure Time for Genesis Adventurer holders!
/// @notice This contract mints Adventure Time for Loot holders and provides
/// administrative functions to the Loot DAO. It allows:
/// * Genesis Adventurer holders to claim Adventure Time
/// * A DAO to set seasons for new opportunities to claim Adventure Time
/// * A DAO to mint Adventure Time for use within the Loot ecosystem
/// @custom:unaudited This contract has not been audited. Use at your own risk.
contract AdventureTime is Context, Ownable, ERC20, ERC20Burnable {
    // Genesis Adventurer contract is available at https://etherscan.io/token/0x8db687aceb92c66f013e1d614137238cc698fedb
    address public gaContractAddress;
    IERC721Enumerable private _gaContract;

    // Give out 100,000 Adventure Time for every Genesis Adventurer that a user holds
    uint256 public adventureTimePerTokenId = 20320 * (10**decimals());

    uint256 public tokenIdStart = 1;

    uint256 public tokenIdEnd = 2540;

    // Seasons are used to allow users to claim tokens regularly. Seasons are
    // decided by the DAO.
    uint256 public season = 0;

    // Track claimed tokens within a season
    // IMPORTANT: The format of the mapping is:
    // claimedForSeason[season][tokenId][claimed]
    mapping(uint256 => mapping(uint256 => bool)) public seasonClaimedByTokenId;

    constructor(address _gaContractAddress, address _genesisDaoAddress)
        Ownable()
        ERC20("Adventure Time", "ATIME")
    {
        // Transfer ownership to the Genesis Project DAO
        // Ownable by OpenZeppelin automatically sets owner to msg.sender, but
        // we're going to be using a separate wallet for deployment
        transferOwnership(_genesisDaoAddress);
        gaContractAddress = _gaContractAddress;
        _gaContract = IERC721Enumerable(gaContractAddress);
    }

    function claimById(uint256 tokenId) external {
        // Follow the Checks-Effects-Interactions pattern to prevent reentrancy
        // attacks

        // Checks

        // Check that the msgSender owns the token that is being claimed
        require(
            _msgSender() == _gaContract.ownerOf(tokenId),
            "MUST_OWN_TOKEN_ID"
        );

        // Further Checks, Effects, and Interactions are contained within the
        // _claim() function
        _claim(tokenId);
    }

    function claimAllForOwner() external {
        uint256 tokenBalanceOwner = _gaContract.balanceOf(_msgSender());

        // Checks
        require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");

        // i < tokenBalanceOwner because tokenBalanceOwner is 1-indexed
        for (uint256 i = 0; i < tokenBalanceOwner; i++) {
            // Further Checks, Effects, and Interactions are contained within
            // the _claim() function
            _claim(_gaContract.tokenOfOwnerByIndex(_msgSender(), i));
        }
    }

    /// @notice Claim Adventure Time for a given Genesis Adventurer ID
    /// @param tokenId The tokenId of the GA NFT
    function _claim(uint256 tokenId) internal {
        // Follow the Checks-Effects-Interactions pattern to prevent reentrancy
        // attacks

        // Checks

        // Check that the msgSender owns the token that is being claimed
        require(
            _msgSender() == _gaContract.ownerOf(tokenId),
            "MUST_OWN_TOKEN_ID"
        );

        // Check that the token ID is in range
        // We use >= and <= to here because all of the token IDs are 0-indexed
        require(
            tokenId >= tokenIdStart && tokenId <= tokenIdEnd,
            "TOKEN_ID_OUT_OF_RANGE"
        );

        // Check that Adventure Time have not already been claimed this season
        // for a given tokenId
        require(
            !seasonClaimedByTokenId[season][tokenId],
            "TIME_CLAIMED_FOR_TOKEN_ID"
        );

        // Effects

        // Mark that Adventure Time has been claimed for this season for the
        // given tokenId
        seasonClaimedByTokenId[season][tokenId] = true;

        // Interactions

        // Send Adventure Time to the owner of the token ID
        _mint(_msgSender(), adventureTimePerTokenId);
    }

    /// @notice Allows the DAO to mint new tokens for use within the Loot
    /// Ecosystem
    /// @param amountDisplayValue The amount of Loot to mint. This should be
    /// input as the display value, not in raw decimals. If you want to mint
    /// 100 Loot, you should enter "100" rather than the value of 100 * 10^18.
    function daoMint(uint256 amountDisplayValue) external onlyOwner {
        _mint(owner(), amountDisplayValue * (10**decimals()));
    }

    /// @notice Allows the DAO to set a new contract address for Loot. This is
    /// relevant in the event that Loot migrates to a new contract.
    /// @param gaContractAddress_ The new contract address for Loot
    function daoSetGAContractAddress(address gaContractAddress_)
        external
        onlyOwner
    {
        gaContractAddress = gaContractAddress_;
        _gaContract = IERC721Enumerable(gaContractAddress);
    }

    /// @notice Allows the DAO to set the token IDs that are eligible to claim
    /// Loot
    /// @param tokenIdStart_ The start of the eligible token range
    /// @param tokenIdEnd_ The end of the eligible token range
    /// @dev This is relevant in case a future GA contract has a different
    /// total supply of GA's
    function daoSetTokenIdRange(uint256 tokenIdStart_, uint256 tokenIdEnd_)
        external
        onlyOwner
    {
        tokenIdStart = tokenIdStart_;
        tokenIdEnd = tokenIdEnd_;
    }

    /// @notice Allows the DAO to set a season for new Adventure Time claims
    /// @param season_ The season to use for claiming Loot
    function daoSetSeason(uint256 season_) public onlyOwner {
        season = season_;
    }

    /// @notice Allows the DAO to set the amount of Adventure Time that is
    /// claimed per token ID
    /// @param adventureTimeDisplayValue The amount of Loot a user can claim.
    /// This should be input as the display value, not in raw decimals. If you
    /// want to mint 100 Loot, you should enter "100" rather than the value of
    /// 100 * 10^18.
    function daoSetAdventureTimePerTokenId(uint256 adventureTimeDisplayValue)
        public
        onlyOwner
    {
        adventureTimePerTokenId = adventureTimeDisplayValue * (10**decimals());
    }

    /// @notice Allows the DAO to set the season and Adventure Time per token ID
    /// in one transaction. This ensures that there is not a gap where a user
    /// can claim more Adventure Time than others
    /// @param season_ The season to use for claiming loot
    /// @param adventureTimeDisplayValue The amount of Loot a user can claim.
    /// This should be input as the display value, not in raw decimals. If you
    /// want to mint 100 Loot, you should enter "100" rather than the value of
    /// 100 * 10^18.
    /// @dev We would save a tiny amount of gas by modifying the season and
    /// adventureTime variables directly. It is better practice for security,
    /// however, to avoid repeating code. This function is so rarely used that
    /// it's not worth moving these values into their own internal function to
    /// skip the gas used on the modifier check.
    function daoSetSeasonAndAdventureTimePerTokenId(
        uint256 season_,
        uint256 adventureTimeDisplayValue
    ) external onlyOwner {
        daoSetSeason(season_);
        daoSetAdventureTimePerTokenId(adventureTimeDisplayValue);
    }
}
