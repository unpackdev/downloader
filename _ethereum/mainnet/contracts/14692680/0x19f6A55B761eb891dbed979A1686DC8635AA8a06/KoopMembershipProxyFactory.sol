// SPDX-License-Identifier: MIT

/*
              /@,                                                                                             
            @@@@@@@                                                                                           
           @@@@@@@@                         @@@@@                                                             
 ,@@@@@@@@@@*#@@@     @@@@@@%             (@@@@@@                              @@@@@@@          @@@@@@  @@@@. 
@@@@@@@@@            &@@@@@@@            @@@@@@@                            @@@@@( ,@@@@&      @@@@@@@@@@@@@@@
 @@@@@@@     @@@@@@@@@@@@@@@            @@@@@@@    &@@@@/  %@@@@@@@@@@    &@@@@      @@@@#    @@@@@@     *@@@@
  &@       @@@@@@@@                    @@@@@@@@ #@@@@@@  &@@@@     @@@@@  @@@@@(     @@@@@   @@@@@@@@   @@@@@@
  &@       #@@@@@@     .@@            @@@@@@@@@@@@@@@   (@@@@#     ,@@@@  @@@@@@@@@@@@@@@  .@@@@@@@@@@@@@@@@  
 @@@@@@              @@@@@@@#        @@@@@@@@@@@@@@     @@@@@@@( &@@@@@@   @@@@@@@@@@@@&   @@@@@@@@@@@        
@@@@@@@@            @@@@@@@@(       @@@@@@@&@@@@@@&      @@@@@@@@@@@@@@       %@@@@@      @@@@@@@@            
  @@@@@@   %@@@@@@@@#   ((         %@@@@@     @@@@@        @@@@@@@@@@                    @@@@@@@              
          @@@@@@@@                  .@%        @@@@/                                        &*                
           .@@@@@                                                                                                

File: KoopMembershipProxyFactory.sol
Author: Conner Chyung                                                                                          
*/

pragma solidity 0.8.12;

import "./TransparentUpgradeableProxy.sol";
import "./Ownable.sol";
import "./InitializedProxy.sol";
import "./KoopMembership.sol";
import "./ProxyFactoryUpgrade.sol";

contract KoopMembershipProxyFactory is ProxyFactoryUpgrade, Ownable {
    event KoopMembershipCreated(address host, address deployedAddress, string externalId);
    event ImplementationCreated(address deployedAddress);

    address public immutable implementation;

    constructor() {
        // deploy implementation contract with owner set as proxy admin
        KoopMembership _implementation = new KoopMembership(owner());
        implementation = address(_implementation);
    }

    function createKoopMembership(
        string calldata _name,
        string calldata _symbol,
        string calldata _externalId,
        uint96 _royaltyFee
    ) external returns (address) {
        bytes memory _koopInitializationCalldata = 
            abi.encodeWithSignature(
                // If you are getting execution revered with an empty string, something here is probably f'd
                "__KoopMembership_init(string,string,address,address,uint96)",
                _name,
                _symbol,
                msg.sender,
                address(this),
                _royaltyFee
            );

        address koopProxyAddress = address(
            new InitializedProxy(                
                implementation,
                address(this),
                _koopInitializationCalldata
            )
        );
        
        emit KoopMembershipCreated(msg.sender, koopProxyAddress, _externalId);
        return koopProxyAddress;
    }
}