// SPDX-License-Identifier: UNLICENSED

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                        #                                           //
//                                                                      ##                                            //
//                                                                    ###                                             //
//                                                               #######                                              //
//                                                            ####%**##                                               //
//                                                         ####*:---##                                                //
//                                                      ###%*:-----###                                                //
//                                                    ###%-----+---##                                                 //
//                                                  ####----====--=##                                                 //
//                                                ####:---======--*##                                                 //
//                                              ####----+===+===--###                                                 //
//                                             ###=---+===**+===--###                                                 //
//                                            ###:--====+***+===--*##                                                 //
//                                          ###=---===+******===--+##                                                 //
//                                         ##%:--====********===--=##                                                 //
//                                        ###---===+*********+==---###                                                //
//                                       ###---+==+**********+===--+##                                                //
//                                      ###---+==+************===--:%##                                               //
//                                     ###:--===+**************===--=##                                               //
//                                    ##%---===+***************+===--*##                                              //
//                                    ##=--===+*****************===---*##                                             //
//                                   ##*---==+*******************==+---*##                                            //
//                                  ##%:--+==*********************===---=###                                          //
//                         #        ##+--===+**********************====---%##                                         //
//                       ###       ##%---+==************************====---+###                                       //
//                     ####        ##*--===+*************************+===---:*###                                     //
//                   ######        #%=--+==****************************====----+%###                                  //
//                  ##%=###       ##%---==+******************************===+----=####                                //
//                 ###-:%##       ###---==+********************************=====---:#####                             //
//               ###+--:%##       ##*--===+**********************************====+----=%###                           //
//              ###=----###       ##*--===+************************************+=====----%###                         //
//             ###---=--+##       ###--===+***************************************=====---:%###                       //
//            ###---==--:%##      ##*--===+**************#####**********************+====----%##                      //
//            ##=--====---%##    ##%---+==********####################****************+====---+###                    //
//           ##*---====+:--+%######---===+****#####%#+:.       ..-*######***************+====---###                   //
//          ###---+==+====----===:---===+***#####:                    =%####**************====--:###                  //
//          #%=--===+**=====-------====*+*###%:                          +%###************++===---*##                 //
//         ###---==+*****+===========+**###%.                              =%###*************===---*##                //
//         ##=--+==**********+++++*****###-                                  *###*************===---*##               //
//        ###---==+******************###%.                                    :%##*************==+---###              //
//        ##*--===+*****************###%                                       .%##************+==+:--%##             //
//        ##=--===******************##%                                         :%##+***********+===--*##             //
//        ##=--===*****************##%.                                          =###************==+---###            //
//        ##---===*****************##+                                            ###************+===--###            //
//        ##---===****************##%:                                            +##*************===--+##            //
//        ##---===****************###.                                            :###************===--=##            //
//        ##=--===****************###                                             :###************===---##            //
//        ##*--===+***************###.         *%###%.            +%###%-         :###************+==---##            //
//        ###---==+***************##%.       .%#######*         .#########        =###************===---##            //
//         ##---+==***************###-       +########%         -########%:       ###*************===---##            //
//         ##*--===+***************##%.      .%########         .%########.      -###*************===--+##            //
//         ##%---+==***************###*       .#####%=     #-    .*%###%+       .###*************+===--*##            //
//          ##*---==+***************###=                  *#%:                 .###**************===---###            //
//          ##%---===+***************###+                +###%.               .####*************+===--+##             //
//           ##%:--+==****************####.             =%%%%%%.             .%##***************==+---###             //
//            ###:--===*****************###=                                %###***************+==---*##              //
//             ###---===*****************####+                           .#####***************+===--=##               //
//              ###---===+*****************####%.                      =%###*****************+===---%##               //
//               ###:--====******************###:  *%%:   ..:.   *%%.  +##******************====---%##                //
//                ##%----===+****************###:  +##:   +#%.   *#%.  +##*****************====--=###                 //
//                 ###+---====+**************###:  +##:   +#%.   *#%.  +##***************===+---+###                  //
//                   ##%----====+************###=::*##-:::*##-:::*##-::*##*************+===----###                    //
//                    ###%----=====**********#############################***********=====---+###                     //
//                      ###%:--:======================================================+----=%##                       //
//                        ###%=----=++++++++++++++++++++++++++++++++++++++++++++++++=---:*###                         //
//                          #####------------------------------------------------------####                           //
//                             ##########################################################                             //
//                                ####################################################                                //
//                                                                                                                    //
//  :::::::::  :::    ::: :::::::::  ::::    :::      ::::::::::: :::::::::::      :::::::::      :::      ::::::::   //
//  :+:    :+: :+:    :+: :+:    :+: :+:+:   :+:          :+:         :+:          :+:    :+:   :+: :+:   :+:    :+:  //
//  +:+    +:+ +:+    +:+ +:+    +:+ :+:+:+  +:+          +:+         +:+          +:+    +:+  +:+   +:+  +:+    +:+  //
//  +#++:++#+  +#+    +:+ +#++:++#:  +#+ +:+ +#+          +#+         +#+          +#+    +:+ +#++:++#++: +#+    +:+  //
//  +#+    +#+ +#+    +#+ +#+    +#+ +#+  +#+#+#          +#+         +#+          +#+    +#+ +#+     +#+ +#+    +#+  //
//  #+#    #+# #+#    #+# #+#    #+# #+#   #+#+#          #+#         #+#          #+#    #+# #+#     #+# #+#    #+#  //
//  #########   ########  ###    ### ###    ####      ###########     ###          #########  ###     ###  ########   //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.23;

