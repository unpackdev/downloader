// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// OZ Libraries
import "./Ownable.sol";

/**
 * @title One Phase Mint Implementation
 * @author @NiftyMike, NFT Culture
 * @dev All the code needed to support a One Phase mint in a standard way.
 */
contract OnePhaseMint is Ownable {
    bool private mintControl;

    uint256 public publicMintPricePerNft;

    modifier isPublicMinting() {
        require(mintControl, 'Minting stopped');
        _;
    }

    constructor(
        uint256 __publicMintPricePerNft
    ) {
        publicMintPricePerNft = __publicMintPricePerNft;
    }

    function setMintingState(bool __publicMintingActive, uint256 __publicMintPricePerNft)
        external
        onlyOwner
    {
        mintControl = __publicMintingActive;

        if (__publicMintPricePerNft > 0) {
            publicMintPricePerNft = __publicMintPricePerNft;
        }
    }

    function isPublicMintingActive() external view returns (bool) {
        return mintControl;
    }

    function supportedPhases() external pure returns (uint256){
        return 1;
    }
}
