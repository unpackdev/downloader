// SPDX-License-Identifier: UNLICENSED
/// @title Glder
/// @notice Glder
/// @author CyberPnk <cyberpnk@glder.cyberpnk.win>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     


pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IERC165.sol";
import "./IERC721Enumerable.sol";
import "./GenericGld.sol";
import "./GenericGldForEnumerable.sol";

contract Glder is Ownable {
    mapping (uint  => address) public contractMapping;

    constructor() Ownable() {
    }

    event CreateGld(address indexed nftContract, address glderOwner, address indexed gldContractMinter, address gldContract, string name, string symbol, uint gldPerNft);

    function createGld(string memory name, string memory symbol, address nftContract, uint gldPerNft) public {
        uint myhash = uint(keccak256(abi.encodePacked(msg.sender, nftContract)));
        IERC165 nft = IERC165(nftContract);

        bool isEnumerable = false;
        address newContractAddress;

        try nft.supportsInterface(type(IERC721Enumerable).interfaceId) returns (bool myIsEnumerable) {
            isEnumerable = myIsEnumerable;
        } catch {
            isEnumerable = false;
        }

        if (isEnumerable) {
            GenericGldForEnumerable newContractForEnumerable = new GenericGldForEnumerable(nftContract, owner(), msg.sender, name, symbol, gldPerNft);
            newContractAddress = address(newContractForEnumerable);
        } else {
            GenericGld newContract = new GenericGld(nftContract, owner(), msg.sender, name, symbol, gldPerNft);
            newContractAddress = address(newContract);
        }
        contractMapping[myhash] = newContractAddress;

        emit CreateGld(nftContract, owner(), msg.sender, newContractAddress, name, symbol, gldPerNft);
    }

    function myGldContract(address contractMinter, address nftContract) public view returns(address) {
        uint myhash = uint(keccak256(abi.encodePacked(contractMinter, nftContract)));
        return contractMapping[myhash];
    }
}
