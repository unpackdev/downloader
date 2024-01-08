//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./NoobFriendlyTokenTemplate.sol";

/**
 @author Justa Liang
 @notice Template of NFT contract generator
 */
abstract contract NoobFriendlyTokenGenerator is Ownable, GeneratorInterface {

    /// @notice Admin contract address
    address public adminAddr;

    /// @notice Slotting fee of generate one NFT contract
    uint public override slottingFee;

    /// @dev Setup slotting fee, and point to admin contract
    constructor(
        address adminAddr_,
        uint slottingFee_
    ) {
        adminAddr = adminAddr_;
        slottingFee = slottingFee_;
    }
    
    /// @dev Should implement _genContract() in every generator
    function _genContract(
        BaseSettings calldata baseSettings
    ) internal virtual returns (address);

    /**
     @notice Generate NFT contract for user
     @param client User who want to generate an NFT contract
     @param baseSettings See BaseSettings in ./NoobFriendlyTokenTemplate.sol
     */
    function genNFTContract(
        address client,
        BaseSettings calldata baseSettings
    ) external override returns (address) {
        require(_msgSender() == adminAddr);
        address contractAddr =  _genContract(baseSettings);
        TemplateInterface nftContract = TemplateInterface(contractAddr);
        nftContract.transferOwnership(client);
        return contractAddr;
    }

    /// @dev Update slotting fee
    function updateSlottingFee(
        uint newSlottingFee
    ) external onlyOwner {
        slottingFee = newSlottingFee;
    }
} 