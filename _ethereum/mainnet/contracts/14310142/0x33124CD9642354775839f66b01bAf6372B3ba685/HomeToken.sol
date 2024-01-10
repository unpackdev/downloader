// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC20PresetFixedSupply.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

/**
 * @title Home (HOME) ERC20 Token
 * @notice HOME is the core token of the Home Network Foundation ecosystem
 * @author Home Network Foundation
 *
 * @dev Token Summary:
 *      Symbol: HOME
 *      Name: Home
 *      Decimals: 18
 *      Token supply: 500,000,000 HOME
 *      Burnable: total supply may decrease
 *      Not mintable
 */

/*
 * @dev HomeNetworkHandler: Handler contracts for handling payments in HOME and/or ETH.
 * @param _from - The address of the caller
 * @param _ethDestination - The address to which ETH amount is sent
 * @param _homeDestination - The address to which HOME amount is sent
 * @param _id - A client-defined id passed by the caller
 * @param _ethValue - The amount of ETH sent
 * @param _homeValue - The amount of HOME sent
 * @param _data - any additional data
 */
abstract contract HandlerContract {
    function handleSendHome(address _from, address _ethDestination, address _homeDestination, uint256 _id, uint256 _ethValue, uint256 _homeValue, bytes memory _data) virtual external;
}

contract HomeToken is ERC20PresetFixedSupply, AccessControl, ReentrancyGuard {
    /**
     * @notice ERC20 Name of the token: Home
     */
    string constant public NAME = "Home";

    /**
     * @notice ERC20 Symbol of the token: HOME
     */
    string constant public SYMBOL = "HOME";

    /**
     * @notice Total supply of the token: 500,000,000 (18 decimals)
     */
    uint256 constant public SUPPLY = 500000000000000000000000000;

    /**
    * @notice Details of registered handler contracts
    */
    struct Handler {
        address ethDestinationAddress;
        address homeDestinationAddress;
        HandlerContract homeHandlerContract;
    }

    mapping(address => Handler) public handlers;

    /**
    * @dev Fired when a new handler contract is registered
    * @param contractAddress - The address of the new handler
    * @param ethDestinationAddress - The address ETH is sent to
    * @param homeDestinationAddress - The address HOME is sent to
    */
    event HandlerRegistered(address contractAddress, address ethDestinationAddress, address homeDestinationAddress);

    /**
    * @dev initialize a standard openzeppelin ERC20 with Fixed Supply
    *      grant deployer address DEFAULT_ADMIN_ROLE
    */
    constructor()
    ERC20PresetFixedSupply(NAME, SYMBOL, SUPPLY, msg.sender) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
    * @notice Allow the caller to send HOME and/or ETH and invoke the handler
    * @param _handlerAddress - The address of the deployed and registered handler contract
    * @param _id - An id passed by the caller
    * @param _homeValue - The amount of HOME sent
    * @param _data - additional data
    */
    function sendHome(address _handlerAddress, uint256 _id, uint256 _homeValue, bytes memory _data) public payable nonReentrant {
        require(msg.value + _homeValue > 0, "Must send ETH and/or HOME");
        require(handlers[_handlerAddress].homeDestinationAddress != address(0), "No handler for given _handlerAddress");

        Handler memory handler = handlers[_handlerAddress];

        if (msg.value > 0) {
            (bool sent, bytes memory data) = handler.ethDestinationAddress.call{value : msg.value}("");
            require(sent, "Failed to send ETH");
        }

        if (_homeValue > 0) {
            _transfer(msg.sender, handler.homeDestinationAddress, _homeValue);
        }

        handler.homeHandlerContract.handleSendHome(msg.sender, handler.ethDestinationAddress, handler.homeDestinationAddress, _id, msg.value, _homeValue, _data);
    }

    /**
    * @notice Allow an address with DEFAULT_ADMIN to register a handler
    * @param _contractAddress - The address of the new handler
    * @param _ethDestinationAddress - sendHome transfers ETH here
    * @param _homeDestinationAddress - sendHome transfers HOME here
    */
    function addHandlerContract(address _contractAddress, address _ethDestinationAddress, address _homeDestinationAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_ethDestinationAddress != address(0) && _homeDestinationAddress != address(0), "Destination cannot be 0");
        require(handlers[_contractAddress].homeDestinationAddress == address(0), "Handler already registered");
        handlers[_contractAddress] = Handler({
            ethDestinationAddress: _ethDestinationAddress,
            homeDestinationAddress: _homeDestinationAddress,
            homeHandlerContract: HandlerContract(_contractAddress)
        });
        emit HandlerRegistered(_contractAddress, _ethDestinationAddress, _homeDestinationAddress);
    }
}