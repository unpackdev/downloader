// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./base64.sol";
import "./ICode.sol";
import "./HtmlEthFsCode.sol";
import "./HtmlScriptCode.sol";

contract HtmlCode is ICode, Ownable{

    string public startToTitle =
        '<!DOCTYPE html>'
        '<html lang="en">'
        '<head><title>';
    string public title =
        'Skies by BlockMachine';
    string public titleToStyle =
        '</title>'
        '<meta http-equiv="Content-Security-Policy" content="default-src \'self\';'
        'script-src \'self\' \'unsafe-inline\' data:;'
        'style-src \'unsafe-inline\'">'
        '<meta charset="utf-8"/>';
    string public style =
        '<style>'
        'html, body{'
        'margin:0;'
        'padding:0;'
        '}'
        'canvas{'
        'display:block;'
        'height:100vh;'
        'width:100vw;'
        '}'
        '</style>';
    string public headerToBody =
        '</head>'
        '<body>';

    string public bodyToEnd =
        '</body>'
        '</html>';

    HtmlScriptCode public scriptCode;

    function getCodeEncoded(string calldata params) external view returns(string memory) {
        return string.concat('data:text/html;base64,', Base64.encode(abi.encodePacked(getCode(params))));
    }

    function getCode(string calldata params) public view override returns(string memory) {
        return string.concat(
            startToTitle,
            title,
            titleToStyle,
            style,
            headerToBody,
            scriptCode.getCode(params),
            bodyToEnd
        );
    }

    function setScriptCode(address addr) external virtual onlyOwner {
        scriptCode = HtmlScriptCode(addr);
    }
}
