// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./MoonrayComicChapterOneBase.sol";
import "./MoonrayComicChapterOneSplits.sol";

/**
 * @title MoonrayComicChapterOne
 *  ,                         ////              ////,         ,          //   //////////                         ///        .///
 *  ██*          *██\    (███████████*      .███████████*    \███       (██*   /██████████(        (██           /████    ,████
 *  /████      █████\   ███        /███    ███=       .███b    ████     (██*           .███        ████(            ████ ████
 *     \███\/███████\  ███\         .██\  *██(         /███      \████* (██*          .#███      ███\ ███            /█████
 *       /████/  ███\  ███/         ███,  #███         /███         ███████*        █████.      ███/  \███.          ████
 *               ███\   \███/    ,\███.    █████,     ████            \████*         \███     =███\                ████.
 *               ███\     ██████████=        /█████████(                 \█*          \███,  /███        =███    ████
 */
contract MoonrayComicChapterOne is MoonrayComicChapterOneSplits, MoonrayComicChapterOneBase {
    constructor()
        MoonrayComicChapterOneBase(
            'MoonrayComicChapter1',
            'MCC1',
            'https://nftculture.mypinata.cloud/ipfs/QmXkagNmTEzzmWTvWDi3As5hXStmKLu9Xx3mxk3fBYQodp/',
            addresses,
            splits,
            0.02 ether,
            0.02 ether
        )
    {
        // Implementation version: 1
    }
}