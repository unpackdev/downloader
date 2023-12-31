pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT


// Imports
import "./TinyStrings.sol";
import "./Math.sol";
import "./Options.sol";
import "./BetStorage.sol";
import "./GameOptions.sol";
import "./PackedBets.sol";
import "./ContractState.sol";
import "./VRF.sol";

/**
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * *                                                                                                                                   * *
 * *                                                      Welcome to dice9.win!                                                        * *
 * *                                                                                                                                   * *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 * Summary
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Inspired by many projects in the Ethereum ecosystem, this smart contract implements a set of robust, provably fair games of chance.
 * The users can play one of four available games, wagering cryptocurrency at the odds they choose and even take part in Jackpot rolls!
 *
 * Coin Flip
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * This game allows to choose a side of the coin – heads or tails – and bet on it. Once the bet settles, the winning amount is paid if the
 * side matches the one chosen by the player.
 *
 * Dice
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * This game allows to choose 1 to 5 numbers of a dice cube and wins if a dice roll ends up with one of those numbers. The more numbers
 * are chosen the higher is the chance of winning, but the multiplier is less.
 *
 * Two Dice
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * This game allows to choose 1 to 11 numbers representing the sum of two dice. Similar to Dice game, if two dice add up to one of the
 * numbers chosen, the winnings are paid back.
 *
 * Etheroll
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * This game allows to place a bet on a number in 3 to 97 range, and if the random number produced (from 1..100 range) is less or equal
 * than the chosen one, the bet is considered a win.
 *
 * Winnings
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * If a bet wins, all the funds (including Jackpot payment, if it was eligible and won the Jackpot) are paid back to the address which
 * made the bet. Due to legal aspects, we do not distribute the winnings to other address(es), other currencies and so on.
 *
 * Jackpots
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * If a bet exceeds a certain amount (the UI will display that), a tiny Jackpot fee is taken on top of default House commission and the
 * bet automatically plays for Jackpot. Jackpots are events that have 0.1% chance of happening, but if they do, the bet gets an extra
 * portion of the winnings determined by Jackpot logic. The Jackpot rolls are completely independent from the games themselves, meaning
 * if a bet that lost a game can still get a Jackpot win.
 *
 * Commisions
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * In order to maintain the game, which includes paying for bet resolution transactions, servers for the website, our support engineers
 * and developers, the smart contract takes a fee from every bet. The specific amounts can be seen below in the constants named
 * HOUSE_EDGE_PERCENT, HOUSE_EDGE_MINIMUM_AMOUNT and JACKPOT_FEE.
 *
 * Questions?
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Please feel free to refer to our website at https://dice9.win for instructions on how to play, support channel, legal documents
 * and other helpful things.
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * *                                                                                                                                   * *
 * *                                               Good luck and see you at the tables!                                                * *
 * *                                                                                                                                   * *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 */
