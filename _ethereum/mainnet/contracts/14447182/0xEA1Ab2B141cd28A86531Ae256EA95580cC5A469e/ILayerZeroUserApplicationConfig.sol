// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

//
// interface functions for setting/getting UserApplication config.
//
// a contract that implements this interface must have access
// to a LayerZero endpoint (an instance of Communicator.sol)
interface ILayerZeroUserApplicationConfig {

    /* setters */

    // set the Oracle address for the given chainId
    function setOracle(uint16 _chainId, address payable _oracle) external ;
    // set the Relayer address for the given chainId
    function setRelayer(uint16 _chainId, address payable _relayer) external ;
    // set the blockConfirmations for the given chainId
    function setBlockConfirmations(uint16 _chainId, uint _blockConfirmations) external ;
    // set the libraryVersion for the given chainId
    function setLibraryVersion(uint16 _chainId, uint16 _libraryVersion) external ;

    /* getters */

    // get the current Oracle address configured for the chainId
    function getOracle(uint16 _chainId, address userApplicationAddress) view external returns(address oracle) ;
    // get the Relayer address configured for the chainId
    function getRelayer(uint16 _chainId, address userApplicationAddress) view external returns(address relayer) ;
    // get the required block confirmations configured for the chainId
    function getBlockConfirmations(uint16 _chainId, address userApplicationAddress) view external returns(uint blockConfirmations) ;
    // get the libraryVersion configured for the chainId
    function getLibraryVersion(uint16 _chainId, address userApplicationAddress) view external returns(uint16 libraryVersion) ;

}