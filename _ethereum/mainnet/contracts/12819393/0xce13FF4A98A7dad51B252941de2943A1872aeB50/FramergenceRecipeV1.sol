// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Ownable.sol";
 
contract FramergenceRecipeV1 is Ownable {
    
    string public script;
    string public scriptIPFS;  
    string public p5jsIPFS;  

    function setScript(string memory _script) public onlyOwner {
        script = _script;
    }

    function setScriptIPFS(string memory _scriptIPFS) public onlyOwner {
        scriptIPFS = _scriptIPFS;
    }

    function setP5jsIPFS(string memory _p5jsIPFS) public onlyOwner {
        p5jsIPFS = _p5jsIPFS;
    }

}