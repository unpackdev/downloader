
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NiftyRiffs Metaverse Guitars
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                           ,;;;;;                                           //
//                                                      ,   ,;::,:;;                                          //
//                                                    ,;;r;rr;;;;;;;r;                                        //
//                                                     ,,,rrr;;;rSr;;r                                        //
//                                                    :,  ;;2;;:;;;;r;                                        //
//                                                   ;;r;;;;;;;;:;;rr,                                        //
//                                                   ,;,;r;;;;;;;;r;,                                         //
//                                                   ,  ;;r2;;;;;,                                            //
//                                                 ,;;r,;:;;;:;;;                                             //
//                                                  ,::r;;;;;;;;;                                             //
//                                                ,:  ,;r5;;;:;;;,                                            //
//                                                ::;:;::;;;:;,;;;                                            //
//                                                 ,,rrr;;;::,;r;;,                                           //
//                                               :,  ;;3;;::,::rr::                                           //
//                                              ::r;::;:;:;rrr;;r:;                                           //
//                                               ,,;rr;;;;:;:;,,5;;,                                          //
//                                             ,:  ::rr;;:;::,;;3;;:                                          //
//                                            ,;;r:;,;:::;:;::;r;;r;                                          //
//                                             ,,,rrr;;::::::::;r;,                                           //
//                                               :;r5;:, ,,:,;;;                                              //
//                                              ,;;:;,:,35 ,;;:                                               //
//                                               ;;;;;:;BM;;;;                                                //
//                                                 :5rrrMBrr5;                                                //
//                                                  ;;:,,,,:;:                                                //
//                                                  ;,,,, ,,:,                                                //
//                                                  ;;:;::,:;:                                                //
//                                                  ;;:,:,::;,                                                //
//                                                  ;;::,,::::                                                //
//                                                  rrr;r;r;r;                                                //
//                                                  ;;,::,,:;:                                                //
//                                                  ;::,:,,,:,                                                //
//                                                  :;,,,,,,,,                                                //
//                                                 ,r;;;;;;;;;                                                //
//                                                 ,;;;;,,;;;;                                                //
//                                                  ;:,,X;, ,,                                                //
//                                                  ;:,,r;,,,,                                                //
//                                                 ,r;;;::;;;:                                                //
//                                                 ,;;;;:;;;;;                                                //
//                                                  ;,,,,,: ,,                                                //
//                                                  ;,,,,,:,,,                                                //
//                                                 :r;;;;;r;r;                                                //
//                                                 ,;;,,,,::;;                                                //
//                                                 ,;,,,B:,,,,                                                //
//                                                 :;;:,;,::::                                                //
//                                                 ;r;;;;;r;r;                                                //
//                                                 ,:,,,, ,,,,                                                //
//                                                 ,;,,,, : ,,                                                //
//                                                 ;r;;;;;;;r;                                                //
//                                                 :;,;,r,:,;:                                                //
//                                                 ::,,;h:  ,:                                                //
//                                                 ;r;;;:;;;r;                                                //
//                                                 ;;:;::,::;;                                                //
//                                                 :: , ,   ,,                                                //
//                                                 rr;;;:;;;;;                                                //
//                                                 ;;,;:r,::;,                                                //
//                                                 ::,,;h,   ,                                                //
//                                                 ;r;r;;;;;r;                                                //
//                                                 ;;,,,,,,,;:                                                //
//                                                 ;;::,:,:,;;                                                //
//                                                ,r;;;;;;;;rr                                                //
//                                                 ,, , , , ,:                                                //
//                                                ,r;:;;;;:;;;                                                //
//                                                ,;:3r,;,Sr::                                                //
//                               :                ,;:5r::,3r:;                                                //
//                              ;rr,              :r;,;;;;:,;;                                                //
//                          ;@MMM@r               ,;,:,,,,,,,,                                                //
//                         @BhMB93M               :rr;r;r;;;r;                                                //
//                        Bh5MMM9;B               ,;,:,,,,,,,:                                                //
//                       3M;MMMMB:M,              ;rr;;;r;;;r;                                                //
//                       Mr@MMBMM,Mr              ,;,, rh,,,,;                                                //
//                      :M;BMBMBM;AB              ;r;;;;;;r;rr,                                               //
//                      rM;MBMBMMB;Mh             ,;::,,,,:;;:                                                //
//                      rBrBMBBBMB@rMM;           ;;;;;r3:;;r;                  :rr:                          //
//                      ;M;MMMBMBMMM@MBBr,      ;M;;:;,r9,::;;                 @MMMMB;                        //
//                       M;BMBBBMBMBMBBBMMMMBBBMMM,:;;;,,:;:;;                rM5MrBhB;                       //
//                       BrXMBBMBMBBBMBM@@@MMMBMMM,;;;;;;;;;;;                BrB5 ,MrM                       //
//                       ;BrMMMBMBMBMBMBMMMMMBMMMB,;;;,S@,;:;;               ;MrM,, 33Ar                      //
//                        Br@MMBBMBMBBBBBMBB    rG:;;;;;;;;;;;               M5M9   :9rS                      //
//                        r@rBMBMBMBBBMBMBM@      ;;;;;;;:;:;:r            rMS9B    :9r3                      //
//                         Mr@BMBMBMBBBBBBMM;    ,;r;;:X@:;;;,@MXr:, ,,;rhMMh@9     rXSr                      //
//                         ;BrMMMBMBMBBBBBMB@   ,:;r;;;;;;r;;:rBMMMBMBMMMBMBh;  ,   hr@                       //
//                          929MBMBBBMBBBBBMM  ,,:;rrrrrrrrrrr ,;:rXhB@hS5;    ,   :@rS                       //
//                           BrMMBMBBBBBBBBBM:  ,   ,,,,,,, ,  ,              , ,  @39,                       //
//                           33SMMBMBBBBBBBMM; ; ,, , ,, , , ,  ,        , , ,, ;,5@S2                        //
//                            B;MMMBMBBBMBBMM; r,;;,r,r:;;,r,r;,3:,,,,,,,,,,,,,  ;M5X                         //
//                            S2AMBMBBBBBMBMM;  , ,, , ,  ,,,  , , ,,,,,,,,,,,  ,M3h                          //
//                            r9rBMBBBBBBBMMM   , , , , , , , , , ,,,,,,,,,,,   BSh,                          //
//                            :B;MMMBMBBBBMMS  ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,, 2B3r                           //
//                            ;@rBMBBBBBBBMB  ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,  B29                            //
//                            SSrMMMBBBBBMMr , , , ,,, ,,,,,,,,, ,,,,,,, ,,,, ,Mr9                            //
//                            M;@MMBBBMBMM@ ;, ,, , ,,    , , ,,  ,,,,,,,,,,, ;Mr@                            //
//                           3X;MMBMBBBMMM    ;5,r;;r:5;rr:3,2;:5, ,,,,: ,,,,  Mr@,                           //
//                          ,M:BMBMBBBBMM:  ,,,,,,,,:,,,:,::::::;,,,, ,:,,,,,  SBr@                           //
//                          M;SMBMBBBBBMr  ,,, , ,,,,,,,,,,,,,,,,,,,,,,r , , ,  Mr93                          //
//                         @3rMBMBBBBBMB  ,,,,,,,,,,,,,,,,,,,,,,,,,,, :r,,; , ;;;M;Br                         //
//                        S9;MMMBBBBBMB; , , , ,,,,,,,,,,,,,,,,,,,,,,,,; ,;;, ,, AM;M;                        //
//                       rM:MMMBBBBBMBM ;; ,,,,,, ,   ,,, ,,,,,,,,,,, ;;,,,:r,    BB;M:                       //
//                      :M:@MBBBBBBBBMB   ,,,,;5,r:;;,,,       , , , ,;,,,:;:,;;,  M@;B                       //
//                      M;SMM@BBBBBBBBB   ,,,,,;,;;;;;2:3;;;,;,:;,,,,;:,,,:,,,,;r:  M3rM                      //
//                     M5rMMBBBBBBBBBMB  ,,,,,,,,,,,,:,:;,;;:r,5h; ,:; ;::,,,,,,;:  :Mr59                     //
//                    SB;BMBMBBBBBBBBMM3   ,,,,     , , ,,, , ,:;;;:;::;;,:,,,,,,,,;,rM:h;                    //
//                   ,M;@MMMBBBMBBBBBMMMr      ;;;;;;;:;:;;;;;;;  ,;::,;;;;:,, ,,,,;, @M,B                    //
//                   BArMMMBBBBBBBMBMBBMM9, ;  ;r3,,;:;::,;,,rA,,;      ;r;,;;,,;::,, ,B3r3                   //
//                   M;MBBBMBBBBBBBMBBBMMMMM9A@; ;;;;r;r;;;;;r; 3r;2;;:,,,,:,::;::,,,, rB;@,                  //
//                  3ArBMBMBBBBBMBBBMBMBMMMMMMM; r;:r,r,;;:r ;, r BBMMMMM@5:  ,,,,:,,   M3r3                  //
//                  X3BMBBBBBMBBBBBMBMBMBBBMMMB, ;;;;;;r;;;r;; ;; AMBMMMMMBM@r  :; ,:,  3M;9                  //
//                  BMMBBBBBBBBBBBMBBBBBBBMBBMMr::rr;;,r;;;:3:;rr,9BMBMBMBMMMMMr:,:,;,, ;MrS:                 //
//                  BMMMBBBBBBBBBMBMBBBBBMBMBMMMMMMMMMBMMMMBMBMMMMBMM;    ;XMMMMM3:  ,r ,M53;                 //
//                  MMMBBBBBBBBBMBMBMBMBBBMBBBMMMMMBMMMMMBMBMMMBMMMM@     ,,:rMBMBM3;,:;BMA5;                 //
//                  BMMBBMBMBMBBBBBMBMBBBBBBBMBMBMBBBMBMBMBMBMBMBBBMMr  ,;3r;; 2BMBMBMBMBMS3;                 //
//                  rMMBMBMBBBMBBBMBMBMBMBMBMBMBMBBBMBBBMBBBBBMBBBBBMMh, ;rr::,  9MBMBMMMM3A,                 //
//                   MMMBBBMBMBMBMBBBBBMBBBMBMBBBMBBBMBMBMBBBBBBBBBMBMMMS,,   ,;  rMMMBMMMGh                  //
//                    MMMMMBBBMBMBMBBBBBBBMBBBMBMBMBMBBBMBMBMBMBBBMBMBMMMBh;   :,  rMBBBMBM,                  //
//                     MMMMMBMBMBMBMBMBBBBBBBMMMBMBMBBBMBMBMBMBMBMBBBMBMMMMMB@5r;  ;MMBMMMr                   //
//                      3BMMMMMBMBMBMBMBBBBBBBBBBBBBMBMBMBMBBBMBBBBBBBBBBBMMMBMMMMMMMBMMMr                    //
//                        SMBMMMBMBMBMBMBMBBBBBBBBBMBMBMBMBBBBBMBMBMBMBMBMBBBMMMMMMMMMBM;                     //
//                          rMMMMMMMMMMBBBMBMBBBBBBBBBMBMBMBMBMBMBBBMBBBBBBBMBMBMBMMMM3                       //
//                             2BMMMMMBMMMMMBMMMMMMMBBBMBMBMBMBMBMBMBMBMBMBMMMBMMMBMr                         //
//                                ;r9BMBMMMMMBMMMMMBMBMMMMMMMMMMMMMMMMMMMMMBMMMBBr,                           //
//                                      ,;rr3AX@BMMMBMMMMMBMMMMMMMMMMMMMMM@Ar;                                //
//                                                    ,;,                                                     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RIFF is ERC721Creator {
    constructor() ERC721Creator("NiftyRiffs Metaverse Guitars", "RIFF") {}
}
