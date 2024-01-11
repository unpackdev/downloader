// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IHyewonNft {
    error MintingNotStarted(uint256 startTime);
    error MintingEnded(uint256 endTime);
    error MintingNotAllowed();
    error ExceedMaximumForTheRound();
    error ExceedMaximumSupply();
    error ExceedAllowedQuantity(uint16 maximumAllowedQuantity);
    error MaxMintingIdLowerThanCurrentId();
    error NoMatchingFee();
    error NonExistingToken(uint256 tokenId);
    error AddressNotWhitelisted(address candidate);
    error NotEnoughAllowanceLeft(uint16 remainingAllowance);
    error FailedToSendBalance();
    error NotOwnerNorAdmin(address account);
    error AdminOnlyRound();
    error BadRequest(string reason);
    error WhitelistOnlyRound();
    error NotWhitelistOnlyRound();
    error SignatureNotMatch();
    error AlreadyRevealed();
    error ImmutableState();

    enum State {
        DEPLOYED,
        PREPARE_MINTING,
        ON_MINTING,
        END_MINTING,
        ALL_MINTING_DONE
    }

    struct Round {
        uint16 roundNumber; // round number
        uint256 maxMintingId; // maximum token id for this round
        uint256 startId; // beginning of the tokenId for the round
        uint256 lastMintedId; // last token id actually minted before the next round starts
        string tokenURIPrefix; // directory hash value for token uri
        uint256 mintingFee; // minting for the round
        uint16 maxAllowedMintingQuantity; // max number of tokens for an account (if zero, no limit)
        bool whitelisted; // use whitelist or not
        bool revealed; // released token is revealed or not
        uint256 revealBlockNumber; // blocknubmer which entropy will calculated
        uint256 randomSelection;
        uint256 startTime; // round start time
        uint256 endTime; // round end time (if zero, no end time)
        bool onlyAdminRound; // only admin can mint tokens
        address admin; // additional admin account
    }

    event NewRoundCreated();
    event MaxMintingIdUpdated(uint16 roundNumber, uint256 maxId);
    event TokenURIPrefixUpdated(uint16 roundNumber, string prefix);
    event MintingFeeUpdated(uint16 roundNumber, uint256 fee);
    event MaxAllowedMintingCountUpdated(uint16 roundNumber, uint16 count);
    event WhitelistRequiredChanged(uint16 roundNumber, bool whitelisted);
    event SetRevealBlock(uint256 revealBlockNumber);
    event Revealed(uint16 roundNumber);
    event UnrevealedURIUpdated(uint16 roundNumber, string uri);
    event StartTimeUpdated(uint16 roundNumber, uint256 time);
    event EndTimeUpdated(uint16 roundNumber, uint256 time);
    event OnlyAdminRoundChanged(uint16 roundNumber, bool onlyAdmin);
    event AdminUpdated(uint16 roundNumber, address admin);

    event BaseURIUpdated(string baseURI);
    event DefaultUnrevealedURIUpdated(string defaultUnrevealedURI);
    event MintingFeeChanged(uint256 newFee);
    event MaxPublicIdChanged(uint16 newMaxPubId);
    event Received(address called, uint256 amount);
    event Withdraw(address receiver, uint256 amount);
}