contract Dice9 {
  // Extension functions
  using TinyStrings for TinyString;
  using TinyStrings for string;
  using GameOptions for GameOption;
  using PackedBets for PackedBet;
  using ContractState for ContractState.State;
  using Math for bool;

  // The minimum amount of the fee the contract takes (this is required to support small bets)
  uint constant internal HOUSE_EDGE_MINIMUM_AMOUNT = 0.001 ether;
  // The minimum amount wagered that makes the bet play for Jackpot
  uint constant internal MIN_JACKPOT_BET = 0.1 ether;
  // The fee taken from player's bet as a contribution to Jackpot fund
  uint constant internal JACKPOT_FEE = 0.001 ether;
  // The probability of any eligible bet to win a Jackpot
  uint constant internal JACKPOT_MODULO = 1000;
  // The target number to be rolled to win the jackpot
  uint constant internal JACKPOT_WINNING_OUTCOME = 888;
  // What percentage does the smart conract take as a processing fee
  uint constant internal HOUSE_EDGE_PERCENT = 1;
  // The denominator of jackpotMultiplier value
  uint constant internal JACKPOT_MULTIPLIER_BASE = 8;
  // The paytable of the jackpot: each 2 octets specify the multiplier of the base jackpot to be paid
  uint constant internal JACKPOT_PAYTABLE = 0x0000000000000000000000000404040408080808101010101010101010202040;
  // The base Jackpot value used for calculations
  uint constant internal BASE_JACKPOT_PAYMENT = JACKPOT_MODULO * JACKPOT_FEE;
  // The maximum Jackpot payment before applying the multplier (max value from JACKPOT_PAYTABLE is 4).
  uint constant internal MAX_JACKPOT_PAYMENT = BASE_JACKPOT_PAYMENT * 4;
  // The number of slots in the Jackpot paytable.
  uint constant internal JACKPOT_PAYTABLE_SLOTS_COUNT = 20;
  // The denominator of the values from JACKPOT_PAYTABLE
  uint constant internal JACKPOT_PAYTABLE_BASE = 16;
  // The number of epochs to pass before the bet becomes refundable
  uint constant internal REFUNDABLE_BET_EPOCHS_DISTANCE = 2;
  // The RSA modulus values as 4 uint256 integers.
  uint constant internal MODULUS0 = 0xc5aa5c8027079554ab25d5bdefe5b9bf2b1d77adb5f0494c6f824a86f2929765;
  uint constant internal MODULUS1 = 0x2f5c423a651e9ff83e212bcf54913be51d501ba52b2d4ba036a9f0b71450cf80;
  uint constant internal MODULUS2 = 0x04f8ef238e290af91899d1131beecb94b4dc95dd83a04493f54b579a9d833b5d;
  uint constant internal MODULUS3 = 0x866efeaabcdb9f476f8475939c685871511c2398ee3d48fcd137e62bd0b1f813;

  /* A non-interactive zero knowledge proof of the fact that RSA modulus above creates a permutation (see https://github.com/dice9win/ for further details):
   *  nizk:16:0:0:lQ2GqfyhmMtD0WdWVrVmxYThITd6dVuNOasZx3Uvszii5spX8ouwcLHZ7AU+AsR2ZvMT5Ctd+fIoa82+9r/Zyg==
   *  nizk:16:0:1:qC56TvWFMzSigWfcq/tmN/WiSG+3iVXaYK2XbZIjRvFeG7BSrEnUMpS6RCtbp5L1wR4G1StP8rP+fDgf0Q4wFw==
   *  nizk:16:1:0:NPwijDGGIvb91xwXoeh4pGQLlCECheCy3OW3YgidOVuJidOIjFWZm8GpzeF18w2FLRcrnsU9pwvQDc/N6P31kg==
   *  nizk:16:1:1:EeK3ABEq+UkIb4OqkmA/4BI1yHZ5oBSsIccZTkzWTw2Q9FQ8Cgr6NQvcdSaO2EBSomAENjxnK86Q2IlhZbI8lw==
   *  nizk:16:2:0:VbLVx3JSL5Op/YfL7yQ+oLZGtESfoS4GdlbaC7bIa0K7cWON+ZhG87ueB/xbpzvRXjyb9jMymIitmAV01iJKBQ==
   *  nizk:16:2:1:Roh1vf++yEBT9Y/Aoj25UfYAMu3M8FQK05ikswTc4kyQKHGkG2huz+kXt2EEtn2E/+7ynzuyybKQ9gCH1lLjYA==
   *  nizk:16:3:0:9XsnH0saYXO8TdH2EE8E4NWajxDsFlDKJ0OTNLw/6vfh8BDvILkpqMXifDSIiVglqNbPaDvcdRXk7qNvER2Dhg==
   *  nizk:16:3:1:iDnrg9u7tYJpR6spIVTUnn1W7sFaBePXB/+vhYrP2iMf2kWZLwgmceVyhS/FAK//DSXIq0sHATAGj1gL65sn9A==
   *  nizk:16:4:0:xKZhPeG7w2/XaELmvrsvQcrjFXmNKKOYrUMDxjDb3W0vJ6rbO2CHx6gaPz5S64OuB6pM1EMVc0GzUiN9MV7u7A==
   *  nizk:16:4:1:rdGGGUejvJOvOxag4G3vzccQFHmA3Z8qyieUsJ5Fe9ZQpw7w2ohTvtPkMrU6KwEb/xUL5OaR2QPN8zxROkXoTg==
   *  nizk:16:5:0:pF2MXKaqQG9N9XhCmmLK+vEiPt/e/YfvpwMzsiCPJ0NCRVNZq2wCBdx2kKoMFrb7olpQVgdw/hscdQ54aC9dQA==
   *  nizk:16:5:1:NiCPtqqntQxvBMglTADw4rMlSYg8oLsGoNiQOmrkBxwu5+4ZuA7zAWGNVnLAIchN1mw/zgyc31z7Yw7yzvDSmA==
   *  nizk:16:6:0:psARuKLyJY7h7ZBQY3fLx3giZTrJuDrpq1P+DKtGpm9biG9yTiXi/ITsWwxQkCU/cOF4h58nV6Fnm0iZsh89+w==
   *  nizk:16:6:1:meIjulS4HBqmfa7MmWxddU2fZTZRSNmvJyTEXjeiDAI814mTjH95xvo3rMzfrOF48tONjFdN20GHHn9TJhdGWg==
   *  nizk:16:7:0:WE4Y9RHRJtsCgZuWhVPDMcHcdK+SMblh8DnGo3ZcdTJL8600B6f6ehRYwIhgmRqSr1XEPZEIYgPC2n8XFvUqRg==
   *  nizk:16:7:1:gHqtcvrlKG04sLm2SfA0/dMOyhl+HLUfMEd5egcv9qEuhxxGKli0lsGzqvRyxD43RFHGiF7M8EoMaWIgvZmN2w==
   *  nizk:16:8:0:UON2EHJ6iB0U//XMDgB/DHqFRmpsiBq3zL0Kc4lKG4bBLY0hMVJn6zSVdYL/Dv8DmTKVY52Dn9Lz6kqb+VqLyw==
   *  nizk:16:8:1:rAesDbjg1edTAWUzYMgQEgRUgdKwc/naDo36UAWsInBm/T/I9hlcgF6rnRJHmM0w2/ciEiwQbHuUnzBKSP+8Yg==
   *  nizk:16:9:0:ZSjlXAfClb9AdJ50YPbWtwN96nO/bkGdHw6MwcuFbMKJHwxbGGn2on+JSQezfP1FFWZBtTkwU5H2bsNB5c8fsg==
   *  nizk:16:9:1:dOb7NS/QS6z/kxBVmZLUJ6Y7V9el/HDGEIbmD73/qz1P0cWbRi53C9628c03bKzf6ykydaAS/Fb9HzHal6vpDw==
   *  nizk:16:10:0:a54ikaihIFQrtN6EWKLlm3ElzP8qIKT+XdJRSQwmd7iYMN0rUL/4uzz1PZwYwzjr6yzWfn8OifW0Mnu8rAsRBw==
   *  nizk:16:10:1:AOem959GO//rmTtS9eIGizbSt9sU51DetiSw37SHZ2xmug0jTvUyipC67AetlcQKx2ICOY4O4Bn905XobHX2vA==
   *  nizk:16:11:0:LRch7IkJXFc0QmuSC7h4OQS5o09uh042xnkauJuXrM1TuByP6m6vrQ4dsM9fPcuEL+2QD2dvIncC27kgAJGdmw==
   *  nizk:16:11:1:RKFldgO0nIU7qMb/ZnSD5ShKyV9khEuJth/ww6YQwHjzgHzrLxiIXVMCAP99Yd4AwYozPWZQadlS80mB9AA6MA==
   *  nizk:16:12:0:Oo41oPg0wTn5S0bEbfqgDQiCo6DudbKc7VGvK1GoDM1FT81AYR9+AZwVyYyzbRs+mSJMFQzsoVw4X1XPO7FtKA==
   *  nizk:16:12:1:T0FMmGIiviL7Sucl4IAL087sWU9JzHzR+6I56GAD4WZ3eFyClu8oNk5XSZgmu++8VB600yuyWhMXilSMpLna+g==
   *  nizk:16:13:0:MaOMKs00AQyT6kwRcrREoxdUrflNVbbVkMYsLUpvGjG89iowQBuWgogbBYiBWhax0AFyAoe+QBr0iD/0qohCRg==
   *  nizk:16:13:1:uAagTJchq+LLf0rBxehWVoYTZFWIrNIe+k2o2AVkFC9KlKHHTyHGXIF7u3ZJ1IHAczzSVaPnoCTT7gmk4MuJlA==
   *  nizk:16:14:0:cHLER77YLj1Zy5ndB518oAC6YuOxR2AixKxbp3eaGu4Xk7HQE5SEUS+RWbzQtYOaqRSBAAiBPG4D6ABOuCH93Q==
   *  nizk:16:14:1:Ogoo4VY5YhWjGxdGGUZvguC9WN4Gcuym746UqbH5A/e/qNE5+BwzyKvd5GnL5g+Y3PHmlwUC+oJD0UKYDgKpgg==
   *  nizk:16:15:0:dLor43Y5/vJ7rGwseYDAiNCtxrdiljAILeiff4/GvWhoD4Dhx9DNM/bH+rJ1MnQSKUBJM59pRJc5WicVAiLmpg==
   *  nizk:16:15:1:bnlsC+lecxwwmdLL/XQG3LTDXctBYcy641Eu/eymn48BNw+WPWkzx5BxCKtnMBqDpar8YjFXU6uvatXMzP0U8Q==
   */

  // A structure containing the frequently accessed state of the contract packed into a single 256-bit slot
  // to save on storage gas costs.
  ContractState.State contractState;

  // The address allowed to tweak system settings of the contract.
  address payable public owner;

  // The to-be-promoted address that would become owner upon approval.
  address payable internal nextOwner;

  // The bets placed by the players that are kept in contract's storage.
  BetStorage.Bets internal bets;

  /**
   * The event that gets logged when a bet is placed.
   *
   * @param vrfInputHash the hash of bet attributes (see VRF.sol).
   * @param player the address that placed the bet.
   * @param playerNonce the seq number of the player's bet against this contract.
   * @param amount the amount of bet wagered.
   * @param packedBet the game and options chosen (see PackedBet.sol)
   * @param humanReadable a human-readable description of bet (e.g. "CoinFlip heads")
   */
  event Placed(bytes32 indexed vrfInputHash, address player, uint playerNonce, uint amount, uint packedBet, string humanReadable);

  /**
   * The event that gets logged when a bet is won.
   *
   * @param vrfInputHash the hash of bet attributes (see VRF.sol).
   * @param player the address that placed the bet.
   * @param playerNonce the seq number of the player's bet against this contract.
   * @param payment the amount the bet pays as winnings.
   * @param jackpotPayment the amount the bet pays as jackpot winnings.
   * @param humanReadable a human-readable description of outcome (e.g. "CoinFlip heads heads 888")
   */
  event Won(bytes32 indexed vrfInputHash, address player, uint playerNonce, uint payment, uint jackpotPayment, string humanReadable);

  /**
   * The event that gets logged when a bet is lost.
   *
   * @param vrfInputHash the hash of bet attributes (see VRF.sol).
   * @param player the address that placed the bet.
   * @param playerNonce the seq number of the player's bet against this contract.
   * @param payment the amount the bet pays as a consolation.
   * @param jackpotPayment the amount the bet pays as jackpot winnings.
   * @param humanReadable a human-readable description of outcome (e.g. "CoinFlip heads tails 887")
   */
  event Lost(bytes32 indexed vrfInputHash, address player, uint playerNonce, uint payment, uint jackpotPayment, string humanReadable);

  /**
   * The event that gets logged when somebody attemps to settle the same bet twice.
   *
   * @param player the address that placed the bet.
   * @param playerNonce the seq number of the player's bet against this contract.
   */
  event Duplicate(address player, uint playerNonce);

  /**
   * The event that gets logged when somebody attemps to settle non-existed (already removed?) bet.
   *
   * @param player the address that placed the bet.
   * @param playerNonce the seq number of the player's bet against this contract.
   */
  event Nonexistent(address player, uint playerNonce);

  /**
   * The event that gets logged when the House updates the maxProfit cap.
   *
   * @param value the new maxProfit value.
   */
  event MaxProfitUpdated(uint value);

  /**
   * The event that gets logged when the House updates the Jackpot multiplier.
   *
   * @param value the new jackpotMultiplier value.
   */
  event JackpotMultiplierUpdated(uint value);

  // The error logged when a player attempts to bet on both CoinFlip outcomes at the same time.
  error CoinFlipSingleOption();
  // The error logged when a player attempts to bet on multiple outcomes in Etheroll.
  error EtherollSingleOption();
  // The error logged when the contract receives the bet it might be unable to pay out.
  error CannotAffordToLoseThisBet();
  // The error logged when the contract receives the bet that can win more than maxProfit amount.
  error MaxProfitExceeded();
  // The error logged when the contract receives malformed batch of ecrypted bets to settle.
  error NonFullVRFs();
  // The error logged when the contract receives malformed encrypted bet.
  error StorageSignatureMismatch(address player, uint playerNonce);
  // The error logged when the contract receives a bet with 0 or 100+ winning probability (e.g. betting on all dice outcomes at once)
  error WinProbabilityOutOfRange(uint numerator, uint denominator);
  // The error logged when somebody attempts to refund the bet at the wrong time.
  error RefundEpochMismatch(address player, uint playerNonce, uint betEpoch, uint currentEpoch);

  /**
   * The modifier checking that the transaction was signed by the creator of the contract.
   */
  modifier onlyOwner {
    require(msg.sender == owner, "Only owner can do this");
    _;
  }

  /**
   * The modifier checking that the transaction originates from the EOA (externally owned account).
   */
  modifier onlyEOA {
      require(tx.origin == msg.sender, "Only externally owned account (EOA) can do this");
      _;
  }

  /**
   * Constructs the new instance of the contract by setting the default values for contract settings.
   */
  constructor() payable {
    owner = payable(msg.sender);
    nextOwner = payable(0x0);

    contractState.maxProfit = 100 ether;
    contractState.jackpotMultiplier = 8;
  }

  /**
   * The entry point function to place a bet in a CoinFlip game.
   *
   * The first parameter is not used in any way by the smart contract and can be ignored – it's sole purpose
   * is to make Dice9 frontend find player's bets faster; it does not affect the logic in any way.
   *
   * The second parameter is a string containing "heads", "tails", "0" or "1" - indicating the side of the coin
   * the player is willing to put a bet on.
   *
   * @param options human-readable string of options to lace a bet on.
   */
  function playCoinFlip(uint /* unusedBetId */, string calldata options) external onlyEOA payable {
    (uint mask,) = Options.parseOptions(options.toTinyString(), 0, 1);

    // make sure there is a single option selected
    if (!Math.isPowerOf2(mask)) {
      revert CoinFlipSingleOption();
    }

    placeBet(msg.sender, msg.value, GameOptions.toCoinFlipOptions(mask));
  }

  /**
   * The entry point function to place a bet in a Dice game.
   *
   * The first parameter is not used in any way by the smart contract and can be ignored – it's sole purpose
   * is to make Dice9 frontend find player's bets faster; it does not affect the logic in any way.
   *
   * The second parameter is a string containing number(s) in the range of 1..6, e.g. "1" or "4,5,6" indicating
   * the dice outcome(s) the user is willing to place a bet on.
   *
   * @param options human-readable string of options to lace a bet on.
   */
  function playDice(uint /* unusedBetId */, string calldata options) external onlyEOA payable {
    (uint mask,) = Options.parseOptions(options.toTinyString(), 1, 6);
    placeBet(msg.sender, msg.value, GameOptions.toDiceOptions(mask));
  }

  /**
   * The entry point function to place a bet in a TwoDice game.
   *
   * The first parameter is not used in any way by the smart contract and can be ignored – it's sole purpose
   * is to make Dice9 frontend find player's bets faster; it does not affect the logic in any way.
   *
   * The second parameter is a string containing number(s) in the range of 2..12, e.g. "2" or "8,12" indicating
   * the sum of two dice roll(s) the user is willing to place a bet on.
   *
   * @param options human-readable string of options to lace a bet on.
   */
  function playTwoDice(uint /* unusedBetId */, string calldata options) external onlyEOA payable {
    (uint mask,) = Options.parseOptions(options.toTinyString(), 2, 12);
    placeBet(msg.sender, msg.value, GameOptions.toTwoDiceOptions(mask));
  }

  /**
   * The entry point function to place a bet in a Etheroll game.
   *
   * The first parameter is not used in any way by the smart contract and can be ignored – it's sole purpose
   * is to make Dice9 frontend find player's bets faster; it does not affect the logic in any way.
   *
   * The second parameter is a string containing number(s) in the range of 3..97, e.g. "5" or "95" indicating
   * the number the user is willing to place a bet on.
   *
   * @param options human-readable string of options to lace a bet on.
   */
  function playEtheroll(uint /* unusedBetId */, string calldata options) external onlyEOA payable {
    (uint mask, uint option) = Options.parseOptions(options.toTinyString(), 3, 97);

    // make sure there is a single option selected
    if (!Math.isPowerOf2(mask)) {
      revert EtherollSingleOption();
    }

    placeBet(msg.sender, msg.value, GameOptions.toEtherollOptions(option));
  }

  /**
   * The generic all-mighty function processing all the games once the input parameters have been read and validated
   * by corresponding playXXX public methods.
   *
   * Accepting player's address, bet amount and GameOption instance describing the game being played, the function
   * stores the bet information in the contract's storage so that it can be settled by a Croupier later down the road.
   *
   * The function performs a few boring, but very important checks:
   *  1. It makes sure that all the bets currently accepted will be payable, even if all of them win (since we do not know upfront).
   *     If the contract sees that the potential winnings from pending bets exceed contract's balance, it would refrain from accepting the bet.
   *  2. If checks that the current bet will not win "too much" – a value depicted by maxProfit - a fair limitation kept in place to avoid
   *     situations when a single whale drains the contract in one lucky bet and everyone else has to wait until the House tops the contract up.
   *     Please mind this value is kept reasonably high so you should rarely run into such a limitation.
   *  3. It makes sure the player does not place "non-sensial" bets, like all Dice numbers or no sides in CoinFlip.
   *
   * If everything goes well, the contract storage is updated with the new bet and a log entry is recorded on the blockchain so that the
   * player can validate the parameters of the bet accepted.
   *
   * @param player the address of the player placing a bit.
   * @param amount the amount of the bet the player wagers.
   * @param gameOptions the choice(s) and the game type selected by the player.
   */
  function placeBet(address player, uint amount, GameOption gameOptions) internal {
    // check if the bet plays for jackpot
    bool playsForJackpot = amount >= MIN_JACKPOT_BET;

    // pack the bet into an instance of PackedBet
    PackedBet packedBet = PackedBets.pack(amount, gameOptions, playsForJackpot);

    // extract the bet information with regards to ods to compute the winAmount
    (uint numerator, uint denominator,, TinyString humanReadable) = gameOptions.describe();
    // consider this bet wins: how big the win is going to be?
    uint winAmount = computeWinAmount(amount, numerator, denominator, playsForJackpot);

    // add locks on contract funds arising from having to process this bet
    ContractState.State memory updatedContractState = contractState;
    updatedContractState.lockFunds(winAmount, playsForJackpot);

    // compute the amount the contract has to have available to pay if everyone wins and compare that to the current balance
    if (updatedContractState.totalLockedInBets(MAX_JACKPOT_PAYMENT, JACKPOT_MULTIPLIER_BASE) > address(this).balance) {
      // ok, we potentially owe too much and cannot accept this bet
      revert CannotAffordToLoseThisBet();
    }

    // check if the winning amount of the bet sans the amount wagered exceeds the maxProfit limit
    if (winAmount > amount + updatedContractState.maxProfit) {
      // ok, the win seems to be too big - crash away
      revert MaxProfitExceeded();
    }

    // all seems good - just store the bet in contract's storage
    uint playerNonce = BetStorage.storePackedBet(bets, player, packedBet);

    // append "jckpt" string if the bet plays for jackpot
    if (playsForJackpot) {
      humanReadable = humanReadable.append(TinyStrings.SPACE).append(GameOptions.JCKPT_STR);
    }

    // compute VRF input hash - a hash of all bet attributes that would uniquely identify this bet
    bytes32 vrfInputHash = VRF.computeVrfInputHash(player, playerNonce, packedBet.withoutEpoch());

    // commit fund locks to storage
    contractState = updatedContractState;

    // log the bet being placed successfully
    emit Placed(vrfInputHash, player, playerNonce, amount, packedBet.toUint(), humanReadable.toString());
  }

  /**
   * This is main workhorse of the contract: the routine that settles the bets previously placed by the players.
   *
   * It is expected that a Croupier (i.e. our software having access to the secret encryption key) would invoke this function,
   * passing some number of ecnrypted bets. The RSA VRF utilities (see VRF.sol) would validate the authenticity of the ecrypted data
   * received (e.g. check that the bets are encrypted with the specific secret key).
   *
   * If the authencity is confirmed, the routine would use the encrypted text as the source of entropy – essentially, treat
   * the encrypted bet data as a huge number. Since the contract uses pretty strong and battle-tested encryption (RSA 1024 bits), this
   * number is guaranteed to be unpredictable and uniformely distributed. The only party which can produce this number is, of course,
   * the Croupier – the possession of the secret key is required to calculate the number. The Croupier, in its turn, cannot tamper
   * with the bet attributes (since the contract keeps track of what players bet on) and has to create a number for every bet submitted.
   * Since the key is fixed, every bet attributes get a single, unique number from the croupier.
   *
   * More technical details are available in VRF.sol.
   *
   * @param vrfs the blob of VRF(s) chunks to use for bet settlement.
   */
  function settleBet(bytes calldata vrfs) external {
    // first and foremost, make sure there is a whole number of VRF chunks in the calldata
    if (vrfs.length % VRF.RSA_CIPHER_TEXT_BYTES != 0) {
      // there is not – just revert, no way to even try, it is coming from a malicious actor
      revert NonFullVRFs();
    }

    // move contract summary state to memory, as it will be updated several times (especially if batching)
    ContractState.State memory updatedContractState = contractState;

    // iterate over callback bytes in chunks of RSA_CIPHER_TEXT_BYTES size
    for (uint start = 0; start < vrfs.length; start += VRF.RSA_CIPHER_TEXT_BYTES) {
      // get the current slice of VRF.RSA_CIPHER_TEXT_BYTES bytes
      bytes calldata slice = vrfs[start:start+VRF.RSA_CIPHER_TEXT_BYTES];

      // use VRF.decrypt library to decrypt, validate and decode bet structure encoded in this particular chunk of calldata
      // unless the function reverts (which it would do shall there be anything wrong), it would return a fully decoded bet along
      // with vrfHash parameter – this is going to act as out entropy source
      (bytes32 vrfHash, bytes32 vrfInputHash, address player, uint playerNonce, PackedBet packedBet) = VRF.decrypt(MODULUS0, MODULUS1, MODULUS2, MODULUS3, slice);

      // get the (supposedly the same) bet from bet storage – it is trivial since we have both player and playerNonce values
      PackedBet ejectedPackedBet = BetStorage.ejectPackedBet(bets, player, playerNonce);

      // check if the bet is not blank
      if (ejectedPackedBet.isEmpty()) {
        // it is blank – probably already settled, so just carry on
        emit Nonexistent(player, playerNonce);
        continue;
      }

      // check if the bet's amount is set to zero – we are using this trick (see BetStorage.sol) to mark bets
      // which have already been handled
      if (ejectedPackedBet.hasZeroAmount()) {
        // it has been settled already, so just carry on
        emit Duplicate(player, playerNonce);
        continue;
      }

      // at this point it looks like the bet is fully valid – let's make sure the contract storage contains
      // exactly the same attributes as the decrypted data; we just need to be mindful that decrypted bets don't
      // contain any epoch information, so we ignore it for comparisons
      if (!ejectedPackedBet.withoutEpoch().equals(packedBet)) {
        // this is a pretty suspicious situation: the decrypted attributes do not match the data in the storage, as if
        // someone would try to settle a bet and alter its parameters at the same time. we don't like this and we crash
        revert StorageSignatureMismatch(player, playerNonce);
      }

      // at this point the bet seems valid, matches it decrypted counterpart and is ready to be settled

      // first of all, decode the bet into its attributes...
      (uint winAmount, bool playsForJackpot, uint betDenominator, uint betMask, TinyString betDescription) = describePackedBet(packedBet);
      // ...and pass those attributes to compute the actual outcome
      (bool isWin, uint payment, uint jackpotPayment, TinyString outcomeDescription) = computeBetOutcomes(uint(vrfHash), winAmount, playsForJackpot, betDenominator, betMask, betDescription);

      // remove fund locks (since we are processing the bet now)
      updatedContractState.unlockFunds(winAmount, playsForJackpot);

      // did the bet win?
      if (isWin) {
        // yes! congratulations, log the information onto the blockchain
        emit Won(vrfInputHash, player, playerNonce, payment, jackpotPayment, outcomeDescription.toString());
      } else {
        // nope :( it is ok, you can try again – log the information onto the blockchain
        emit Lost(vrfInputHash, player, playerNonce, payment, jackpotPayment, outcomeDescription.toString());
      }

      // compute the total payment
      uint totalPayment = payment + jackpotPayment;

      // invoke the actual funds transfer and revert if it fails for a winning bet
      (bool transferSuccess,) = player.call{value: totalPayment + Math.toUint(totalPayment == 0)}("");
      require(transferSuccess || totalPayment == 0, "Transfer failed!");
    }

    // commit summary state to storage
    contractState = updatedContractState;
  }

  /**
   * A publicly available function used to request a refund on a bet if it was not processed.
   *
   * The player or the House can refund any unprocessed bet during every other 8-hour window following
   * the bet.
   *
   * The logic of the time constraint is as follows:
   *  1. The day is split into 4 hour windows, i.e. 00:00-08:00, 08:00-16:00, 16:00-24:00 etc
   *  2. The smart contract keeps track of the window number the bet was placed in. For example, if
   *     the bet is placed at 02:15, it will be attributed to 00:00-08:00 window.
   *  3. The player can request the refund during every other 8-hour window following the bet.
   *     For example, if the bet is placed at 02:15, one can refund it during 16:00-20:00, or
   *     during 04:00-12:00 (next day), but not at 12:00 the same day.
   *
   * The refund window logic is a bit convoluted, but it is kept this way to minimise the gas requirements
   * imposed on all the bets going through the system. It is in House's best interests to make sure
   * this function is never needed – if all the bets are processed in a timely manner, noone would ever
   * invoke this. We decided to keep this in, however, to assure the players the funds will never end up
   * locked up in the contract, even if the Croupier stops revealing all the bets forever.
   *
   * @param player the address of the player that made the bet. Must match the sender's address or the contract owner.
   * @param playerNonce the playerNonce of the bet to refund
   */
  function refundBet(address player, uint playerNonce) external {
    // make sure a legit party is asking for a refund
    require(((msg.sender == player) || (msg.sender == owner)), "Only the player or the House can do this.");

    // extract the bet from the storage
    PackedBet ejectedPackedBet = BetStorage.ejectPackedBet(bets, player, playerNonce);

    // check if the bet is not blank
    if (ejectedPackedBet.isEmpty()) {
      // it is blank – probably already settled, so just carry on
      emit Nonexistent(player, playerNonce);
      return;
    }

    // check if the bet's amount is set to zero – we are using this trick (see BetStorage.sol) to mark bets
    // which have already been handled
    if (ejectedPackedBet.hasZeroAmount()) {
      // it has been settled already, so just carry on
      emit Duplicate(player, playerNonce);
      return;
    }

    // get the bet's and current epochs – those would be integers from 0..3 range denoting the number of
    // the 4 hour windows corresponding to the epochs
    (uint betEpoch, uint currentEpoch) = ejectedPackedBet.extractEpochs();
    // compute the distance between two epochs mod 4
    uint epochDistance = (currentEpoch + PackedBets.EPOCH_NUMBER_MODULO - betEpoch) & PackedBets.EPOCH_NUMBER_MODULO_MASK;

    // check if bet's epoch is good for refund
    if (epochDistance < REFUNDABLE_BET_EPOCHS_DISTANCE) {
      // we actually have to revert here since we have just modified the storage and are no taking any action
      revert RefundEpochMismatch(player, playerNonce, betEpoch, currentEpoch & PackedBets.EPOCH_NUMBER_MODULO_MASK);
    }

    // unlock the funds since the bet is getting refunded
    (uint winAmount, bool playsForJackpot,,,) = describePackedBet(ejectedPackedBet);
    contractState.unlockFundsStorage(winAmount, playsForJackpot);

    // send the funds back
    (,uint amount,) = ejectedPackedBet.unpack();
    (bool transferSuccess,) = player.call{value: amount}("");
    require(transferSuccess, "Transfer failed!");
  }

  /**
   * Being given an instance of PackedBet, decodes it into a set of parameters, specifically:
   *  1. What would the payment amount to if the bet wins.
   *  2. Whether the bet should play for Jackpot.
   *  3. What is the bet's game's denominator (2 for Coin Flip, 6 for Dice etc).
   *  4. What were the options chosen by the user (a.k.a. bet mask).
   *  5. What is the human-readable description of this bet.
   *
   * These parameters can further be utilised during processing or refunding of the bet.
   *
   * @param packedBet an instance of PackedBet to decode.
   *
   * @return winAmount how much the bet should pay back if it wins.
   *         playsForJackpot whether the bet should take part in a Jackpot roll.
   *         betDenominator the denominator of the game described by this bet.
   *         betMask the options the user chose in a form of a bitmask.
   *         betDescription the human-readable description of the bet.
   */
  function describePackedBet(PackedBet packedBet) internal pure returns (uint winAmount, bool playsForJackpot, uint betDenominator, uint betMask, TinyString betDescription) {
    // unpack the packed bet to get to know its amount, options chosen and whether it should play for Jackpot
    (GameOption gameOptions, uint amount, bool isJackpot) = packedBet.unpack();
    // unpack the GameOption instance into bet attributes and gather human-readable wager description at the same time
    (uint numerator, uint denominator, uint mask, TinyString description) = gameOptions.describe();

    // compute the amount of money this bet would pay if it is winning
    winAmount = computeWinAmount(amount, numerator, denominator, isJackpot);
    // return true if the bet plays for jackpot
    playsForJackpot = isJackpot;
    // transfer other attributes to the result
    betDenominator = denominator;
    betMask = mask;
    betDescription = description;
  }

  /**
   * Being given the entropy value and bet parameters, computes all the outcomes of the bet, speficically:
   *  1. The amount won, if the bet wins
   *  2. The amount of Jackpot payment, if the bet wins the jackpot
   *  3. The human-readable representation of the outcome (e.g. "Dice 1,2,3 2 888" or "CoinFlip tails heads 555")
   *
   * The incoming entropy integer is split into 3 chunks: game-dependent entropy, jackpot-dependent entropy and jackpot payment entropy.
   * All these values are taken from different parts of the combined entropy to make sure there is no implicit dependency between
   * out come values.
   *
   * @param entropy the RNG value to use for deciding the bet.
   * @param winAmount how much the bet should pay back if it wins.
   * @param playsForJackpot whether the bet should take part in Jackpot roll.
   * @param denominator the denominator of the game described by this bet.
   * @param mask the options the user chose in a form of a bitmask.
   * @param description the human-readable description of the bet.
   *
   * @return isWin the flag indicating whether the bet won on the primary wager.
   *         payment the amount of the winnings the bet has to pay the player.
   *         jackpotPayment the amount of the Jackpot winnings paid by this bet.
   *         outcomeDescription the human-readable description of the bet's result.
   */
  function computeBetOutcomes(uint entropy, uint winAmount, bool playsForJackpot, uint denominator, uint mask, TinyString description) internal view returns (bool isWin, uint payment, uint jackpotPayment, TinyString outcomeDescription) {
    // compute game specific entropy
    uint gameOutcome = entropy % denominator;

    // decide on the game type being played
    if (denominator == GameOptions.GAME_OPTIONS_ETHEROLL_MODULO) {
      // it is an Etheroll bet; the bet wins if the mask value (which simply holds the number for Etheroll, see GameOption.sol)
      // does not exceed the gameOutcome number
      isWin = gameOutcome < mask;

      // append the actual number (+1 to make it start from 1 instead of 0)
      outcomeDescription = description.append(TinyStrings.SPACE).appendNumber(gameOutcome + 1);
    } else if (denominator == GameOptions.GAME_OPTIONS_TWO_DICE_MODULO) {
      // it is a TwoDice bet; the bet wins if the user has chosen a sum of two dice that we got
      // first off, compute the dice outcomes by splitting the game outcome into 2 parts, with 6 possible values in each one
      uint firstDice = gameOutcome / GameOptions.GAME_OPTIONS_DICE_MODULO;
      uint secondDice = gameOutcome % GameOptions.GAME_OPTIONS_DICE_MODULO;

      // compute the sum of two dice
      uint twoDiceSum = firstDice + secondDice;
      // check if the mask contains the bit set at that position
      isWin = (mask >> twoDiceSum) & 1 != 0;

      // append the value of the first dice to the human-readable description (+1 to make it start from 1 instead of 0)
      outcomeDescription = description.append(TinyStrings.SPACE).appendNumber(firstDice + 1);
      // append the value of the second dice to the human-readable description (+1 to make it start from 1 instead of 0)
      outcomeDescription = outcomeDescription.append(TinyStrings.PLUS).appendNumber(secondDice + 1);
    } else if (denominator == GameOptions.GAME_OPTIONS_DICE_MODULO) {
      // it is a dice game – all is very simple, to win the user should bet on a particular number, thus
      // check if the mask has the bit set at the position corresponding to the dice roll
      isWin = (mask >> gameOutcome) & 1 != 0;

      // append the value of the dice to the human-readable description (+1 to make it start from 1 instead of 0)
      outcomeDescription = description.append(TinyStrings.SPACE).appendNumber(gameOutcome + 1);
    } else if (denominator == GameOptions.GAME_OPTIONS_COIN_FLIP_MODULO) {
      // it is a CoinFlip game - similar to Dice, the player should bet on the correct side to win
      isWin = (mask >> gameOutcome) & 1 != 0;

      // append the space to the description of the outcome
      outcomeDescription = description.append(TinyStrings.SPACE);

      // append heads or tails to the description, based on the result
      if (gameOutcome == 0) {
        outcomeDescription = outcomeDescription.append(GameOptions.HEADS_STR);
      } else {
        outcomeDescription = outcomeDescription.append(GameOptions.TAILS_STR);
      }
    }

    // now, the payment amount would equal to the winAmount if bet wins, 0 otherwise
    payment = isWin.toUint() * winAmount;

    // the last bit to check for is the jackpot
    if (playsForJackpot) {
      // first of all, get a separate chunk of entropy and compute the Jackpot Outcome number, adding
      // +1 to convert from 0..999 range to 1..1000
      uint jackpotOutcome = (entropy / denominator) % JACKPOT_MODULO + 1;

      // append Jackpot Number to the human-readable description of the bet
      outcomeDescription = outcomeDescription.append(TinyStrings.SPACE).appendNumber(jackpotOutcome);

      // check the Jackpot Number matches the lucky outcome
      if (jackpotOutcome == JACKPOT_WINNING_OUTCOME) {
        // it does – compute the jackpot payment entropy chunk
        uint jackpotPaymentOutcome = entropy / denominator / JACKPOT_MODULO;
        // set the jackpotPayment to the value computed by a dedicated function
        jackpotPayment = computeJackpotAmount(jackpotPaymentOutcome);
      }
    }
  }

  /**
   * Computes the amount a bet should pay to the user based on the odds the bet has and whether the bet plays for Jackpot.
   *
   * The logic of this method is based on the core principle of this smart contract: be fair. The bet ALWAYS pays the amount
   * decided by the odds (after the House fees are taken out). If the bet has 1 in 3 chances, the winning amount would be 3x;
   * if the bet has 1 in 16 chances of winning, the amount would be 16x.
   *
   * Running the contract is prety labour-intensive and requires constant investment of both labour and money (to settle the bets,
   * pay increased Jackpots and so on), that is why the contract always deducts the fees, calculated as follows:
   *  1. The House takes HOUSE_EDGE_PERCENT (1%) from every bet
   *  2. The House always takes at least HOUSE_EDGE_MINIMUM_AMOUNT (0.001 Ether) fee - roughly how much it costs to settle the bet.
   *  3. If the bet plays for Jackpot, a fixed Jackpot fee is taken to contribute towards the Jackpot payments.
   *
   * @param amount the amount being wagered in this bet.
   * @param numerator the number of possible outcomes chosen by the user.
   * @param denominator the total number of possible outcomes
   * @param isJackpot the flag indicating whether the bet takes part in Jackpot games.
   *
   * @return the amount the bet would pay as a win if it settles so.
   */
  function computeWinAmount(uint amount, uint numerator, uint denominator, bool isJackpot) internal pure returns (uint) {
    // range check
    if (numerator == 0 || numerator > denominator) {
      revert WinProbabilityOutOfRange(numerator, denominator);
    }

    // house edge clamping
    uint houseEdge = amount * HOUSE_EDGE_PERCENT / 100;

    if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
      houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
    }

    // jackpot fee
    uint jackpotFee = isJackpot.toUint() * JACKPOT_FEE;

    return (amount - houseEdge - jackpotFee) * denominator / numerator;
  }

  /**
   * Computes the amount the bet would pay as the Jackpot if the user wins the Jackpot.
   *
   * The value is computed in the following way:
   *  1. Base Jackpot value is computed by multiplying Jackpot Odds by Jackpot fee.
   *  2. A random number is sampled from JACKPOT_PAYTABLE, providing a number between 0.25 and 4.
   *  3. A current jackpotMultiplier value is read, providing another mutlplier.
   *  4. Everything is multipled together, providing the final Jackpot value.
   *
   * If the House keeps jackpotMultiplier at a default value (1), the Jackpot would pay between 0.25x and 4x
   * of base Jackpot value. During the happy hours this number can go up significantly.
   *
   * @param jackpotPaymentOutcome the Jackpot payment entropy value to use to sample a slot from the paytable.
   *
   * @return the jackpot payment value decided by all the attributes.
   */
  function computeJackpotAmount(uint jackpotPaymentOutcome) internal view returns (uint) {
    // compute base jackpot value that would be paid if the paytable was flat and pre-multply it by current
    // jackpotMultiplier; we will have to divide by JACKPOT_MULTIPLIER_BASE later.
    uint baseJackpotValue = BASE_JACKPOT_PAYMENT * contractState.jackpotMultiplier;
    // get random slot from the paytable
    uint paytableSlotIndex = jackpotPaymentOutcome % JACKPOT_PAYTABLE_SLOTS_COUNT;
    // compute the paytable multiplier based on the slot index
    uint paytableMultiplier = ((JACKPOT_PAYTABLE >> (paytableSlotIndex << 3)) & 0xFF);

    // the result would be base value times paytable multiplier OVER multipler denominators since
    // both paytable and jackpotMultiplier store integers assuming a certain divisor to be applied
    return baseJackpotValue * paytableMultiplier / JACKPOT_MULTIPLIER_BASE / JACKPOT_PAYTABLE_BASE;
  }

  /**
   * The total number of funds potentially due to be paid if all pending bets win (sans jackpots).
   *
   * @return the locked amount.
   */
  function lockedInBets() public view returns (uint) {
    return contractState.lockedInBets;
  }

  /**
   * The total number of funds potentially due to be paid if all pending bets win (including jackpots).
   *
   * @return the locked amount.
   */
  function lockedInBetsWithJackpots() public view returns (uint) {
    return contractState.totalLockedInBets(MAX_JACKPOT_PAYMENT, JACKPOT_MULTIPLIER_BASE);
  }

  /**
   * The number of not-yet-settled bets that are playing for jackpot.
   *
   * @return number of bets playing for jackpot.
   */
  function jackpotBetCount() public view returns (uint) {
    return contractState.jackpotBetCount;
  }

  /**
   * The multiplier of the jackpot payment, set by the house.
   *
   * @return jackpot multiplier.
   */
  function jackpotMultiplier() public view returns (uint) {
    return contractState.jackpotMultiplier;
  }

  /**
   * The value indicating the maximum potential win a bet is allowed to make. We have to cap that value to avoid
   * draining the contract in a single bet by whales who put huge bets for high odds.
   *
   * @return jackpot multiplier.
   */
  function maxProfit() public view returns (uint) {
    return contractState.maxProfit;
  }

  /**
   * A House-controlled function used to modify maxProfit value – the maximum amount of winnings
   * a single bet can take from the contract.
   *
   * Bets potentially exceedign this value will not be allowed to be placed.
   *
   * @param newMaxProfit the updated maxProfit value to set.
   */
  function setMaxProfit(uint newMaxProfit) external onlyOwner {
    contractState.maxProfit = uint72(newMaxProfit);
    emit MaxProfitUpdated(newMaxProfit);
  }

  /**
   * A House-controlled function used to modify jackpotMultiplier value – the scale factor
   * of the Jackpot payment paid out on Jackpot wins.
   *
   * The House reserves the right to tweak this value for marketing purposes.
   *
   * @param newJackpotMultiplier the updated maxProfit value to set.
   */
  function setJackpotMultiplier(uint newJackpotMultiplier) external onlyOwner  {
    contractState.jackpotMultiplier = uint32(newJackpotMultiplier);
    emit JackpotMultiplierUpdated(newJackpotMultiplier);
  }

  /**
   * A House-controlled function used to send a portion of contract's balance to an external
   * address – primarily used for bankroll management.
   *
   * The function DOES NOT allow withdrawing funds from the bets that are currently being
   * processed to make sure the house cannot do a bank run.
   *
   * @param to the address to withdraw the funds to.
   * @param amount the amount of funds to withdraw.
   */
  function withdrawFunds(address to, uint amount) external onlyOwner  {
    // make sure there will be at least lockedInBets funds after the withdrawal
    require (amount + contractState.lockedInBets <= address(this).balance, "Cannot withdraw funds - pending bets might need the money.");
    // transfer the money out
    (bool transferSuccess,) = to.call{value: amount}("");
    require (transferSuccess, "Transfer failed!");
  }

  /**
   * A House-controlled function used block a specific address from placing any new bets.
   *
   * The already-placed bets can still be processed or refunded.
   *
   * The primary use of this function is to block addresses containing funds associated with
   * illegal activity (such as stolen or otherwise acquired in an illegal way).
   *
   * This is a legal requirement to have this function.
   *
   * @param player the address of the player to suspend.
   * @param suspend whether to suspend or un-suspend the player.
   */
  function suspendPlayer(address player, bool suspend) external onlyOwner {
    BetStorage.suspendPlayer(bets, player, suspend);
  }

  /**
   * A House-controlled function used to destroy the contract.
   *
   * It would only work if the value of lockedInBets is 0, meaning there are no pending bets
   * and the contract destruction would not take any player's money.
   */
  function destroy() external onlyOwner {
    require(contractState.lockedInBets == 0, "There are pending bets");
    selfdestruct(owner);
  }

  /**
   * A function used to add funds to the contract.
   */
  function topUpContract() external payable {
  }

  /**
   * Approves nextOwner address allowing transfer of contract's ownership
   * to a new address.
   */
  function approveNextOwner(address _nextOwner) external onlyOwner {
    nextOwner = payable(_nextOwner);
  }

  /**
   * Accepts ownership transfer to the nextOwner address making it the new owner.
   * The signer should seek approval from the current owner before calling this method.
   */
  function acceptNextOwner() external {
    require(msg.sender == nextOwner, "nextOwner does not match transaction signer.");
    owner = nextOwner;
  }
}

