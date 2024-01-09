// SPDX-License-Identifier: MIT

//** Demon Random Generation Contract */
//** Author Alex Hong : DEMONS 2021.12 */

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./VRFConsumerBase.sol";

contract DemonRandom is Ownable, VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;
    uint256 public randomRange;

    address public spender;

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * LINK token address:                0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     */
    constructor()
        public
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        )
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10**18; // 0.1 LINK (Varies by network)
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(msg.sender == spender);
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness.mod(randomRange).add(1);
    }

    function setRandomRange(uint256 _randomRange) external onlyOwner {
        require(_randomRange != 0, "It should bigger than 0 ");

        randomRange = _randomRange;
    }

    function setSpender(address _account) external onlyOwner {
        require(_account != address(0), "Invalid account for spender");

        spender = _account;
    }

    function withdrawLink() external onlyOwner {
        LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
    }
}
