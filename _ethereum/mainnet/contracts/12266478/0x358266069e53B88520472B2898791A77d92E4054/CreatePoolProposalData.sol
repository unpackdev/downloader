// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IProposalData.sol";

contract CreatePoolProposalData is ICreatePoolProposalData {
    
    string private symbol;
    string private name;
    
    uint256 private ethPrice;
    uint256 private minTime;
    uint256 private maxTime;
    uint256 private diffstep;
    uint256 private maxClaims;
    
    address private allowedToken;

    constructor(
        string memory _symbol,
        string memory _name,

        uint256 _ethPrice,
        uint256 _minTIme,
        uint256 _maxTime,
        uint256 _diffStep,
        uint256 _maxCLaim,
        
        address _allowedToken
    ) {
        symbol = _symbol;
        name = _name;
        ethPrice = _ethPrice;
        minTime = _minTIme;
        maxTime = _maxTime;
        diffstep = _diffStep;
        maxClaims = _maxCLaim;
        allowedToken = _allowedToken;
    }

    function data()
        external
        view
        override
        returns (
            string memory,
            string memory,

            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            
            address
        )
    {
        return (
            symbol, 
            name, 
            
            ethPrice, 
            minTime, 
            maxTime, 
            diffstep, 
            maxClaims, 
            
            allowedToken);

    }
}
