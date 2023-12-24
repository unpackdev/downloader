// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "./IMinterController.sol";
import "./IStanceRKLCollection.sol";

import "./Ownable.sol";
import "./Constants.sol";

import "./ERC1155.sol";
import "./LibString.sol";

contract StanceRKLCollection is ERC1155, IStanceRKLCollection, Ownable, Constants {
    using LibString for uint256;
    IMinterController public immutable minterController;
    string private baseUri = "ipfs://QmQJN194brEQ5EV3QoCVt9SgNkPzcVs2foVUP6LRDpsZjF/";
    string public name = "RKL x Stance HyperSocks";
    string public symbol = "RKLSH";

    constructor(address _minterController) {
        admin = msg.sender;
        minterController = IMinterController(_minterController);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseUri, id.toString()));
    }

    function mint(address to, uint256[] memory tokenIds, uint256[] memory amounts) external {
        if (to == ZERO_ADDRESS) {
            revert MintToZeroAddr();
        }
        if (tokenIds.length == 0) {
            revert NothingToMint();
        }
        if (tokenIds.length != amounts.length) {
            revert ArgLengthMismatch();
        }
        minterController.checkMinterAllowedForTokenIds(msg.sender, tokenIds);
        if (tokenIds.length == 1) {
            super._mint(to, tokenIds[0], amounts[0], "");
        } else {
            super._batchMint(to, tokenIds, amounts, "");
        }
    }

    // =====================================================================//
    //                              Admin                                   //
    // =====================================================================//

    function setBaseUri(string calldata newBaseUri) external onlyOwner {
        baseUri = newBaseUri;
    }
}
