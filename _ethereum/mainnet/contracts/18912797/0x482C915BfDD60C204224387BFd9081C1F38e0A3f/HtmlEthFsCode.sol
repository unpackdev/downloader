// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IFileStore.sol";
import "./base64.sol";

contract HtmlEthFsCode is Ownable {

    IFileStore public fileStore;// = IFileStore(0x9746fD0A77829E12F8A9DBe70D7a322412325B91);

    function fetch(string calldata ethFsFilename, bool isZipped, bool isBase64Encoded) external view returns(string memory) {
        return string.concat(
            "<script ",
            'id="', ethFsFilename,'" ',
            (isZipped ? "type=\"text/javascript+gzip\" " : ""),
            "src=\"data:text/javascript;base64,",
            (
                isBase64Encoded
                    ? string(fileStore.getFile(ethFsFilename).read())
                    : Base64.encode(abi.encodePacked(fileStore.getFile(ethFsFilename).read()))
            )
            ,
            "\"></script>"
        );
    }

    function setFilestoreAddr(address addr) external virtual onlyOwner {
        fileStore = IFileStore(addr);
    }
}
