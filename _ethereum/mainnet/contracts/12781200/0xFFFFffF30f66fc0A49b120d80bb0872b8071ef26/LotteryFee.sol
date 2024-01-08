// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";


contract LotteryFee is VRFConsumerBase, Ownable {
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 constant DICE_SIZE = 42; //42;
    uint256 constant DICE_WINNING_FACE = 7;
    uint256 constant GAME_PERIOD_SECONDS = 60*60*24; // once per day

    uint256 public lastRandomResult;

    mapping(uint256 => uint256) public rolledDiceAtDay;
    bool public isWon = false;

    /**
     * Kovan
     */
    //    constructor()
    //    VRFConsumerBase(
    //        0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
    //        0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
    //    ) public
    //    {
    //        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
    //        fee = 0.1 * 10 ** 18; // 0.1 LINK
    //    }

    /**
    * Rinkeby
    */
    constructor()
    VRFConsumerBase(
        0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
        0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
    ) public
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }

    /**
    * Ethereum Mainnet
    */
    //    constructor()
    //    VRFConsumerBase(
    //        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
    //        0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
    //    ) public
    //    {
    //        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    //        fee = 2 * 10 ** 18; // 0.1 LINK
    //    }

    /**
     * Return timestamp of the second beginning of the day
     */
    function getCurrentDayTimestamp() public view returns (uint256) {
        return (block.timestamp / GAME_PERIOD_SECONDS) * GAME_PERIOD_SECONDS;
    }

    function rollTheDice(uint256 userProvidedSeed) external {
        require(isWon == false, "the game is finished");
        require(rolledDiceAtDay[getCurrentDayTimestamp()] == 0, "already rolled today");
        rolledDiceAtDay[getCurrentDayTimestamp()] = type(uint256).max;
        bytes32 requestId = getRandomNumber(userProvidedSeed);
        emit StartedRollingDice(requestId, msg.sender, userProvidedSeed);
    }

    function checkRolledDice(uint256 diceFace) internal {
        rolledDiceAtDay[getCurrentDayTimestamp()] = diceFace + 1;
        if (diceFace == DICE_WINNING_FACE) {
            isWon = true;
        }
    }

    function resetGame() external onlyOwner {
        isWon = false;
    }

    /**
     * Requests randomness from a user-provided seed
     ************************************************************************************
     *                                    STOP!                                         *
     *         THIS FUNCTION WILL FAIL IF THIS CONTRACT DOES NOT OWN LINK               *
     *         ----------------------------------------------------------               *
     *         Learn how to obtain testnet LINK and fund this contract:                 *
     *         ------- https://docs.chain.link/docs/acquire-link --------               *
     *         ---- https://docs.chain.link/docs/fund-your-contract -----               *
     *                                                                                  *
     ************************************************************************************/
    function getRandomNumber(uint256 userProvidedSeed) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        lastRandomResult = randomness % DICE_SIZE + 1;
        checkRolledDice(lastRandomResult);
        FinishedRollingDice(requestId, getCurrentDayTimestamp(), lastRandomResult);
    }

    /**
     * Withdraw LINK from this contract
     *
     */
    function withdrawLink() external onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }

    event StartedRollingDice(bytes32 requestId, address user, uint256 seed);
    event FinishedRollingDice(bytes32 requestId, uint256 dayTimestamp, uint256 diceFace);
}
