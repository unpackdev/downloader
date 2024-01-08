//SPDX-License-Identifier: MIT
/**                                                                              
                                            ..                                  
                                          ,*.                                   
                                        .**,                                    
                                       ,***.                                    
                                 .,.   ,***,                                    
                               .**,    *****.                                   
                             .****.    ,*****,                                  
                           .******,     ,******,                                
                         .*******.       .********,              .              
                       ,******.            .*************,,*****.               
                     ,*****.        ,,.        ,************,.                  
                  .,****.         ,*****,                                       
                 ,***,          ,*******,.              ..                      
               ,**,          .*******,.       ,********.                        
                           .******,.       .********,                           
                         .*****,         .*******,                              
                       ,****,          .******,                                 
                     ,***,.          .*****,                                    
                   ,**,.           ./***,                                       
                  ,,             .***,                                          
                               .**,                                 
            __  _______  ____  _   _______ __  ______  ______         
           /  |/  / __ \/ __ \/ | / / ___// / / / __ \/_  __/         
          / /|_/ / / / / / / /  |/ /\__ \/ /_/ / / / / / /            
         / /  / / /_/ / /_/ / /|  /___/ / __  / /_/ / / /             
        /_/  /_/\____/\____/_/_|_//____/_/_/_/\____/_/_/__    ________
          / ____/ __ \/ /   / /   / ____/ ____/_  __/  _/ |  / / ____/
         / /   / / / / /   / /   / __/ / /     / /  / / | | / / __/   
        / /___/ /_/ / /___/ /___/ /___/ /___  / / _/ /  | |/ / /___   
        \____/\____/_____/_____/_____/\____/ /_/ /___/  |___/_____/                                                           
*/
pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./ElectionFactory.sol";
import "./EIP712MetaTransaction.sol";

contract Diplomat is
    AccessControl,
    ElectionFactory,
    EIP712MetaTransaction("Diplomat", "1")
{
    using SafeERC20 for IERC20;

    uint256 public currentElectionStartBlock;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NOT CONTRACT ADMIN");
        _;
    }

    function admin(address wallet, bool value) public onlyAdmin {
        if (value) {
            grantRole(DEFAULT_ADMIN_ROLE, wallet);
        } else {
            revokeRole(DEFAULT_ADMIN_ROLE, wallet);
        }
    }

    function createElection(string memory electionId)
        public
        returns (string memory)
    {
        return _createElection(electionId);
    }

    function getElections() public view returns (string[] memory) {
        return elections;
    }

    function payElection(
        string memory electionId,
        address[] memory _adrs,
        uint256[] memory _shares,
        address _token
    ) public payable {
        _payElection(electionId, _adrs, _shares, _token);
    }

    function deposit() public payable {}

    function withdraw(uint256 amount) public onlyAdmin {
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Failed to withdraw Ether");
    }

    function withdrawToken(IERC20 token, uint256 amount) public onlyAdmin {
        token.safeTransfer(msg.sender, amount);
    }

    // payable fallback function
    receive() external payable {}

    fallback() external payable {}
}
