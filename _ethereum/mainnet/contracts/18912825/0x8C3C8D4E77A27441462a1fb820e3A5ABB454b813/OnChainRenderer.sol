//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./Strings.sol";
import "./base64.sol";
import "./IArtParams.sol";
import "./ICode.sol";
import "./IRenderer.sol";
import "./IArtData.sol";
import "./IArtCode.sol";
import "./IArtHtml.sol";
import "./Structs.sol";

contract OnChainRenderer is IRenderer, Ownable
{
    using Strings for uint256;

    address public _codeAddr;
    IParams public _artParams;

    function render(
        string calldata tokenSeed,
        uint256 tokenId,
        BaseAttributes memory atts,
        bool isSample,
        IArtData.ArtProps memory artProps
    )
    external
    view
    virtual
    override
    returns (string memory)
    {
        string memory htmlStr = getHtmlString(tokenSeed,tokenId,atts,isSample,artProps);
        return string.concat('data:text/html;base64,',
            Base64.encode(abi.encodePacked(htmlStr)));
    }


    function getHtmlString(
        string calldata,
        uint256 tokenId,
        BaseAttributes memory atts,
        bool isSample,
        IArtData.ArtProps memory artProps
    )
    public
    view
    virtual
    returns (string memory htmlStr)
    {
        ICode code = ICode(_codeAddr);
        string memory paramsStr = string.concat('[', tokenId.toString(), ',', _artParams.getParmsSequence(atts, isSample, artProps), ']');
        return code.getCode(paramsStr);
    }

    function setCodeAddr(address addr) external virtual onlyOwner {
        _codeAddr = addr;
    }

    function setParamsAddr(address addr) external virtual onlyOwner {
        _artParams = IParams(addr);
    }

    function check() external view {
        require(address(_codeAddr) != address(0), "!code");
        require(address(_artParams) != address(0), "!artPrm");
    }
}
