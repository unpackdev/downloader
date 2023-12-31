pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";

contract SWPConfig is Ownable {
    struct Configuration {
        uint16 priceCalculationDuration;
        uint16 priceImpactTolerance;
        uint16 rate;
        uint16 feePool;
        address targetToken;
    }

    mapping(address => Configuration) public tokens;

    function setToken(address _interfaceAddress, uint8 priceCalculationDuration, uint16 priceImpactTolerance, uint16 rate, uint16 feePool, address targetToken) public onlyOwner {
        tokens[_interfaceAddress] = Configuration(priceCalculationDuration, priceImpactTolerance, rate, feePool, targetToken);
    }

    // Function to get a configuration for a specific address
    function getToken(address _contractAddress) public view returns (Configuration memory) {
        return tokens[_contractAddress];
    }
}