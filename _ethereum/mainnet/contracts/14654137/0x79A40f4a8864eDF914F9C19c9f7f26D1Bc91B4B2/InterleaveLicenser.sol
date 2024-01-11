// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.13;
import "./ECDSA.sol";
import "./Strings.sol";

interface ICaller{
    function ownerOf(uint _tokenId) external returns(address);
}


contract InterleaveLicenser {
    using ECDSA for bytes32;

    bytes[] private LicensingSignatures;
    string[] private LicensingMessages;
    address[] private LicensingAddress;

    function License(string memory collection,address collectionAddress, uint256 ID, uint256 duration, bytes memory signature) public{

        //first verify the caller is owner of the APE ID to be licensed
        address owner = ICaller(collectionAddress).ownerOf(ID);
        require(msg.sender == owner, "ERROR: You do not own this token");

        //reconstruct the message that was signed off-chain
        bytes memory unhashedMessage = abi.encodePacked("I agree to license my ",string(collection)," #",Strings.toString(ID)," from contract address ",Strings.toHexString(uint256(uint160(collectionAddress)), 20)," to InterleaveCC for ",Strings.toString(duration)," months.");
        
        //make sure the message signed is indeed the expected one (months, and corresponding tokenID)
        address signer = ECDSA.toEthSignedMessageHash(bytes(unhashedMessage)).recover(signature);


        //make sure the person who signed is also the person who sends
        require(msg.sender == signer, "ERROR: You are not the signer");

        //then and only then, store the signature in the contract
        LicensingSignatures.push(signature);
        LicensingMessages.push(string(unhashedMessage));
        LicensingAddress.push(signer);
    }

    function getLicense(uint licenseID) public view returns (address,string memory,bytes memory){
        return (LicensingAddress[licenseID],LicensingMessages[licenseID],LicensingSignatures[licenseID]);
    }
}