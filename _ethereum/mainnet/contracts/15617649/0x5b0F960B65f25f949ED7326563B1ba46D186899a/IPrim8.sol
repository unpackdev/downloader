// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IPrim8 {
    enum States {
        // 1. mint setup state for dev mint
        MintSetup,
        // 2. reservedCommunity mint state for whitlists mint
        ReservedCommunityMintStarted,
        ReservedCommunityMintEnded,
        // 3. public mint state for public mint
        PublicMintStarted,
        PublicMintEnded,
        // 4. airdrop state for airdrop mint
        Airdrop
    }

    function initialize(
        string memory title,
        string memory symbolValue,
        uint256 maxSupplyValue,
        uint256 reservedForDevValue,
        uint256 reservedForCommunityValue,
        uint256 limitAmountPerWalletValue,
        uint256 maxBatchSizeValue,
        string memory defaultTokenURIValue,
        address beneficiaryValue,
        address seedGeneratorContractValue
    ) external;

    function setState(States state) external;

    function getState() external view returns (States);

    function reservedForDev() external view returns (uint256);

    function reservedDevMint(uint256 quantity) external;

    function reservedForCommunity() external view returns (uint256);

    function reservedCommunityMint(address to, uint256 quantity) external;

    function reservedCommunityMinted() external view returns (uint256);

    function limitAmountPerWallet() external view returns (uint256);

    function publicMint(uint256 quantity) external;

    function allowAirdrop(address addr) external;

    function allowAirdrops(address[] memory addrs) external;

    function setAirdropAllowance(address addr, uint256 quantity) external;

    function airdrop(address[] memory addresses, uint256[] memory quantities)
        external;

    function airdropMinted() external view returns (uint256);

    function defaultTokenURI() external view returns (string memory);

    function baseTokenURI() external view returns (string memory);

    function seed() external view returns (uint256);

    function seedGeneratorContract() external view returns (address);

    function revealBlock() external view returns (uint256);

    function isRevealed() external view returns (bool);

    function metadata(uint256 tokenId) external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function setBaseTokenURI(string memory newBaseTokenURI) external;

    function setSeed(uint256 randomNumber) external;

    function setRevealBlock(uint256 blockNumber) external;

    function setSeedGeneratorContract(address newSeedGeneratorContract) external;

    function maxSupply() external view returns (uint256);

    function setMaxSupply(uint256 newMaxSupply) external;

    function beneficiary() external view returns (address);

    function setBeneficiary(address beneficiaryValue) external;

    function withdraw() external;

    function maxBatchSize() external view returns (uint256);
}
