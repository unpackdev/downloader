// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./ECDSA.sol";
import "./Interfaces.sol";
//import "./console.sol"; 

/*
█▀█ █▀█ █ █▀ █▀▄▀█   █▄▄ █▀█ █ █▀▄ █▀▀ █▀▀
█▀▀ █▀▄ █ ▄█ █░▀░█   █▄█ █▀▄ █ █▄▀ █▄█ ██▄

The Ethernal Elves Gasles multichain bridge
*/


contract PrismBridge {

    using ECDSA for bytes32;

    bool public isBridgeOpen;    
    bool public initialized;
    address public admin;
    address validator;
    
    mapping(address => bool)   public auth;  
    mapping(bytes => uint256)  public usedSignatures; 
    
    IElves public elves;
    ///Add more assets here

   function initialize() public {
    
       require(!initialized, "Already initialized");
       admin                = msg.sender;   
       initialized          = true;
       isBridgeOpen         = true;
    }

    function setAddresses(address _elves, address _validator)  public {
       onlyOwner();
       elves                = IElves(_elves);
       validator            = _validator;
     
    }

    function setAuth(address[] calldata adds_, bool status) public {
        onlyOwner();
                
        for (uint256 index = 0; index < adds_.length; index++) {
               auth[adds_[index]] = status;
        }
    } 

    function flipActiveStatus() external {
        onlyOwner();
        isBridgeOpen = !isBridgeOpen;
    }  

//TRANSFERS TO ETH to be called from Polygon Contract
// event emmited by the contract
    function checkIn(uint256[] calldata sentinelIds, uint256[] calldata elderIds, uint256 artifactsAmount, uint256 renAmount, address _owner, uint256 chain) public returns (bool) {

                checkBridgeStatus();             
                
                address owner;

                if(chain == 1){
                    isPlayer();
                    owner = msg.sender;                    
                }else{
                    onlyOperator();
                    owner = _owner;
                }                                     

                uint256 sentinelElves = sentinelIds.length;
                uint256 elderElves = elderIds.length;

                if (sentinelElves > 0) {

                    elves.exitElf(sentinelIds, owner);                  
                                                   
                }

                if (elderElves > 0) {/*wen elders? */}
               
                if (renAmount > 0) {
                    elves.setAccountBalance(owner, renAmount, true, 0);                                              
                }

                if (artifactsAmount > 0) {
                    elves.setAccountBalance(owner, artifactsAmount, true, 2);          
                    
                }
            
             
        }

        function transferTokensIn(uint256[] calldata tokenAmounts, uint256[] calldata tokenIndex, bytes[] memory tokenSignatures, uint256[] calldata timestamps, address[] calldata owners, uint256 chain) public returns (bool) {
        
        checkBridgeStatus();         
        chain == 1 ? isPlayer() : onlyOperator();

                for(uint i = 0; i < owners.length; i++){
                    require(usedSignatures[tokenSignatures[i]] == 0, "Signature already used");   
                    require(_isSignedByValidator(encodeTokenForSignature(tokenAmounts[i], owners[i], timestamps[i], tokenIndex[i]),tokenSignatures[i]), "incorrect signature");
                    usedSignatures[tokenSignatures[i]] = 1;
                    
                    if(tokenIndex[i] == 0){
                        elves.setAccountBalance(owners[i], tokenAmounts[i], false, 0);      
                      
                    }else if(tokenIndex[i] == 1){
                        elves.setAccountBalance(owners[i], tokenAmounts[i], false, 1);      
                      
                    }
                     
                }            
            
        }


    function checkOutSentinel(uint256[] calldata ids, uint256[] calldata sentinel, bytes[] memory signatures, bytes[] memory authCodes, address _owner, uint256 chain) public returns (bool) {
    
        checkBridgeStatus();         
        address owner;

                if(chain == 1){
                    isPlayer();
                    owner = msg.sender;                    
                }else{
                    onlyOperator();
                    owner = _owner;
                }          

                    for (uint256 index = 0; index < ids.length; index++) {  

                        require(usedSignatures[signatures[index]] == 0, "Signature already used");   
                        require(_isSignedByValidator(encodeSentinelForSignature(ids[index], owner, sentinel[index], authCodes[index]),signatures[index]), "incorrect signature");
                        usedSignatures[signatures[index]] = 1;

                    }
                    
        elves.prismBridge(ids, sentinel, owner);

    }


    //CheckOut Permissions 
    function encodeSentinelForSignature(uint256 id, address owner, uint256 sentinel, bytes memory authCode) public pure returns (bytes32) {
        return keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", 
                    keccak256(
                            abi.encodePacked(id, owner, sentinel, authCode))
                            )
                        );
    } 

    function encodeTokenForSignature(uint256 tokenAmount, address owner, uint256 timestamp, uint256 tokenIndex) public pure returns (bytes32) {
                return keccak256(
                        abi.encodePacked("\x19Ethereum Signed Message:\n32", 
                            keccak256(
                                    abi.encodePacked(tokenAmount, owner, timestamp, tokenIndex))
                                    )
                                );
    }  

//////////////////////////////////////////////////////////////////////////////////////////////////
  
            function _isSignedByValidator(bytes32 _hash, bytes memory _signature) private view returns (bool) {
                
                bytes32 r;
                bytes32 s;
                uint8 v;
                    assembly {
                            r := mload(add(_signature, 0x20))
                            s := mload(add(_signature, 0x40))
                            v := byte(0, mload(add(_signature, 0x60)))
                        }
                    
                        address signer = ecrecover(_hash, v, r, s);
                        return signer == validator;
  
            }

            ////////////////MODIFIERS//////////////////////////////////////////

            function checkBalance(uint256 balance, uint256 amount) internal view {    
            require(balance - amount >= 0, "notEnoughBalance");           
            }
            function checkBridgeStatus() internal view {
            require(isBridgeOpen, "bridgenotOpen");       
            }
            function onlyOperator() internal view {    
            require(msg.sender == admin || auth[msg.sender] == true);
            }
            function isPlayer() internal {    
            uint256 size = 0;
            address acc = msg.sender;
            assembly { size := extcodesize(acc)}
            require((msg.sender == tx.origin && size == 0));
            }
            function onlyOwner() internal view {    
            require(admin == msg.sender);
            }

}


