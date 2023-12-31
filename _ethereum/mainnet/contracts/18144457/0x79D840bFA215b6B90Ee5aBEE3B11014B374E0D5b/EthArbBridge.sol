// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./EthArbBase.sol";
import "./IEthArbBrigde.sol";


contract EthArbBridge is EthArbBase {
    uint256 public constant GAS_LIMIT_FOR_CALL = 2_000_000;
    uint256 public constant MAX_FEE_PER_GAS = 1 gwei;
    uint256 public constant MAX_SUBMISSION_COST = 0.001 ether;
    
    function getDelayBox() internal pure virtual returns (address) {
        return 0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f;
    }

    function getArbitrumReceiver() internal pure virtual returns (address) {
        return 0xDcBd0888F20c18eF1a2D50cEc77A774aA4A2E16d; //arbNftPurchaser arbitrum address
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    receive() external payable {
        uint256 requiredValue = NFT_PRICE *
            COUNT + 
            MAX_SUBMISSION_COST +
            GAS_LIMIT_FOR_CALL *
            MAX_FEE_PER_GAS;

        require(msg.value >= requiredValue, "!msg.value");

        bytes memory arbContractData = abi.encodeWithSelector(
            bytes4(keccak256("purchaseNfts(address)")),
            msg.sender
        );

        IEthArbBrigde(getDelayBox()).createRetryableTicket{
            value: requiredValue
        }(
            getArbitrumReceiver(),
            NFT_PRICE * COUNT,
            MAX_SUBMISSION_COST,
            msg.sender,
            msg.sender,
            GAS_LIMIT_FOR_CALL,
            MAX_FEE_PER_GAS,
            arbContractData
        );

        if(msg.value > requiredValue){
           
          payable(msg.sender).transfer(msg.value - requiredValue);
        }
    }
}
