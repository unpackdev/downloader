// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC1155.sol";
import "./ERC20.sol";

contract Megacube {

    mapping(string=>bool) redeemedReward ;
    event Reward(string rewardId , address sender ,uint successDate);
    address public owner;
    constructor(){
        owner = msg.sender;
    }

    function getRewards(string memory rewardId , address signer,address sender,uint id,
                        uint amount ,address collection,uint typeERC,
                        bytes memory signature) public returns(bool){
                        require(verify(rewardId, signer, sender,id,amount,collection,signature),"Wrong signature");
                        require(redeemedReward[rewardId]==false, "Reward redeemed");
                        require(sender == msg.sender , "You are not the owner");
                        if(typeERC==721){
                            ERC721 contractAddress = ERC721(collection);
                            contractAddress.safeTransferFrom(signer, msg.sender, id);
                            emit Reward(rewardId, msg.sender , block.timestamp);
                            redeemedReward[rewardId] = true;
                            return true;
                        }
                        if(typeERC==1155){
                            ERC1155 contractAddress = ERC1155(collection);
                            contractAddress.safeTransferFrom(signer,msg.sender, id ,amount,"");
                            emit Reward(rewardId , msg.sender , block.timestamp);
                            redeemedReward[rewardId] = true;
                            return true;
                        }
                        if(typeERC==20){
                            ERC20 contractAddress = ERC20(collection);
                            contractAddress.transferFrom(signer,msg.sender,amount);
                            emit Reward(rewardId , msg.sender , block.timestamp);
                            redeemedReward[rewardId] = true;
                            return true;
                        }
                
                return false ; 
    }

    function getMessageHash(
        string memory rewardId,
        address signer , address sender , 
        uint id , uint amount,
        address collection
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(rewardId, signer, sender,id,amount,collection));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function verify(
        string memory rewardId,
        address signer,
        address sender,
        uint id, uint amount, address collection ,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(rewardId,signer,sender,id,amount,collection);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == owner;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
     
}