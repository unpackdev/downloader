// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "Ownable.sol";
import "EthUsPriceConversion.sol";
import "MyStorage.sol";

contract Wrapper is Ownable {

    address sc_owner;

    MyStorage internal myStorage;
  //  EthUsPriceConversion internal ethUsConvert;
   // enum STATE { OPEN, END, CLOSED }

    constructor(
        address _priceFeedAddress,
        uint32 _minimumEntreeFee,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash
        ) payable {
            sc_owner = msg.sender;
           // ethUsConvert = new EthUsPriceConversion(_priceFeedAddress, _minimumEntreeFee);
            myStorage = new MyStorage(
                sc_owner,
                _priceFeedAddress,
                _minimumEntreeFee,
                _subscriptionId,
                _callbackGasLimit,
                _vrfCoordinator,
                _link,
                _keyHash
            );
        }


    /**
     * @notice Open the funding account.  Users can start funding now.
     */
    function start() external onlyOwner {
        myStorage.start();
    }

    /**
     * @notice It is ended.
     */
    function end() external onlyOwner {
        myStorage.end();
    }

    /**
     * @notice It is closed.
     */
    function closed() external onlyOwner {
        myStorage.closed();
    }

    /**
     * @notice Get the current Ethereum market price in Wei
     */
    function getETHprice() external view returns (uint256) {
       return myStorage.getETHprice();
    }

    /**
     * @notice Get the current Ethereum market price in US Dollar
     */
    function getETHpriceUSD() external view returns (uint256) {
        return myStorage.getETHpriceUSD();
    }

    /**
     * @notice Get the minimum funding amount which is $50
     */
    function getEntranceFee() external view returns (uint256) {
        return myStorage.getEntranceFee();
    }

    /**
     * @notice Update minimum funding amount
     */
  /*  function setEntranceFee(uint32 min_Entree_Fee) external onlyOwner {
        myStorage.setEntranceFee(min_Entree_Fee);
    }
*/

    /**
     * @notice Update the gas limit for callback function 
     */
    function setCallbackGasLimit(uint32 gasLimit) external onlyOwner {
        myStorage.setCallbackGasLimit(gasLimit);
    }

    /**
     * @notice Get current state.
     */
    function getCurrentState() external view returns (string memory) {
        return myStorage.getCurrentState();
    }

    /**
     * @notice Update the funding state
     */
    function setState(uint32 newState) external onlyOwner {
        return myStorage.setState(newState);
    }

    /**
     * @notice Get the Random RequestID from Chainlink
     */
    function getRequestID() external onlyOwner view returns (uint256) {
        return myStorage.getRequestID();
    }

    /**
     * @notice Get the First Random Word Response from Chainlink
     */
    function getFirstWord() external onlyOwner view returns (uint256) {
        return myStorage.getFirstWord();
    }

    /**
     * @notice Get the Second Random Word Response from Chainlink
     */
    function getSecondWord() external onlyOwner view returns (uint256) {
        return myStorage.getSecondWord();
    }

    /**
     * @notice User can enter the fund.  Minimum $50 value of ETH.
     */
    function send() external payable {
        // $50 minimum
        myStorage.send(msg.sender, msg.value);
    }

    /**
     * @notice Owner withdraw.
     */
    function wdraw() external payable onlyOwner {
        return myStorage.wdraw();
    }

    /**
     * @notice Get the balance of the user.
     */
    function getUserBalance(address user) external view returns (uint256) {
        return myStorage.getUserBalance(user);
    }

    /**
     * @notice Get the total amount in this account.
     */
    function getTotalAmount() external view returns (uint256) {
        return myStorage.getTotalAmount();
    }

    /**
     * @notice Owner withdraw the funding.
     */
    function collect() external onlyOwner {
        myStorage.collect();
    }

    /**
     * @notice Transfer to amount to recipient
     * 
     * @param recipient - recipient of the transfer
     * @param amount - amount to transfer
     */
    function transfer(address recipient, uint amount) external onlyOwner returns (bool success){
        myStorage.transfer(recipient, amount);
        return true;
    }
}