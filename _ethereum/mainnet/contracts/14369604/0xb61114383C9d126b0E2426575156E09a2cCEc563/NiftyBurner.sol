// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Withdrawable.sol";
import "./IERC721Burnable.sol";

contract NiftyBurner is Withdrawable {

    constructor(address niftyRegistryContract_) {
        initializeNiftyEntity(niftyRegistryContract_);
    }

    function burnBatch(address tokenContract, uint256[] calldata tokenIds) external {
        require(tokenIds.length <= 500, "Burns up to 500 tokens per tx");
        IERC721Burnable burnableTokenContract = IERC721Burnable(tokenContract);
        for(uint256 i = 0; i < tokenIds.length; i++) {
            burnableTokenContract.burn(tokenIds[i]);
        }
    }    
}