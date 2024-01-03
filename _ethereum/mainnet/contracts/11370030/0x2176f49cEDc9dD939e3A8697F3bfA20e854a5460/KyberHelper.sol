/**
 * For 0xaa448eff88b1e752d50b87220b543d79eac15a0e reserve
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

abstract contract IConversionRate {

    function getStepFunctionData(address token, uint command, uint param) virtual external view returns(int);
    function getListedTokens() virtual external view returns(address[] memory);
    function getBasicRate(address token, bool buy) virtual external view returns(uint);
    function getRateUpdateBlock(address token) virtual external view returns(uint);
    function getCompactData(address token) virtual external view returns(uint, uint, byte, byte);
    function getTokenControlInfo(address token) virtual external view returns(uint, uint, uint);
    
     mapping(address => mapping(uint=>uint)) public tokenImbalanceData;
}



contract KyberHelper {
    
    // bps - basic rate steps. one step is 1 / 10000 of the rate.
    struct StepFunction {
        int[] x; // quantity for each step. Quantity of each step includes previous steps.
        int[] y; // rate change per quantity step  in bps.
    }

    struct TokenData {
        address token;
        
        uint256 rateUpdateBlock;

        uint256 baseBuyRate;
        uint256 baseSellRate;
        
        StepFunction buyRateQtyStepFunction;       // in bps. higher quantity - bigger the rate.
        StepFunction sellRateQtyStepFunction;      // in bps. higher the qua
        StepFunction buyRateImbalanceStepFunction; // in BPS. higher reserve imbalance - bigger the rate.
        StepFunction sellRateImbalanceStepFunction;
    }
    
    struct RatesCompactData {
        address token;
        byte buy;
        byte sell;
    }
    
    struct TokenControlInfo {
        address token;
        uint minimalRecordResolution;
        uint maxPerBlockImbalance;
        uint maxTotalImbalance;
    }
    
    struct TokenImbalanceData {
        address token;
        uint256[5] data;
    }
    
    function getTokenImbalanceData(address conversionRateContract) external view returns (TokenImbalanceData[] memory data) {
        address[] memory tokens = IConversionRate(conversionRateContract).getListedTokens();
        data = new TokenImbalanceData[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            data[i].token = tokens[i];
            for (uint j = 0; j < 5; j++) {
                data[i].data[j] = IConversionRate(conversionRateContract).tokenImbalanceData(tokens[i], j);
            }
        }
    }
    
    function getTokenControlInfo(address conversionRateContract) external view returns (TokenControlInfo[] memory data) {
        address[] memory tokens = IConversionRate(conversionRateContract).getListedTokens();
        data = new TokenControlInfo[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
             (
                 uint minimalRecordResolution,
                 uint maxPerBlockImbalance,
                 uint maxTotalImbalance
             ) = IConversionRate(conversionRateContract).getTokenControlInfo(tokens[i]);
            
            data[i].token = tokens[i];
            data[i].minimalRecordResolution = minimalRecordResolution;
            data[i].maxPerBlockImbalance = maxPerBlockImbalance;
            data[i].maxTotalImbalance = maxTotalImbalance;
        }
    }
    
    function getRatesCompactData(address conversionRateContract) external view returns (RatesCompactData[] memory data) {
          address[] memory tokens = IConversionRate(conversionRateContract).getListedTokens();
          data = new RatesCompactData[](tokens.length);
          for (uint i = 0; i < tokens.length; i++) {
              (,,byte buy, byte sell) = IConversionRate(conversionRateContract).getCompactData(tokens[i]);
              
              data[i].token = tokens[i];
              data[i].buy = buy;
              data[i].sell = sell;
          }
    }
    
    function getStepFunctionData(address conversionRateContract) external view returns (TokenData[] memory data) {
        address[] memory tokens = IConversionRate(conversionRateContract).getListedTokens();
        
        data = new TokenData[](tokens.length);
        
        for (uint i = 0; i < tokens.length; i++) {
            
            data[i].token = tokens[i];
            
            data[i].rateUpdateBlock = IConversionRate(conversionRateContract).getRateUpdateBlock(tokens[i]);
            
            data[i].baseBuyRate = IConversionRate(conversionRateContract).getBasicRate(tokens[i], true);
            data[i].baseSellRate = IConversionRate(conversionRateContract).getBasicRate(tokens[i], false);
            
            uint[8] memory stepFunctionLenList = [
                uint(getStepFunctionData(conversionRateContract, tokens[i], 0, 0)),  // none
                uint(getStepFunctionData(conversionRateContract, tokens[i], 2, 0)),  // none
                uint(getStepFunctionData(conversionRateContract, tokens[i], 4, 0)),  // none
                uint(getStepFunctionData(conversionRateContract, tokens[i], 6, 0)),  // none
                uint(getStepFunctionData(conversionRateContract, tokens[i], 10, 0)), // buyRateImbalanceStepFunctionXLen
                uint(getStepFunctionData(conversionRateContract, tokens[i], 10, 0)), // buyRateImbalanceStepFunctionYLen
                uint(getStepFunctionData(conversionRateContract, tokens[i], 14, 0)), // sellRateImbalanceStepFunctionXLen
                uint(getStepFunctionData(conversionRateContract, tokens[i], 14, 0))  // sellRateImbalanceStepFunctionYLen
            ]; 
            
            data[i].buyRateQtyStepFunction = initStepFunction(stepFunctionLenList[0], stepFunctionLenList[1]);
            data[i].sellRateQtyStepFunction = initStepFunction(stepFunctionLenList[2], stepFunctionLenList[3]);
            data[i].buyRateImbalanceStepFunction = initStepFunction(stepFunctionLenList[4], stepFunctionLenList[5]);
            data[i].sellRateImbalanceStepFunction = initStepFunction(stepFunctionLenList[6], stepFunctionLenList[7]);

            for (uint j = 0; j < getMaxValue(stepFunctionLenList); j++) {
              if (j < stepFunctionLenList[0]) {
                data[i].buyRateQtyStepFunction.x[j] = getStepFunctionData(conversionRateContract, tokens[i], 1, j);
              }
              if (j < stepFunctionLenList[1]) {
                data[i].buyRateQtyStepFunction.y[j] = getStepFunctionData(conversionRateContract, tokens[i], 3, j);
              }
              if (j < stepFunctionLenList[2]) {
                data[i].sellRateQtyStepFunction.x[j] = getStepFunctionData(conversionRateContract, tokens[i], 5, j);
              }
              if (j < stepFunctionLenList[3]) {
                data[i].sellRateQtyStepFunction.y[j] = getStepFunctionData(conversionRateContract, tokens[i], 7, j);
              }
              if (j < stepFunctionLenList[4]) {
                data[i].buyRateImbalanceStepFunction.x[j] = getStepFunctionData(conversionRateContract, tokens[i], 9, j);
              }
              if (j < stepFunctionLenList[5]) {
                data[i].buyRateImbalanceStepFunction.y[j] = getStepFunctionData(conversionRateContract, tokens[i], 11, j);
              }
              if (j < stepFunctionLenList[6]) {
                data[i].sellRateImbalanceStepFunction.x[j] = getStepFunctionData(conversionRateContract, tokens[i], 13, j);
              }
              if (j < stepFunctionLenList[7]) {
                data[i].sellRateImbalanceStepFunction.y[j] = getStepFunctionData(conversionRateContract, tokens[i], 15, j);
              }  
            }
        }
    }
    
    function getMaxValue(uint[8] memory values) private pure returns (uint) {
        uint max; 
        for(uint i = 0; i < values.length; i++) {
            if(values[i] > max) {
                max = values[i]; 
            } 
        }
        return max;
    }
    
    function initStepFunction(uint xLen, uint yLen) private pure returns (StepFunction memory stepFunc) {
        stepFunc.x = new int[](xLen);
        stepFunc.y = new int[](yLen);
    }
    
    function getStepFunctionData(address conversionRateContract, address token, uint256 command, uint256 param) private view returns (int) {
        try IConversionRate(conversionRateContract).getStepFunctionData(token, command, param) returns (int len) {
            return (len);
        } catch {
            return (0);
        }
    }
    
}