// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

abstract contract Creators {

    address internal constant evolution = 0x48a4C0ddC37Cfb27F8C8182A124589F55125cD8c;
    address internal constant devs = 0x1839EEFA9c73a8a06674cAd1679D0907cCA518e0;
    address internal constant artist = 0x243B020703A2f9E26a809480d3617f04885924d8;
    address internal constant storyTeller = 0x189cd71521A92F548b228Ee142A320778a41818f;
    address internal constant social = 0xD364062E23aBc71Cfd1e8343264666AfE452e828;
    address internal constant ceo = 0x535C2Ab2180226315F02077b425c1b7aAF42fd5a;
    address internal constant payback = 0x9F332F7406C6933d398c23e1B0b86B44F499e4a1;

    function isCreator(address operator) public pure virtual returns (bool) {
        return operator == devs;
    }
}
