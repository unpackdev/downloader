//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./ICarbonInventoryControl.sol";
import "./IPolygonBridge.sol";

/**
  * @dev this contract is meant to run on mainchain (ethereum) as a single entrypoint
  * for offset batches issued on sidechain (celo)
 */
contract CarbonBatchOffset is Initializable, AccessControlUpgradeable {

    address public carbonInventoryControl;
    address private MCO2;
    address private broker;
    address private bridge;
    bytes32 constant public BURNER_ROLE = keccak256("BURNER_ROLE");

    event MCO2Changed(address newMCO2);
    event BrokerChanged(address newBroker);
    event BatchOffset(address broker, uint carbonTon, string batchHash, string onBehalfOf);
    event BridgeChanged(address newBridge);
    

    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, msg.sender), "ContractBatchOffset: sender is not a BURNER");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "CarbonBatchOffset: sender is not an ADMIN");
        _;
    }

    function initialize(
        address _carbonInventoryControl,
        address _MCO2,
        address _broker,
        address _bridge,
        address _operator
    ) public initializer {
        _changeInventoryControl(_carbonInventoryControl);
        _changeMCO2(_MCO2);
        _changeBroker(_broker);
        _changeBridge(_bridge);
        
        _setupRole(DEFAULT_ADMIN_ROLE, _operator);
    }

    /**
      * @dev executes the batch offset on carbon registry inventory. This will burn
      * _carbonTon MCO2 tokens and their counterparty on general carbon inventory
     */
    function offsetBatch( uint256 _carbonTon, string memory _batchHash, string memory _onBehalfOf)
        public onlyBurner {
        ICarbonInventoryControl(carbonInventoryControl).offsetTransaction(address(this), broker, _carbonTon, _batchHash, _onBehalfOf, MCO2);
        emit BatchOffset(broker, _carbonTon, _batchHash, _onBehalfOf);
    }


    function exitBridge(bytes calldata inputData) external onlyAdmin {
        IPolygonBridge(bridge).exit(inputData);
    } 

    function changeMCO2(address newMCO2) external onlyAdmin returns(bool) {
        _changeMCO2(newMCO2);
        return true;
    }

    function _changeMCO2(address newMCO2) internal {
        require(newMCO2 != address(0), "CarbonBatchOffset: invalid MCO2 address");
        MCO2 = newMCO2;
        emit MCO2Changed(MCO2);
    }

    function getMCO2() external view returns(address) {
        return MCO2;
    }

    function changeBroker(address newBroker) external onlyAdmin returns(bool) {
        _changeBroker(newBroker);
        return true;
    }

    function _changeBroker(address newBroker) internal {
        require(newBroker != address(0), "CarbonBatchOffset: invalid broker address");
        broker = newBroker;
        emit BrokerChanged(newBroker);
    }

    function getBroker() external view returns(address) {
        return broker;
    }

    function changeInventoryControl(address newInventory) external onlyAdmin returns(bool) {
        _changeInventoryControl(newInventory);
        return true;
    }

    function _changeInventoryControl(address newInventory) internal {
        require(newInventory != address(0), "CarbonBatchOffset: invalid inventory address");
        carbonInventoryControl = newInventory;
        emit BrokerChanged(newInventory);
    }

    function getInventoryControl() external view returns(address) {
        return carbonInventoryControl;
    }

    /**
    * @dev Changes a the bridge address on celo network
    * @param newBridge New bridge address on celo network  
    */
    function changeBridge (address newBridge) external onlyAdmin returns(bool) {
        _changeBridge(newBridge);
        return true;
    }

    /**
    * @dev Changes a the bridge address on celo network (internal)
    * @param newBridge New bridge address on celo network
    */
    function _changeBridge(address newBridge) internal {
        require(newBridge != address(0), "CarbonChain: Contract is empty");
        bridge = newBridge;
        emit BridgeChanged(bridge);
    }

    function getBridge() external view returns(address) {
        return bridge;
    }


}