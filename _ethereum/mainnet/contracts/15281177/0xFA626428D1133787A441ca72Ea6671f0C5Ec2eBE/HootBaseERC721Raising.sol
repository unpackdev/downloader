// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                 +
+                                                                                                                 +
.                        .^!!~:                                                 .^!!^.                            .
.                            :7Y5Y7^.                                       .^!J5Y7^.                             .
.                              :!5B#GY7^.                             .^!JP##P7:                                  .
.   7777??!         ~????7.        :5@@@@&GY7^.                    .^!JG#@@@@G^        7????????????^ ~????77     .
.   @@@@@G          P@@@@@:       J#@@@@@@@@@@&G57~.          .^7YG#@@@@@@@@@@&5:      #@@@@@@@@@@@@@? P@@@@@@    .
.   @@@@@G          5@@@@@:     :B@@@@@BJG@@@@@@@@@&B5?~:^7YG#@@@@@@@@BJP@@@ @@&!!     #@@@@@@@@@@@@@? P@@@@@@    .
.   @@@@@G          5@@@@@:    .B@@@@#!!J@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@P   ^G@@@@@~.   ^~~~~~^J@ @@@@??:~~~~~    .
.   @@@@@B^^^^^^^^. 5@@@@@:   J@@@@&^   G@7?@@@@@@&@@@@@@@@@@@&@J7&@@@@@#.   .B@@@@P           !@@@@@?            .
.   @@@@@@@@@@@@@@! 5@@@@@:   5@@@@B   ^B&&@@@@@#!#@@@@@@@@@@7G&&@@@@@#!     Y@@@@#.           !@@@@@?            .
.   @@@@@@@@@@@@@@! P@@@@@:   ?@@@@&^    !YPGPY!  !@@@@@Y&@@@@Y  ~YPGP57.    .B@@@@P           !@@@@@?            .
.   @@@@@B~~~~~~~!!.?GPPGP:   .B@@@@&7           ?&@@@@P ?@@@@@5.          ~B@@@@&^            !@@@@@?            .
.   @@@@@G          ^~~~~~.    :G@@@@@BY7~^^~75#@@@@@5.    J@@@@@&P?~^^^!JG@@@@@#~             !@@@@@?            .
.   @@@@@G          5@@@@@:      ?B@@@@@@@@@@@@@@@@B!!      ^P@@@@@@@@@@@@@@@@&Y               !@@@@@?            .
.   @@@@@G.         P@@@@@:        !YB&@@@@@@@@&BY~           ^JG#@@@@@@@@&#P7.                !@@@@@?            .
.   YYYYY7          !YJJJJ.            :~!7??7!^:                 .^!7??7!~:                   ^YJJJY~            .
.                                                                                                                 .
.                                                                                                                 .
.                                                                                                                 .
.                                  ………………               …………………………………………                  …………………………………………        .
.   PBGGB??                      7&######&5            :B##############&5               .G#################^      .
.   &@@@@5                      ?@@@@@@@@@@           :@@@@@@@@@@@@@@@@@G               &@@@@@@@@@@@@ @@@@@^      .
.   PBBBBJ                 !!!!!JPPPPPPPPPY !!!!!     :&@@@@P?JJJJJJJJJJJJJJ?      :JJJJJJJJJJJJJJJJJJJJJJ.       .
.   ~~~~~:                .#@@@@Y          ~@@@@@~    :&@@@@7           ~@@@&.      ^@@@@.                        .
.   #@@@@Y                .#@@@@G?JJJJJJJJ?5@@@@@~    :&@@@@7   !JJJJJJJJJJJJ?     :JJJJJJJJJJJJJJJJJ!!           .
.   #@@@@Y                .#@@@@@@@@@@@@@@@@@@@@@@~   :&@@@@7   G@@@@@@@@G &@@             @@@@@@@@@@P            .
.   #@@@@Y                .#@@@@&##########&@@@@@~    :&@@@@7   7YYYYYYYYJ???7             JYYYYYYYYYYYYJ???7     .
.   #@@@@Y                .#@@@@5 ........ !@@@@@~    :&@@@@7            ~@@@&.                         !@@@#     .
.   #@@@@#5PPPPPPPPPJJ    .#@@@@Y          !@@@@@~    :&@@@@P7??????????JYY5J      .?????????? ???????JYY5J       .
.   &@@@@@@@@@@@@@@@@@    .#@@@@Y          !@@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@@@P            .
.   PBBBBBBBBBBBBBBBBY    .#@@@@Y          !@@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@ @@5           .
+                                                                                                                 +
+                                                                                                                 +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./HootBase.sol";
import "./HootBaseERC721Owners.sol";

