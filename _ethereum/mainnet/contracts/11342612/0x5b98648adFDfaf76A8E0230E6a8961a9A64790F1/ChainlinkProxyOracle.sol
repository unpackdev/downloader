pragma solidity 0.6.12;

import "./Ownable.sol";
import "./ChainlinkToOracleBridge.sol";
import "./IMedianOracleGetter.sol";

/**
  * @title ChainlinkToOracleBridge requests data from the Chainlink network and feeds it to xBTCs 
  * Dominance Oracle
  * @dev This contract is designed to work on multiple networks, including local test networks
  */
contract ChainlinkProxyOracle is Ownable, IMedianOracleGetter {
  // details where the Chainlink data can be found
  ChainlinkToOracleBridge public chainlinkBridge = ChainlinkToOracleBridge(0);

  event ChainlinkBridgeSet(ChainlinkToOracleBridge newChainlinkBridge);

  /**
    * @notice Deploy the contract with a Chainlink data source set
    * @param _chainlinkBridge The address of the LINK token contract
    */
  constructor(ChainlinkToOracleBridge _chainlinkBridge) public {
    chainlinkBridge = _chainlinkBridge;
    emit ChainlinkBridgeSet(_chainlinkBridge);
  }

  /**
    * @notice Changes the Chainlink data source.
    * @param _chainlinkBridge Address of the new Chainlink data source.
    */
  function setChainlinkBridge(ChainlinkToOracleBridge _chainlinkBridge)
    external
    onlyOwner
  {
    require(chainlinkBridge != _chainlinkBridge, 'New bridge must be different');
    chainlinkBridge = _chainlinkBridge;
    emit ChainlinkBridgeSet(_chainlinkBridge);
  }

  /**
    * @notice Gets the current value of the oracle.
    * @return Value: The current value.
    *         valid: Boolean whether the value is valid or not.
    */
  function getData()
    external
    override
    returns (uint256, bool)
  {
    return (chainlinkBridge.data(), true);
  }
}
