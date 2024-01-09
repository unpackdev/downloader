// contracts/token/ERC721/spaces/RareSpaceNFTContractFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./Ownable.sol";
import "./Clones.sol";
import "./RareSpaceNFT.sol";
import "./IMarketplaceSettings.sol";
import "./ISpaceOperatorRegistry.sol";

contract RareSpaceNFTContractFactory is Ownable {
    IMarketplaceSettings public marketplaceSettings;
    ISpaceOperatorRegistry public spaceOperatorRegistry;

    address public rareSpaceNFT;

    event RareSpaceNFTContractCreated(
        address indexed _contractAddress,
        address indexed _operator
    );

    constructor(address _marketplaceSettings, address _spaceOperatorRegistry) {
        require(_marketplaceSettings != address(0));
        require(_spaceOperatorRegistry != address(0));

        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
        spaceOperatorRegistry = ISpaceOperatorRegistry(_spaceOperatorRegistry);

        RareSpaceNFT _rareSpaceNFT = new RareSpaceNFT();
        rareSpaceNFT = address(_rareSpaceNFT);
    }

    function setIMarketplaceSettings(address _marketplaceSettings)
        external
        onlyOwner
    {
        require(_marketplaceSettings != address(0));
        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
    }

    function setRareSpaceNFT(address _rareSpaceNFT) external onlyOwner {
        require(_rareSpaceNFT != address(0));
        rareSpaceNFT = _rareSpaceNFT;
    }

    function createRareSpaceNFTContract(
        string calldata _name,
        string calldata _symbol
    ) public returns (address) {
        address spaceAddress = Clones.clone(rareSpaceNFT);
        RareSpaceNFT(spaceAddress).init(_name, _symbol, msg.sender);
        emit RareSpaceNFTContractCreated(spaceAddress, msg.sender);

        marketplaceSettings.setERC721ContractPrimarySaleFeePercentage(
            spaceAddress,
            15
        );

        spaceOperatorRegistry.setPlatformCommission(msg.sender, 5);

        return spaceAddress;
    }
}
