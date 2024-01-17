//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "./web0.sol";
import "./console.sol";

//////////////////////
//
// Injectooor
// A web0 plugin
//
//////////////////////


contract Injectooor is web0plugin {

    function info() public pure override returns(Info memory) {
        ParamInfo[] memory params = new ParamInfo[](2);
        params[0] = ParamInfo('string', 'Injected into <head>');
        params[1] = ParamInfo('string', 'Injected into <body>');
        return Info('Inject', params);
    }

    function head(uint, Param[] memory params_, bool, address) public override pure returns(string memory){
        return params_[0]._string;
    }

    function body(uint, Param[] memory params_, bool, address) public override view returns(string memory){
        console.log(params_[1]._string);
        return params_[1]._string;
    }

}