// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AtevadaTokenAccessControl {
    mapping(address => uint256) private authorizedContracts;
    bool private operational = true;
    address public contractOwner;

    constructor(){
		contractOwner = msg.sender;
	}

     modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  
    }

    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireIsCallerAuthorized()
    {
        require(authorizedContracts[msg.sender] == 1, "Caller is not an authorized contract");
        _;
    }

    function setContractOwner(address _newContractOwner) public requireContractOwner {
        require(_newContractOwner != address(0));

        contractOwner = _newContractOwner;
    }

    function isOperational() public view returns(bool) 
    {
        return operational;
    }

    function setOperatingStatus (bool mode) external requireContractOwner 
    {
        operational = mode;
    }

    function authorizeCaller( address contractAddress) external requireContractOwner
    {
        authorizedContracts[contractAddress] = 1;
    }

    function isAuthorized(address contractAddress) external view returns(bool)
    {
        return(authorizedContracts[contractAddress] == 1);
    }

    function deauthorizeCaller( address contractAddress) external requireContractOwner
    {
        delete authorizedContracts[contractAddress];
    }
}