// This example code is designed to quickly deploy an example contract using Remix.

pragma solidity 0.6.6;

import "./VRFConsumerBase.sol";

contract FxceVrfContract is VRFConsumerBase {

    bytes32 internal keyHash;
    uint256 internal fee;

    address[] private whiteListAddresses = [ address(0xf84Fa8971A713f6bf87bD010526B217f3322cCF0) ];

    // save requestId => user-provided seed
    mapping(bytes32 => uint256) private requests;
    // save user-provided seed => randomResult
    mapping(uint256 => uint256) private results;

    uint256 public randomResult;

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor()
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        ) public
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; // 0.1 LINK
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
    function getRandomNumber(uint256 userProvidedSeed) public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        require(results[userProvidedSeed] <= 0, "This seed already in used");
        bool isWhiteList = false;
        for (uint i = 0; i < whiteListAddresses.length; i++) {
          if (msg.sender == whiteListAddresses[i]) {
            isWhiteList = true;
            break;
          }
        }

        require(isWhiteList, "This address is not allowed to create new random number.");
        requestId = requestRandomness(keyHash, fee);
        requests[requestId] = userProvidedSeed;
        return requestId;
    }

    /**
     * Withdraw LINK from this contract
     *
     * DO NOT USE THIS IN PRODUCTION AS IT CAN BE CALLED BY ANY ADDRESS.
     * THIS IS PURELY FOR EXAMPLE PURPOSES.
     */
    function getRandomNumberFromSeed(uint256 userProvidedSeed) public view returns (uint256 randomness) {
        return results[userProvidedSeed];
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        results[requests[requestId]] = randomness;
    }

}
