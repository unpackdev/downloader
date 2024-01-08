//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./NoobFriendlyTokenTemplate.sol";

/**
 @author Justa Liang
 @notice Entry for creating NFT contracts
 */
contract NoobFriendlyTokenAdmin is Ownable, PaymentSplitter {

    /// @notice Store user-issued contract
    mapping (address => TemplateInterface[]) public userContracts;

    /// @notice Map type index to generator address
    mapping (uint32 => GeneratorInterface) public typeToGenerator;

    /// @dev Setup payment splitter
    constructor(
        address[] memory payees,
        uint[] memory shares
    ) 
        PaymentSplitter(payees, shares)
    {}

    /// @dev Update generator address
    function updateGenerator(
        uint32 typeOfNFT,
        address generatorAddr
    ) external onlyOwner {
        typeToGenerator[typeOfNFT] = GeneratorInterface(generatorAddr);
    }

    /// @notice Generate NFT contract
    function genNFTContract(
        BaseSettings calldata baseSettings
    ) external payable {
        GeneratorInterface generator = typeToGenerator[baseSettings.typeOfNFT];
        require(
            address(generator) != address(0),
            "Admin: invalid ticket type"
        );
        require(
            msg.value >= generator.slottingFee(),
            "Admin: slotting fee error"
        );
        TemplateInterface nftContract = TemplateInterface(generator.genNFTContract(_msgSender(), baseSettings));

        userContracts[_msgSender()].push(nftContract);
    }

    /// @notice Get user-issued contract address list
    function getContractList() external view returns (TemplateInterface[] memory) {
        return userContracts[_msgSender()];
    }

    /// @notice Get slotting fee given generator type
    function slottingFee(uint32 generatorType) external view returns (uint) {
        GeneratorInterface generator = typeToGenerator[generatorType];
        require(
            address(generator) != address(0),
            "Admin: invalid ticket type"
        );
        return generator.slottingFee();
    }
}
