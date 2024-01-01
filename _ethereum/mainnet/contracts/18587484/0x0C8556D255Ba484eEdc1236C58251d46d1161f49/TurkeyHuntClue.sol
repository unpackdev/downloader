// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * Turkey Hunt Club 
 * TG: https://t.me/turkeyhuntclub
 * TW: https://twitter.com/turkeyhuntclub
 * WE: https://www.turkeyhunt.club/
 * 
 * Can you find all the clues? 
 * 
 * Join the turkey hunt. We have stashed away 6 wallets with varying degrees of tokens. The private
 * keys have been split into 3 pieces and seeded on the website, twitter, telegram, medium and within 
 * this contract. 
 * 
 * Not all parts have been seeded on launch. 
 * 
 * Initial launch procedure will be as follows: 
 *  - initial launch tax will be fairly high
 *  - tax will be reduced over time
 *  - final tax will be 3/3 and paid into MW for pushing the project
 *  - after 3/3 the project will be renounced
 * 
 * 
                     .--.
    {\             / q {\
    { `\           \ (-(~`
   { '.{`\          \ \ )
   {'-{ ' \  .-""'-. \ \
   {._{'.' \/       '.) \
   {_.{.   {`            |
   {._{ ' {   ;'-=-.     |
    {-.{.' {  ';-=-.`    /
     {._.{.;    '-=-   .'
      {_.-' `'.__  _,-'
         jgs   |||`
              .='==,
 */


contract TurkeyHuntClue {
    /**
     * Keep on searching, there are others out there. 
     */
    function getWallet5Part3() public pure returns (string memory) {
        return "afd787d07ee5b920b070cb76bc42cd4f3";
    }
}