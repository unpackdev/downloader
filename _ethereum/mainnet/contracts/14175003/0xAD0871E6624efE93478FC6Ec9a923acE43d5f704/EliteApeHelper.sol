// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";

contract EliteApeHelper is Ownable {
    mapping(address => uint256) public purchased;
    mapping(address => bool) public contractAllowed;
    address[] nftContracts;

    IEliteApeCoinContract public eliteApeCoinContract;

    constructor (address _eliteApeCoinContract) {
        eliteApeCoinContract = IEliteApeCoinContract(_eliteApeCoinContract);    
    }  

    function setAllowedContracts(address[] calldata _allowedContracts) external onlyOwner {
        for(uint i; i < _allowedContracts.length;i++) {
            contractAllowed[_allowedContracts[i]] = true;
            nftContracts.push(_allowedContracts[i]);
        }  
    }

    function setStageLengthAll(uint256 _stageLength) external onlyOwner {
        for(uint i; i < nftContracts.length;i++) {
            IEliteApeNFTContract(nftContracts[i]).setStageLength(_stageLength);
        }  
    }    

    function setMerkleRootsAll(bytes32[] calldata _merkleRoots) external onlyOwner {
        for(uint i; i < nftContracts.length;i++) {
            IEliteApeNFTContract(nftContracts[i]).setMerkleRoots(_merkleRoots);
        }  
    }    

    function setWindowsAll(uint256 _purchaseWindowOpens, uint256 _purchaseWindowOpensPublic) external onlyOwner {
        for(uint i; i < nftContracts.length;i++) {
            IEliteApeNFTContract(nftContracts[i]).setWindows(_purchaseWindowOpens, _purchaseWindowOpensPublic);
        }  
    }

    function burnAndIncrease(address _account, uint256 _amount) external {
        require(contractAllowed[msg.sender], "sender not allowed");

        eliteApeCoinContract.burnFromRedeem(_account, 0, _amount);
        purchased[_account] += _amount;
    }    
}

interface IEliteApeCoinContract {
    function burnFromRedeem(address account, uint256 id, uint256 amount) external;
 }

interface IEliteApeNFTContract {
    function setWindows(uint256 _purchaseWindowOpens, uint256 _purchaseWindowOpensPublic) external;
    function setStageLength(uint256 _stageLength) external;
    function setMerkleRoots(bytes32[] calldata _merkleRoots) external;
 }
