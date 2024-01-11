// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./MerkleProof.sol";
import "./AccessControlEnumerable.sol";
import "./Math.sol";

import "./IGenericMintableNFT.sol";

contract NFTClaim is AccessControlEnumerable {

    error ZeroMintError();
    error ExceedingAmountError();
    error ConstructorParamError(string param);

    using Math for uint256;

    IGenericMintableNFT public immutable NFT;

    uint256 public immutable saleCap;
    uint256 public immutable capPerUser;

    /// @notice constructor
    /// @param _NFT address of the nft contract
    /// @param _saleCap maximum of nfts sold during the sale
    /// @param _capPerUser maximum a single address can buy
    constructor(
        address _NFT,
        uint256 _saleCap,
        uint256 _capPerUser
    ) {
        if(_NFT == address(0)) {
            revert ConstructorParamError("_NFT == address(0)");
        }
        if(_saleCap == 0) {
            revert ConstructorParamError("_saleCap == 0");
        }
        if(_capPerUser == 0) {
            revert ConstructorParamError("_capPerUser == 0");
        }

        NFT = IGenericMintableNFT(_NFT);
        saleCap = _saleCap;
        capPerUser = _capPerUser;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Claim an NFT
    /// @param _amount amount of nfts to claim
    function claim(uint256 _amount) external {
        // mint max what's left or max mint per user
        uint256 amount = _amount.min(saleCap - NFT.totalMinted()).min(capPerUser -  NFT.numberMinted(msg.sender));

        if(amount == 0) {
            revert ZeroMintError();
        }

        // External calls at the end of the function
        // mint NFTS
        NFT.mint(amount, msg.sender);
    }
}
