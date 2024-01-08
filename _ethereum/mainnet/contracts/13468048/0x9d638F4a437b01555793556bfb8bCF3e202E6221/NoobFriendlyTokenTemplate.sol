//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./PaymentSplitter.sol";
import "./ERC721Enumerable.sol";

struct BaseSettings {
    string name;
    string symbol;
    address[] payees;
    uint[] shares;
    uint32 typeOfNFT;
    uint32 maxSupply;
}

struct BaseSettingsInfo {
    string name;
    string symbol;
    uint32 typeOfNFT;
    uint32 maxSupply;    
}

interface GeneratorInterface {
    function slottingFee() external view returns (uint);
    function genNFTContract(address, BaseSettings calldata) external returns (address);
}

interface TemplateInterface {
    function owner() external returns (address);
    function transferOwnership(address newOwner) external;
}

/**
 @author Justa Liang
 @notice Template of NFT contract
 */
abstract contract NoobFriendlyTokenTemplate is Ownable, PaymentSplitter, ERC721Enumerable {

    struct Settings {
        uint32 maxSupply;
        uint32 maxPurchase;
        uint32 typeOfNFT;
        uint160 startTimestamp;
    }

    /// @notice Template settings
    Settings public settings;
    
    /// @notice Prefix of tokenURI
    string public baseURI;

    /// @notice Whether contract is initialized
    bool public isInit;

    /// @dev Setup type and max supply 
    constructor(
        uint32 typeOfNFT_,
        uint32 maxSupply_
    ) {
        settings.typeOfNFT = typeOfNFT_;
        settings.maxSupply = maxSupply_;
        isInit = false;
    }

    /// @dev Make the contract to initialized only once
    modifier onlyOnce() {
        require(!isInit, "template: init already");
        isInit = true;
        _;
    }

    /// @notice get BaseSettings
    function getBaseSettings() external view returns (BaseSettingsInfo memory) {
        return  BaseSettingsInfo(
                    name(),
                    symbol(),
                    settings.typeOfNFT,
                    settings.maxSupply
                );
    }
}