import "./ERC721PsiBurnable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PullPayment.sol";
import "./LibPRNG.sol";
import "./LibString.sol";
import "./LibBitSet.sol";
import "./LibShared.sol";
import "./LibConfig.sol";
import "./LibGame.sol";
import "./LibWinners.sol";
import "./LibRefundable.sol";
import "./TimeLock.sol";
import "./LibUser.sol";
import "./Constants.sol";

/// @dev VERSION: 1.1.1
contract BurnItDAO is
ERC721PsiBurnable,
PullPayment,
Ownable,
ReentrancyGuard,
TimeLock,
ILibBitSetFilter
{
    using LibPRNG for LibPRNG.PRNG;
    using LibBitSet for LibBitSet.Set;
    using LibGame for LibGame.Game;
    using LibUser for LibUser.User;
    using LibWinners for LibWinners.Winners;
    using LibRefundable for LibRefundable.MintData;
    using LibShared for uint256;
    using LibConfig for uint256;
    using LibGame for uint256;
    using LibString for uint256;
    using LibShared for uint32;
    using LibString for uint8;

    uint256 private immutable _tokenPrice;
    uint256 private immutable _config;

    LibGame.Game private _game;
    LibWinners.Winners private _winners;
    LibRefundable.MintData private _mints;
    mapping(address => LibUser.User) private _users;
    uint256 private _claimSeed;
    address payable private _teamAddress;
    address payable private _drawAddress;
    string private _baseTokenURI;

    event Claim(address indexed from, uint32 indexed gameRound, uint256 indexed tokenId);
    event Commit(address indexed from, uint32 indexed gameRound);
    event Reveal(address indexed from, uint32 indexed gameRound);

    error ErrorClaimInvalidBurn(uint256 tokenId);
    error ErrorClaimInvalidOwner();
    error ErrorClaimInvalidToken(uint256 tokenId);
    error ErrorClaimInvalidUser();
    error ErrorClaimMaxWallet();
    error ErrorClaimPermissionDenied();
    error ErrorClaimRoundClosed();
    error ErrorClaimUnavailable();
    error ErrorCommitInvalidUser();
    error ErrorDoNotSendDirectEth();
    error ErrorDrawAddress();
    error ErrorGameNotRunning();
    error ErrorInvalidTokenURI();
    error ErrorMintComplete();
    error ErrorMintExpired();
    error ErrorMintMaxTokens();
    error ErrorMintMaxWallet();
    error ErrorMintNotActive();
    error ErrorMintResetting();
    error ErrorMintTxAmount();
    error ErrorMintTxPrice();
    error ErrorNonRefundable();
    error ErrorTeamAddress();
    error ErrorTokenPrice();
    error ErrorTransferDenied();
    error ErrorTransferInvalidBalance();
    error ErrorTransferInvalidUser();

    constructor(
        string memory name,
        string memory symbol,
        uint32 contractId,
        uint256 tokenPrice,
        uint16 maxTokens,
        uint16 maxWallet,
        uint16 maxAmount,
        uint8 teamSplit,
        address payable teamAddress,
        address payable drawAddress,
        string memory baseTokenURI
    )
    ERC721Psi(name, symbol)
    Ownable(msg.sender)
    PullPayment()
    TimeLock(MINT_START_LOCK, MINT_LAST_LOCK)
    {
        if (tokenPrice == 0) revert ErrorTokenPrice();
        _tokenPrice = tokenPrice;
        _config = LibConfig.initConfig(
            tokenPrice,
            contractId,
            maxTokens,
            maxWallet,
            maxAmount,
            teamSplit);
        _claimSeed = uint256(uint160(msg.sender));
        _setInternalAddresses(teamAddress, drawAddress);
        _setBaseTokenURI(baseTokenURI);
        _game.initGame(_nextTokenId());
    }

    function setWallets(
        address payable teamAddress,
        address payable drawAddress
    ) external nonReentrant onlyOwner {
        _setInternalAddresses(teamAddress, drawAddress);
    }

    function setBaseURI(
        string memory newURI
    ) external onlyOwner {
        _setBaseTokenURI(newURI);
    }

    fallback() external {
        revert ErrorDoNotSendDirectEth();
    }

    //////////////////////////////////////////////////
    /// Mint
    //////////////////////////////////////////////////
    /// @notice Allows users to mint new tokens for a specific game season.
    /// @dev User can mint multiple tokens, provided the limits for transaction amount and wallet
    /// size are not exceeded and the game is not expired, in reset state, or already started.
    /// @param amount The number of tokens to mint.
    function mint(
        uint16 amount
    ) external payable nonReentrant {
        uint256 gameData = _game.data;
        uint32 gameRound = gameData.getGameRound();
        GameStatus status = _game.getStatus(gameData);
        if (amount > _config.maxAmount()) revert ErrorMintTxAmount();
        if (msg.value < _tokenPrice * amount) revert ErrorMintTxPrice();
        if (block.timestamp <= _game.virtualResetEndTime(status)) revert ErrorMintResetting();
        if (_isGameExpired(status)) revert ErrorMintExpired();
        if (gameData.gameState() != GAME_STATE_OFFLINE && status > GameStatus.RUNNING) {
            if (gameData.resetEndTime() == 0) {
                _finalizeGame(gameRound);
            }
            gameRound = _game.resetGame(_nextTokenId());
        } else if (status != GameStatus.MINTING) revert ErrorMintNotActive();
        unchecked {
            LibUser.User storage user = _users[msg.sender];
            uint256 userData = user.initUser(msg.sender, gameRound);
            if (userData.getLiveCount() + amount > _config.maxWallet()) revert ErrorMintMaxWallet();
            LibBitSet.Set storage gameTokens = _game.tokens[MINT_LIVE_INDEX];
            uint16 total = uint16(gameTokens.length()) + amount;
            uint16 maxTokens = _config.maxTokens();
            if (total > maxTokens) revert ErrorMintMaxTokens();
            gameTokens.addBatch(_nextTokenId(), amount);
            user.data = userData.addLiveCount(amount);
            _mint(msg.sender, amount);
            uint256 teamAmount = (msg.value * _config.teamSplit()) / 100;
            uint256 userAmount = msg.value - teamAmount;
            _game.prizePool += userAmount;
            _mints.addRefundableAmount(gameRound >> OFFSET_GAME_NUMBER, msg.sender, userAmount);
            _asyncTransfer(_teamAddress, teamAmount);
            if (total == maxTokens) {
                _game.startGame();
                resetTimeLock();
            }
        }
        timeLock();
    }

    //////////////////////////////////////////////////
    /// Commit
    //////////////////////////////////////////////////
    /// @notice Allows users to commit a secret hash to a running or pending game round.
    /// @dev Commits are only allowed if the game is in a RUNNING or PENDING state.
    /// @param hash The hashed secret committed by the user.
    function commit(
        bytes32 hash
    ) external nonReentrant {
        uint256 gameData = _game.data;
        uint32 gameRound = gameData.getGameRound();
        LibUser.User storage user = _users[msg.sender];
        if (user.isInvalid(gameRound)) {
            revert ErrorClaimInvalidUser();
        }
        GameStatus status = _game.getStatus();
        if (status != GameStatus.PENDING && status != GameStatus.RUNNING) {
            revert ErrorGameNotRunning();
        }
        if (status == GameStatus.PENDING) {
            if (gameData.pauseEndTime() != 0) {
                unchecked { gameRound++; }
            }
            _game.startRound(gameRound);
            status = GameStatus.RUNNING;
        }
        user.commit(gameRound, status, hash);
        emit Commit(msg.sender, gameRound);
    }

    //////////////////////////////////////////////////
    /// Reveal
    //////////////////////////////////////////////////
    /// @notice Allows users to reveal their previously committed secret.
    /// @dev This function also seeds the pseudo-random number generator.
    /// @param secret The original secret to be revealed.
    function reveal(
        bytes memory secret
    ) external nonReentrant {
        uint32 gameRound = _game.data.getGameRound();
        _users[msg.sender].reveal(gameRound, _game.getStatus(), secret);
        _randomSeed(bytes32(secret));
        emit Reveal(msg.sender, gameRound);
    }

    //////////////////////////////////////////////////
    /// Claim
    //////////////////////////////////////////////////
    /// @notice Allows a user to claim a token in exchange for burning another random unclaimed token.
    /// @dev This function also updates the internal game and user states.
    /// @param tokenId The ID of the token to be claimed.
    function claim(
        uint256 tokenId
    ) external nonReentrant {
        LibUser.User storage user = _users[msg.sender];
        LibUser.User memory claimUser = user;
        uint256 claimData = claimUser.data;
        uint256 gameData = _game.data;
        uint32 gameRound = gameData.getGameRound();
        uint256 roundEndTime = gameData.roundEndTime();
        LibBitSet.Set storage liveTokens = _game.tokens[gameRound.liveIndex()];
        uint256 liveCount = liveTokens.length();
        if (ownerOf(tokenId) != msg.sender) revert ErrorClaimInvalidOwner();
        if (liveCount <= 1) revert ErrorClaimUnavailable();
        if (claimData.getSafeCount() >= _config.maxWallet()) revert ErrorClaimMaxWallet();
        if (roundEndTime <= block.timestamp) revert ErrorClaimRoundClosed();
        if (claimData.getGameRound() != gameRound) revert ErrorClaimInvalidUser();
        if (claimUser.lastCommit <= REVEAL_THRESHOLD) revert ErrorClaimPermissionDenied();
        if (!liveTokens.remove(tokenId)) revert ErrorClaimInvalidToken(tokenId);
        uint256 safeCount = _game.tokens[gameRound.safeIndex()].add(tokenId);
        claimData = claimData.subLiveCount(1);
        claimData = claimData.addSafeCount(1);
        unchecked {
            liveCount -= 1;
            uint256 burnId = liveTokens.removeAt(_randomN(tokenId, liveCount));
            if (burnId == LibBitSet.NOT_FOUND) revert ErrorClaimInvalidBurn(burnId);
            address burnAddress = ownerOf(burnId);
            _burn(burnId);
            liveCount -= 1;
            gameData += 1;
            if (burnAddress != msg.sender) {
                uint256 burnData = _users[burnAddress].initUser(burnAddress, gameRound);
                _users[burnAddress].data = burnData.subLiveCount(1) + 1;
            } else {
                claimData = claimData.subLiveCount(1) + 1;
            }
            emit Claim(msg.sender, gameRound, tokenId);
            if (claimData.getSafeCount() != safeCount) {
                gameData = gameData.setMultiUser();
            }
            if (liveCount <= 1) {
                gameData = gameData.clearRoundEndTime();
            }
            if ((liveCount > 1) || (gameData.isMultiUser() && (safeCount > 1))) {
                uint256 pauseTime = LibShared.max(safeCount << TOKEN_DELAY_PAUSE, MIN_PAUSE_TIME);
                gameData = gameData.setPauseEndTime(
                    LibShared.max(gameData.roundEndTime(), block.timestamp) + pauseTime
                );
            }
            else {
                gameData = gameData.clearPauseEndTime() | gameData.setResetEndTime(block.timestamp + MIN_RESET_TIME);
                uint256 prize = _game.prizePool;
                _winners.recordWinner(tokenId, prize, gameRound, msg.sender);
                _asyncTransfer(msg.sender, prize);
                emit LibGame.GameOver(gameRound, msg.sender);
            }
        }
        user.data = claimData;
        _game.data = gameData;
    }

    //////////////////////////////////////////////////
    /// Finalize
    //////////////////////////////////////////////////
    /// @notice Finalizes the current game round.
    function finalize(
    ) external nonReentrant {
        _finalizeGame(_game.data.getGameRound());
    }

    //////////////////////////////////////////////////
    /// Refund
    //////////////////////////////////////////////////
    /// @notice Allows a user to claim a refund for a particular game.
    /// @param gameNumber The ID of the game to claim a refund from.
    /// @param owner The address to receive the refund.
    function refund(
        uint32 gameNumber,
        address payable owner
    ) external nonReentrant {
        uint256 amount = _mints.removeRefundableAmount(gameNumber, owner);
        if (amount == 0) revert ErrorNonRefundable();
        _asyncTransfer(owner, amount);
    }

    //////////////////////////////////////////////////
    /// Cancel
    //////////////////////////////////////////////////
    /// @notice Allows to cancel the current game once the time lock has expired.
    function cancel(
    ) external nonReentrant timeLocked {
        if (_game.getStatus() != GameStatus.MINTING) revert ErrorMintNotActive();
        if ( _game.liveTokenCount() >= _config.maxTokens()) revert ErrorMintComplete();
        _mints.cancelMint(_game.data.getGameNumber(), _game.prizePool);
        _game.cancelGame(_nextTokenId());
        resetTimeLock();
    }

    function config(
    ) external view returns (uint256 tokenPrice, uint256 data, address drawAddress) {
        return (_tokenPrice, _config, _drawAddress);
    }

    function getRefundAmount(
        uint256 gameNumber,
        address owner
    ) external view returns (uint256) {
        return _mints.getRefundableAmount(gameNumber, owner);
    }

    function canCancelGame(
    ) external view returns (uint256) {
        if (_game.getStatus() != GameStatus.MINTING) return TimeLock.MAX_LOCK;
        return timeLockLeft();
    }

    function cancelledGames(
    ) external view returns (uint256[] memory) {
        return _mints.cancelledMints();
    }

    function totalCancelledGames(
    ) external view returns (uint256) {
        return _mints.totalCancelledMints();
    }

    function cancelledGameAtIndex(
        uint256 index
    ) external view returns (uint256) {
        return _mints.cancelledMintAtIndex(index);
    }

    function isGameFinalized(
    ) external view returns (bool) {
        (, bool finalized) = _isGameFinalized(_game.data.getGameRound());
        return finalized;
    }

    function isGameExpired(
    ) external view returns (bool) {
        return _isGameExpired(_game.getStatus());
    }

    function getGameInfo(
    ) external view returns (uint256) {
        return _game.gameInfo();
    }

    function getUserInfo(
        address userAddress
    ) external view returns (uint256) {
        return _users[userAddress].getUserInfo(_game);
    }

    function getTokenStatus(
        uint256 tokenId
    ) external view returns (uint8) {
        uint8 status = _getVirtualTokenStatus(tokenId);
        if (status == TOKEN_STATUS_SECURE && _game.data.hasPauseExpired()) {
            status = TOKEN_STATUS_ACTIVE;
        } else if ((status & TOKEN_STATUS_BURNED) != 0) {
            status = TOKEN_STATUS_BURNED;
        } else if ((status & TOKEN_STATUS_WINNER) != 0) {
            status = TOKEN_STATUS_WINNER;
        }
        return status;
    }

    function isTokenOwner(
        address owner,
        uint256 idx
    ) external view override returns (bool) {
        return ownerOf(idx) == owner;
    }

    function liveTokenOfOwner(
        address owner
    ) external view returns (uint256) {
        uint256 data = _users[owner].data;
        uint32 gameRound = _game.data.getGameRound();
        if ((gameRound != data.getGameRound()) || (data.getLiveCount() == 0))
            return LibBitSet.NOT_FOUND;
        return _game.tokens[gameRound.liveIndex()].findFirstOfOwner(owner, this);
    }

    function totalWinners(
    ) external view returns (uint256) {
        uint256 total = _winners.totalWinners();
        (uint256 tokenId, bool finalized) = _isGameFinalized(_game.data.getGameRound());
        if (finalized || tokenId == LibBitSet.NOT_FOUND) return total;
        return total + 1;
    }

    function getWinnerAtIndex(
        uint256 index
    ) external view returns (LibWinners.Winner memory) {
        if (index == _winners.totalWinners()) {
            return _virtualWinner(_game.data.getGameRound());
        }
        return _winners.getWinnerAt(index);
    }

    function getWinner(
        uint32 gameNumber
    ) external view returns (LibWinners.Winner memory) {
        uint32 gameRound = _game.data.getGameRound();
        uint32 currentGame = gameRound >> OFFSET_GAME_NUMBER;
        if (gameNumber > currentGame) {
            gameNumber = currentGame;
        }
        LibWinners.Winner memory winner = _winners.getWinner(gameNumber);
        if (winner.data != 0 || gameNumber != currentGame) {
            return winner;
        }
        return _virtualWinner(gameRound);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert OperatorQueryForNonexistentToken();
        }
        uint8 slug = _getVirtualTokenStatus(tokenId);
        if (slug == TOKEN_STATUS_BANNED || ((slug & TOKEN_STATUS_BURNED) != 0)) {
            slug = TOKEN_STATUS_BURNED;
        }
        if (slug == TOKEN_STATUS_SECURE && _game.data.hasPauseExpired()) {
            slug = TOKEN_STATUS_ACTIVE;
        }
        if ((slug & TOKEN_STATUS_WINNER) != 0) {
            slug = TOKEN_STATUS_WINNER;
            tokenId = _winners.getWinnerId(tokenId);
        } else {
            tokenId %= _config.maxTokens();
        }
        return string(abi.encodePacked(
            _baseTokenURI, slug.toString(), URI_SLASH, tokenId.toString()
        ));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        if (!_approveTransfer(from, to, tokenId)) return;
        super._transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable override {
        if (!_approveTransfer(from, to, tokenId)) return;
        super._safeTransfer(from, to, tokenId, _data);
    }

    function _setInternalAddresses(
        address payable teamAddress,
        address payable drawAddress
    ) internal {
        if (teamAddress == address(0)) revert ErrorTeamAddress();
        if (drawAddress == address(0)) revert ErrorDrawAddress();
        _teamAddress = teamAddress;
        _drawAddress = drawAddress;
    }

    function _finalizeGame(
        uint32 gameRound
    ) internal returns (bool) {
        (uint256 tokenId, bool finalized) = _isGameFinalized(gameRound);
        if (finalized) return false;
        address winnerAddress = tokenId >= FORFEIT_TOKEN_ID ?
            _drawAddress : ownerOf(tokenId);
        uint256 prize = _game.prizePool;
        _winners.recordWinner(tokenId, prize, gameRound, winnerAddress);
        _asyncTransfer(winnerAddress, prize);
        emit LibGame.GameOver(gameRound, winnerAddress);
        return true;
    }

    function _isGameFinalized(
        uint32 gameRound
    ) internal view returns (uint256, bool) {
        uint256 tokenId = _game.isGameOver(gameRound);
        return (tokenId, tokenId == LibBitSet.NOT_FOUND || _winners.hasWinner(tokenId));
    }

    function _isGameExpired(
        GameStatus status
    ) internal view returns (bool) {
        return (status == GameStatus.MINTING) && timeLockExpired();
    }

    function _getVirtualTokenStatus(
        uint256 tokenId
    ) internal view returns (uint8) {
        if (_winners.hasWinner(tokenId)) return TOKEN_STATUS_WINNER;
        uint8 status = _game.getTokenStatus(tokenId);
        if ((status & (TOKEN_STATUS_ACTIVE | TOKEN_STATUS_SECURE)) != 0) {
            uint256 winnerId = _game.isGameOver(_game.data.getGameRound());
            if (winnerId != LibBitSet.NOT_FOUND) {
                return status | (winnerId == tokenId ? TOKEN_STATUS_WINNER : TOKEN_STATUS_BURNED);
            }
        }
        return status;
    }

    function _approveTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal returns (bool) {
        if ((from == to) || !_isApprovedOrOwner(msg.sender, tokenId)) revert TransferFromIncorrectOwner();
        uint8 tokenStatus = _getVirtualTokenStatus(tokenId);
        if (tokenStatus == TOKEN_STATUS_BANNED || ((tokenStatus & TOKEN_STATUS_BURNED) != 0)) {
            _burn(tokenId);
            return false;
        }
        if ((tokenStatus & TOKEN_STATUS_WINNER) != 0) return true;
        if (_game.getStatus() == GameStatus.RUNNING) revert ErrorTransferDenied();
        uint32 gameRound = _game.data.getGameRound();
        LibUser.User storage fromUser = _users[from];
        if (fromUser.isInvalid(gameRound)) revert ErrorTransferInvalidUser();
        uint256 fromData = fromUser.initUser(from, gameRound);
        if ((tokenStatus & (TOKEN_STATUS_ACTIVE | TOKEN_STATUS_QUEUED)) != 0) {
            if (fromData.getLiveCount() == 0) revert ErrorTransferInvalidBalance();
            fromData = fromData.subLiveCount(1);
        } else if ((tokenStatus & TOKEN_STATUS_SECURE) != 0) {
            if (fromData.getSafeCount() == 0) revert ErrorTransferInvalidBalance();
            fromData = fromData.subSafeCount(1);
        }
        fromUser.data = fromData;
        LibUser.User storage toUser = _users[to];
        uint256 toData = toUser.initUser(to, gameRound);
        if ((tokenStatus & (TOKEN_STATUS_ACTIVE | TOKEN_STATUS_QUEUED)) != 0) {
            toData = toData.addLiveCount(1);
        } else if ((tokenStatus & TOKEN_STATUS_SECURE) != 0) {
            toData = toData.addSafeCount(1);
        }
        toUser.data = toData;
        return true;
    }

    function _setBaseTokenURI(
        string memory newURI
    ) private {
        if (bytes(newURI).length < 10) revert ErrorInvalidTokenURI();
        _baseTokenURI = newURI;
    }

    function _virtualUserOf(
        address owner
    ) private view returns (LibUser.User storage, uint32) {
        LibUser.User storage user = _users[owner];
        uint32 gameRound =_game.data.getGameRound();
        return (user, user.isExpired(gameRound) ? 0 : gameRound);
    }

    function _virtualWinner(
        uint32 gameRound
    ) private view returns (LibWinners.Winner memory) {
        LibWinners.Winner memory winner;
        uint256 tokenId = _game.isGameOver(gameRound);
        if (tokenId == LibBitSet.NOT_FOUND) return winner;
        bool draw = tokenId >= FORFEIT_TOKEN_ID;
        address winAddress = draw ? _drawAddress : ownerOf(tokenId);
        gameRound ^= (gameRound & uint32(LibShared.MASK_ROUND));
        winner.data = _winners.packWinnerData(gameRound, winAddress);
        winner.tokenId = draw ? 0 : tokenId;
        winner.prize = _game.prizePool;
        return winner;
    }

    function _randomSeed(
        bytes32 seed
    ) private {
        unchecked {
            _claimSeed = uint256(keccak256(abi.encodePacked(
                _claimSeed, block.prevrandao, msg.sender, block.timestamp, seed, tx.gasprice,
                blockhash(block.number - (uint256(seed) % (block.number < 255 ? block.number - 1 : 255) + 1)))));
        }
    }

    function _randomN(
        uint256 nonce,
        uint256 max
    ) private view returns (uint256 result) {
        return LibPRNG.PRNG({state: uint256(keccak256(
            abi.encodePacked(nonce, block.prevrandao, msg.sender, block.timestamp, _claimSeed)
        ))}).uniform(max);
    }
}
