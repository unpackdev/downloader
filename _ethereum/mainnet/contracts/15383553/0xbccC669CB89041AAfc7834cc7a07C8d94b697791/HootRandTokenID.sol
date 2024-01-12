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

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * @title Hootbirds
 * @author HootLabs
 */
abstract contract HootRandTokenID is ReentrancyGuard, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 5831;
    uint256[MAX_SUPPLY] internal _randIndices; // Used to generate random tokenids

    constructor() {}

    /***********************************|
    |               abstract            |
    |__________________________________*/
    function _remainSupply() internal view virtual returns (uint256);

    /***********************************|
    |               RandomTokenId       |
    |__________________________________*/
    function init(uint256 startIndex, uint256 stopIndex) external onlyOwner {
        unchecked {
            for(uint256 i=startIndex; i<stopIndex; i++){
                _randIndices[i] = i+1;
            }
        }
    }
    function freeStores() external virtual onlyOwner nonReentrant {
        require(_remainSupply() == 0, "there is some token left");
        delete _randIndices;
    }
    function _genTokenId() internal returns (uint256 tokenId_) {
        uint256 remain = _remainSupply();
        require(remain > 0, "tokenId has been exhausted");
        unchecked {
            tokenId_ = _changePos(remain-1, _unsafeRandom(remain) % remain);
        }
    }
    function _genTokenIdBatch(uint256 supply) internal returns (uint256[] memory){
        require(supply > 0, "tokenId has been exhausted");

       uint256 remain = _remainSupply();
       require(supply <= remain, "not enough tokenIDs");

       uint256[] memory tokenIDs = new uint256[](supply);
       unchecked {
            for(uint256 i=0;i<supply; i++){
                tokenIDs[i] = _changePos(remain-i-1, _unsafeRandom(i) % (remain-i));
            }
       } 
       return tokenIDs;
    }
    function _genFirstTokenId() internal returns (uint256 tokenId_){
        require(_remainSupply() == _randIndices.length, "the first tokenId already generated");
        return _changePos(_randIndices.length-1, 0);
    }
    function _changePos(uint256 lastestPos, uint256 pos) private returns (uint256) {
        uint256 val = _randIndices[pos];
        _randIndices[pos] = _randIndices[lastestPos];
        _randIndices[lastestPos] = val;
        return val;
    }
    function _unsafeGetTokenIdByIndex(uint256 index_) internal view returns (uint256) {
        if(index_ >= _randIndices.length){
            return 0;
        }
        return _randIndices[_randIndices.length - index_ - 1];
    }

    /***********************************|
    |               Util               |
    |__________________________________*/
    /**
     * @notice unsafeRandom is used to generate a random number by on-chain randomness.
     * Please note that on-chain random is potentially manipulated by miners, and most scenarios suggest using VRF.
     * @return randomly generated number.
     */
    function _unsafeRandom(uint256 n) private view returns (uint256) {
        unchecked {
            return
                uint256(
                    keccak256(
                        abi.encodePacked(
                            blockhash(block.number - 1),
                            block.difficulty,
                            block.timestamp,
                            block.coinbase,
                            n,
                            tx.origin
                        )
                    )
                );
        }
    }
}