// SPDX-License-Identifier: MIT

/* * * * * * * * * * * * * * * * * * * ** * * *
 *  ______        _  _____                    *
 *  | ___ \      | |/  ___|                   *
 *  | |_/ /__  __| |\ `--.   __ _  _ __ ___   *
 *  |  __/ \ \/ /| | `--. \ / _` || '_ ` _ \  *
 *  | |     >  < | |/\__/ /| (_| || | | | | | *
 *  \_|    /_/\_\|_|\____/  \__,_||_| |_| |_| *
 *                                            *
 * * * * * * * * * * * * * * * * * * * ** * * */

pragma solidity 0.8.10;

import "./ERC721.sol";

/// @title PxlSam NFT
/// @author The Swissness 🧀 🇨🇭 🍫
/// @notice This NFT is not transferable
contract PxlSam is ERC721 {

    error NonTransferable();

    string private constant URI = "https://ipfs.io/ipfs/QmXnxdQxJFwqD6kUaHB2awDUxFhssFd8BYxeR4MfMwkdpZ";

    constructor() ERC721("PxlSam", "PxlSam") {
        _safeMint(0xCE3d8791c1bdaCc6b8e1a52B4E6aC140F8a2C8c3, 1);
    }

    function askColleagues() public pure returns(string memory response) {
        response = "Good job!";
        // TODO make this dependent on the ANT price
    }

    function tokenURI(uint256 tokenId) public view  override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        return URI;
    }
    
    function safeTransferFrom(
        address /* from */,
        address /* to */,
        uint256 /* tokenId */,
        bytes memory /* _data */
    ) public pure override {
        revert NonTransferable();
    }

    function transferFrom(
        address /* from */,
        address /* to */,
        uint256 /* tokenId */
    ) public pure override {
        revert NonTransferable();
    }
}