/**
 * @title HootBaseERC721Raising
 * @author HootLabs
 */
abstract contract HootBaseERC721Raising is
    HootBase,
    HootBaseERC721Owners,
    IERC721
{
    event RaisingStatusChanged(
        uint256 indexed tokenId,
        address indexed owner,
        uint16 indexed raisingType,
        bool isStart
    );
    event RaisingInterrupted(uint256 indexed tokenId, address indexed operator);
    event RaisingTokenTransfered(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event RaisingAllowedFlagChanged(
        bool isRaisingAllowed,
        bool isRaisingTransferAllowed
    );

    struct RaisingStatus {
        uint256 raisingStartTime;
        uint256 total;
        uint16 raisingType;
        bool provisionalFree;
    }
    struct RaisingCurrentStatus {
        uint256 total;
        uint256 current;
        uint16 raisingType;
        bool isRaising;
    }
    mapping(uint256 => RaisingStatus) private _raisingStatuses;
    bool public isRaisingAllowed;
    bool public isRaisingTransferAllowed;

    /***********************************|
    |               Raising Config      |
    |__________________________________*/
    /**
     * @notice setIsRaisingAllowed is used to set the global switch to control whether users are allowed to brew.
     * @param isRaisingAllowed_ set to true to allow
     */
    function setIsRaisingAllowed(
        bool isRaisingAllowed_,
        bool isRaisingTransferAllowed_
    ) external atLeastMaintainer {
        isRaisingAllowed = isRaisingAllowed_;
        isRaisingTransferAllowed = isRaisingTransferAllowed_;
        emit RaisingAllowedFlagChanged(
            isRaisingAllowed_,
            isRaisingTransferAllowed_
        );
    }

    /***********************************|
    |               Raising Core        |
    |__________________________________*/
    /**
     * @notice safeTransferWhileRaising is used to safely transfer tokens while raising
     * @param from_ transfer from address, cannot be the zero.
     * @param to_ transfer to address, cannot be the zero.
     * @param tokenId_ token must exist and be owned by `from`.
     */
    function safeTransferWhileRaising(
        address from_,
        address to_,
        uint256 tokenId_
    ) external nonReentrant {
        require(this.ownerOf(tokenId_) == _msgSender(), "caller is not owner");
        require(
            isRaisingTransferAllowed,
            "transfer while raising is not enabled"
        );
        _raisingStatuses[tokenId_].provisionalFree = true;
        this.safeTransferFrom(from_, to_, tokenId_);
        _raisingStatuses[tokenId_].provisionalFree = false;
        if (_raisingStatuses[tokenId_].raisingStartTime != 0) {
            emit RaisingTokenTransfered(from_, to_, tokenId_);
        }
    }

    /**
     * @notice getTokenRaisingStatus is used to get the detailed raising status of a specific token.
     * @param tokenIDs_ token id
     * @return RaisingCurrentStatus[] how long the token has been raising in the hands of the current hodler.
     */
    function getTokenRaisingStatus(uint256[] calldata tokenIDs_)
        external
        view
        returns (RaisingCurrentStatus[] memory)
    {
        RaisingCurrentStatus[] memory statusList = new RaisingCurrentStatus[](tokenIDs_.length);
        for (uint256 i = 0; i < tokenIDs_.length; ++i) {
            uint256 tokenId = tokenIDs_[i];
            if(!this.exists(tokenId)){
                continue;
            }
            RaisingStatus memory status = _raisingStatuses[tokenId];
            if (status.raisingStartTime != 0) {
                statusList[i].isRaising = true;
                statusList[i].raisingType = status.raisingType;
                statusList[i].current = block.timestamp - status.raisingStartTime;
            }
            statusList[i].total = status.total + statusList[i].current;
        }
        return statusList;
    }

    function _isTokenRaising(uint256 tokenId_) internal view returns (bool) {
        return _raisingStatuses[tokenId_].raisingStartTime != 0;
    }

    /**
     * @notice setTokenRaisingState is used to modify the Raising state of the Token,
     * only the Owner of the Token has this permission.
     * @param tokenIds_ list of tokenId
     */
    function doTokenRaising(
        uint256[] calldata tokenIds_,
        uint16 raisingType_,
        bool isStart_
    ) external nonReentrant {
        if (isStart_) {
            require(isRaisingAllowed, "raising is not allowed");
        }
        unchecked {
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                uint256 tokenId = tokenIds_[i];
                require(
                    this.ownerOf(tokenId) == _msgSender(),
                    "caller is not owner"
                );

                RaisingStatus storage status = _raisingStatuses[tokenId];
                uint256 raisingStartTime = status.raisingStartTime;
                if (isStart_) {
                    if (raisingStartTime == 0) {
                        status.raisingStartTime = block.timestamp;
                        status.raisingType = raisingType_;
                        emit RaisingStatusChanged(
                            tokenId,
                            _msgSender(),
                            raisingType_,
                            isStart_
                        );
                    } else {
                        require(
                            status.raisingType == raisingType_,
                            "raising is already started, but with a different raising type set"
                        );
                    }
                } else {
                    if (raisingStartTime > 0) {
                        status.total += block.timestamp - raisingStartTime;
                        status.raisingStartTime = 0;
                        emit RaisingStatusChanged(
                            tokenId,
                            _msgSender(),
                            raisingType_,
                            isStart_
                        );
                    }
                }
            }
        }
    }

    /**
     * @notice interruptTokenRaising gives the issuer the right to forcibly interrupt the raising state of the token.
     * One scenario of using it is: someone may maliciously place low-priced raising tokens on
     * the secondary market (because raising tokens cannot be traded).
     * @param tokenIds_ the tokenId list to operate
     */
    function interruptTokenRaising(uint256[] calldata tokenIds_)
        external
        nonReentrant
        atLeastMaintainer
    {
        unchecked {
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                uint256 tokenId = tokenIds_[i];
                address owner = this.ownerOf(tokenId);
                RaisingStatus storage status = _raisingStatuses[tokenId];
                if (status.raisingStartTime == 0) {
                    continue;
                }
                status.total += block.timestamp - status.raisingStartTime;
                status.raisingStartTime = 0;
                emit RaisingStatusChanged(
                    tokenId,
                    owner,
                    status.raisingType,
                    false
                );
                emit RaisingInterrupted(tokenId, _msgSender());
            }
        }
    }

    function _beforeTokenTransfer(
        address, /*from_*/
        address, /*to_*/
        uint256 tokenId_
    ) internal virtual {
        if (_isTokenRaising(tokenId_)) {
            require(
                _raisingStatuses[tokenId_].provisionalFree,
                "token is raising"
            );
        }
    }

    function _beforeTokenTransfers(
        address, /*from_*/
        address, /*to_*/
        uint256 startTokenId_,
        uint256 quantity_
    ) internal virtual {
        for (uint256 i = 0; i < quantity_; ++i) {
            if (_isTokenRaising(startTokenId_ + i)) {
                require(
                    _raisingStatuses[startTokenId_ + i].provisionalFree,
                    "token is raising"
                );
            }
        }
    }
}
