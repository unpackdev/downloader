pragma solidity 0.6.6;


interface SanityRates {
    function getSanityRate(address src, address dest) external view returns (uint256);
}

contract QuerySanity {
    SanityRates public oldSanity;
    SanityRates public newSanity;
    address public admin;
    
    address internal constant ETH_TOKEN_ADDRESS = address(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );

    constructor(address _admin, SanityRates _oldSanity, SanityRates _newSanity) public {
        oldSanity = _oldSanity;
        newSanity = _newSanity;
        admin = _admin;
    }
    
    function kill() public {
        selfdestruct(payable(admin));
    }

    
    function tokenToEthDiffPercent(address[] memory tokens) public view returns (uint256[] memory percentageDiff) {
        int256 oldRate; 
        int256 newRate;
        percentageDiff = new uint256[](tokens.length);
        
        for (uint256 i = 0; i < tokens.length; i++) {
            oldRate = int256(oldSanity.getSanityRate(tokens[i], ETH_TOKEN_ADDRESS));
            newRate = int256(newSanity.getSanityRate(tokens[i], ETH_TOKEN_ADDRESS));
            
            percentageDiff[i] = (abs(oldRate - newRate) * 100) / (uint256(oldRate + newRate) / 2);
        }
    }
    
    function ethToTokenDiffPercent(address[] memory tokens) public view returns (uint256[] memory percentageDiff) {
        int256 oldRate; 
        int256 newRate;
        percentageDiff = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            oldRate = int256(oldSanity.getSanityRate(ETH_TOKEN_ADDRESS, tokens[i]));
            newRate = int256(newSanity.getSanityRate(ETH_TOKEN_ADDRESS, tokens[i]));
            
            percentageDiff[i] = (abs(oldRate - newRate) * 100) / (uint256(oldRate + newRate) / 2);
        }
    }

    function abs(int256 val) internal pure returns(uint256) {
        if (val < 0) {
            return uint(val * (-1));
        } else {
            return uint(val);
        }
    }
}