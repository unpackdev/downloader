// This example code is designed to quickly deploy an example contract using Remix.

pragma solidity 0.8.0;

import "./VRFConsumerBase.sol";

contract TheBearMarketRandom is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult;

    address owneraddress;
    
    modifier onlyowner {
        require(owneraddress == msg.sender);
        _;
    }

    /**
     * The Bear Market NFT random retriever contract.
     *
     * Constructor inherits Chainlink's VRFConsumerBase
     * 
     */
    constructor() 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        ) public
    {
        owneraddress = msg.sender;

        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; // 2 LINK
    }

    function getRandomNumber() public onlyowner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
    
    function withdrawLink() external onlyowner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }
}