/* RSA permutation NIZK:
 *    nizk:8:0:ow7gON+Eb+e/r5XB9aWrVMc6TVtdG9+39gWGrGw30Hd/Aj4z5Pj3dhh1QllYgOCFTiI0a23lwf/PFYWQ3+4rUYsUFtjkx82NkLQLLYC6WBzbg2kuhvdE1/0BL6teTjjFV1SNkU9OGbV5MVQX7aE6nWdO/fqyxWf+eh0abaNg6XM=
 *    nizk:8:1:QGSackZNonPtwVDhLWRjGhq3ROEJA1/ko7ZofC34eQGZ429glcIHlkN47HlCwhK1ewXDy1R6w566iW+xU1Kn8FOQG1sRA+r1op0xa4uXnsz+j9JVmiiNgz5407vq+lALjGWEr5Y0w8q0JBBHAwKoYRG8viDSsovmFcuNVGQVyEE=
 *    nizk:8:2:e23Td+FPMDKb2BQkaXrS2M66Enf2mUkHXa61gXv/d5bE9Tm7VtDEL2/Te/4oug6bGLSmmL3aY0qFY7eOLRCA87+sAqc3a+KRSd8vvvupqykbwpsLXFjbD1srrNl/q5FCnUILOqpTterSuyl/Di1cKZ1RJ94lIcmF9ld/yTw9fm8=
 *    nizk:8:3:BF6ScEDU+6dMknR45fxuwLxMIXDILb9WOzzOfc1bJLt9pq8HWfMGXzcL7RNEpZHpFsXL88J9dSygCzy/VliWGTF5MhlmAvn/8VV2fwut9WLKcDjTHspChS5MtT+sAF7kqTUgmF7aSWa+2v5Km4dOtyG6773LejJ3YxXSAB5yWgs=
 *    nizk:8:4:hZnWtDxEFFveo5nzs20FfcCrg4zCsDyHqmMhlY3SZGNVLgL9qvwnVRBMdSn4DyT7LH6SGVSLnABOe4mkI8yuaPS9jDAG/d1uxVKzd5p/bitGOryv1ePDHLYZHeJMMEMT+ZGG7P799tiFqZ1zbjij7MCqtI9qU4YqZ+Sup99ZP4Y=
 *    nizk:8:5:bkratF6TVVbLObR2h3xUfr/DkBw++1OhmuQ3XTbebpxVnna2od/hOWCA4B1Gz6+w+GWo9uSI0lVTT37dWnkT1BUILryhdqGE0H9vpBzbL/BJxIcSltM4N8Sm+np0VCw7yQGeYuyK20qJj392mI/zLmtJZX4Xiho7KWNcXjCEzvI=
 *    nizk:8:6:dvrldgSHZAUT6wn1IOLZsloht+nWhW70+mTTnH2sdz4lofZR9aX6wV9hGqLYgLwVN/EIrswc0gOzCmIAXnyrwRqkBEcGaYlSuiQ9v2DahXRJzBJjD2hs+7Ce8m700tdv8syKLvMgm1pFzTkY4CXfUihDivDNm59sH9a9+M7L3Ts=
 *    nizk:8:7:YazoLkX8tk63ehhbU/+kOpC2dI0LCM4m2gVIEMX9haGt8WHFFPOp762HbkQRLgkg8cFQfPihumPYnEmwPiQ57REM5Wq9zwU5+sNv2ncTi+maG79eDnJw22Q2hqkapEtPQSW/CV4CESiUncoNC7WLAv6dYUZIhZkdYQZLKMQpk3M=
 */
