// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./base64.sol";
import "./ICode.sol";
import "./HtmlEthFsCode.sol";
import "./EthFsLibDef.sol";
import "./HtmlCode.sol";

contract HtmlScriptCode is ICode, Ownable{

    ICode[] public subCodes;
    EthFsLibDef[] public ethFsLibs;
    HtmlEthFsCode public ethFsCode;
    string public gunzipScript = "gunzipScripts-0.0.1.js";

    function getCodeEncoded(string calldata params) external view returns(string memory) {
        return string.concat('data:text/html;base64,', Base64.encode(abi.encodePacked(getCode(params))));
    }

    function getCode(string calldata params) public view override returns(string memory) {
        string memory s;

        for (uint8 i = 0; i < subCodes.length; i++) {
            s = string.concat(s, "<script>", ICode(subCodes[i]).getCode(params), "</script>");
        }

        for (uint8 i = 0; i < ethFsLibs.length; i++) {
            s = string.concat(s, ethFsCode.fetch(ethFsLibs[i].scriptName, true, ethFsLibs[i].isBase64Encoded));
        }

        return string.concat(s, ethFsCode.fetch(gunzipScript, false, true));

    }

    function setEthFsAddr(address addr) external virtual onlyOwner {
        ethFsCode = HtmlEthFsCode(addr);
    }

    function addSubCode(address addr) external virtual onlyOwner {
        subCodes.push(ICode(addr));
    }

    function clearSubCodes() external virtual onlyOwner {
        delete subCodes;
    }

    function addEthFsLib(string calldata scriptName, bool isBase64Encoded) external virtual onlyOwner {
        ethFsLibs.push(EthFsLibDef(scriptName, isBase64Encoded));
    }

    function clearEthFsLibs() external virtual onlyOwner {
        delete ethFsLibs;
    }

    function setGunzipScript(string calldata scriptName) external virtual onlyOwner {
        gunzipScript = scriptName;
    }

}
