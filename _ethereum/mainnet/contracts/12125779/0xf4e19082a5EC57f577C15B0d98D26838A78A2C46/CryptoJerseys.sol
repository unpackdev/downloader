pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./CustomMintRenameWithERC20.sol";
import "./CustomMintRenameWithEth.sol";

pragma experimental ABIEncoderV2;

contract CryptoJerseys is CustomMintRenameWithEth, CustomMintRenameWithERC20 {
    constructor(string memory baseURI) public ERC721("CryptoJerseys", "CJA") {

        // MINT the 0th eth J to the owner
        _safeMint(owner(), uint256(0));
        _rename(uint256(0), "Vitalik");

        _setBaseURI(baseURI);
    }
}
