// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

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
    address public SeasonContractAddress;
    IERC721Enumerable private SeasonContract;

    // Give out 100,000 Adventure Time for every Genesis Adventurer that a user holds
    uint256 public adventureTimePerTokenId = 100 * (10**decimals());

    uint256 public tokenIdStart = 1;

    uint256 public tokenIdEnd = 8000;

    // Seasons are used to allow users to claim tokens regularly.
    // Seasons are decided by the DAO.
    uint256 public season = 0;

    // Track claimed tokens within a season
    // IMPORTANT: The format of the mapping is:
    // claimedForSeason[season][tokenId][claimed]
    mapping(uint256 => mapping(uint256 => bool)) public seasonClaimedByTokenId;

    constructor(
        address _CurrentSeasonContractAddress,
        address _genesisDaoAddress
    ) Ownable() ERC20("Adventure Time", "ATIME") {
        // Transfer ownership to the Genesis Project DAO
        // Ownable by OpenZeppelin automatically sets owner to msg.sender, but
        // we're going to be using a separate wallet for deployment
        transferOwnership(_genesisDaoAddress);
        SeasonContractAddress = _CurrentSeasonContractAddress;
        SeasonContract = IERC721Enumerable(SeasonContractAddress);
    }

    function claimById(uint256 _tokenId) external {
        // Follow the Checks-Effects-Interactions pattern
        // to prevent reentrancy attacks
        _markClaimedForSeason(_tokenId);
        _mint(_msgSender(), adventureTimePerTokenId);
    }

    function claimAllForOwner() external {
        uint256 tokenBalanceOwner = SeasonContract.balanceOf(_msgSender());
        uint256[] memory tokensUnclaimed = new uint256[](tokenBalanceOwner);

        // Checks
        require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");

        for (uint256 i = 0; i < tokenBalanceOwner; i++) {
            if (
                seasonClaimedByTokenId[season][
                    SeasonContract.tokenOfOwnerByIndex(_msgSender(), i)
                ] == false
            ) {
                tokensUnclaimed[i] = SeasonContract.tokenOfOwnerByIndex(
                    _msgSender(),
                    i
                );
            } else {
                delete tokensUnclaimed[i];
            }
        }

        // i < tokenBalanceOwner because tokenBalanceOwner is 1-indexed
        for (uint256 i = 0; i < tokensUnclaimed.length; i++) {
            if (tokensUnclaimed[i] != 0) {
                _markClaimedForSeason(tokensUnclaimed[i]);
            } else {
                tokenBalanceOwner--;
            }
        }
        require(tokenBalanceOwner > 0, "ALL_TOKENS_CLAIMED");

        _mint(_msgSender(), adventureTimePerTokenId * tokenBalanceOwner);
    }

    /// @notice Checks for requirements then marks token complete for season
    /// @param _tokenId The tokenId of the NFT
    function _markClaimedForSeason(uint256 _tokenId)
        internal
        checkOwnerOfToken(_tokenId)
        checkTokenInRange(_tokenId)
        checkAlreadySeasonClaimed(_tokenId)
    {
        // Mark that Adventure Time has been claimed for this season for the token
        seasonClaimedByTokenId[season][_tokenId] = true;
    }

    modifier checkOwnerOfToken(uint256 _tokenId) {
        require(
            _msgSender() == SeasonContract.ownerOf(_tokenId),
            "MUST_OWN_TOKEN_ID"
        );
        _;
    }

    modifier checkTokenInRange(uint256 _tokenId) {
        require(
            _tokenId >= tokenIdStart && _tokenId <= tokenIdEnd,
            "TOKEN_ID_OUT_OF_RANGE"
        );
        _;
    }

    modifier checkAlreadySeasonClaimed(uint256 _tokenId) {
        require(
            !seasonClaimedByTokenId[season][_tokenId],
            "TIME_CLAIMED_FOR_TOKEN_ID"
        );
        _;
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
    /// @param _SeasonContractAddress The new contract address for Loot
    function daoSetSeasonContractAddress(address _SeasonContractAddress)
        external
        onlyOwner
    {
        SeasonContractAddress = _SeasonContractAddress;
        SeasonContract = IERC721Enumerable(SeasonContractAddress);
    }

    /// @notice Allows the DAO to set the token IDs that are eligible to claim
    /// Loot
    /// @param _tokenIdStart The start of the eligible token range
    /// @param _tokenIdEnd The end of the eligible token range
    /// @dev This is relevant in case a future NFT contract has a different
    /// total supply of tokens
    function daoSetTokenIdRange(uint256 _tokenIdStart, uint256 _tokenIdEnd)
        external
        onlyOwner
    {
        tokenIdStart = _tokenIdStart;
        tokenIdEnd = _tokenIdEnd;
    }

    /// @notice Allows the DAO to set a season for new Adventure Time claims
    /// @param _season The season to use for claiming Loot
    function daoSetSeason(uint256 _season) public onlyOwner {
        season = _season;
    }

    /// @notice Allows the DAO to set the amount of Adventure Time that is
    /// claimed per token ID
    /// @param _adventureTimeDisplayValue The amount of Loot a user can claim.
    /// This should be input as the display value, not in raw decimals. If you
    /// want to mint 100 Loot, you should enter "100" rather than the value of
    /// 100 * 10^18.
    function daoSetAdventureTimePerTokenId(uint256 _adventureTimeDisplayValue)
        public
        onlyOwner
    {
        adventureTimePerTokenId = _adventureTimeDisplayValue * (10**decimals());
    }

    /// @notice Allows the DAO to set the season and Adventure Time per token ID
    /// in one transaction. This ensures that there is not a gap where a user
    /// can claim more Adventure Time than others
    /// @param _season The season to use for claiming loot
    /// @param _adventureTimeDisplayValue The amount of Loot a user can claim.
    /// This should be input as the display value, not in raw decimals. If you
    /// want to mint 100 Loot, you should enter "100" rather than the value of
    /// 100 * 10^18.
    /// @dev We would save a tiny amount of gas by modifying the season and
    /// adventureTime variables directly. It is better practice for security,
    /// however, to avoid repeating code. This function is so rarely used that
    /// it's not worth moving these values into their own internal function to
    /// skip the gas used on the modifier check.
    function daoSetSeasonAndAdventureTimePerTokenId(
        uint256 _season,
        uint256 _adventureTimeDisplayValue
    ) external onlyOwner {
        daoSetSeason(_season);
        daoSetAdventureTimePerTokenId(_adventureTimeDisplayValue);
    }
}
