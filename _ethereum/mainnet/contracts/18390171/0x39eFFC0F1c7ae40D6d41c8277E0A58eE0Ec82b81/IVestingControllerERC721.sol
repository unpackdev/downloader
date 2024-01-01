// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IVestingControllerERC721 {
    struct MintParameters {
        address recipient;
        uint256 rndTokenAmount;
        uint256 vestingPeriod;
        uint256 vestingStartTime;
        uint256 cliffPeriod;
    }

    function BPT_TOKEN() external view returns (string memory);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function ECOSYSTEM_RESERVE() external view returns (string memory);

    function GOVERNANCE() external view returns (string memory);

    function INVESTOR_NFT() external view returns (string memory);

    function MINTER_ROLE() external view returns (bytes32);

    function MULTISIG() external view returns (string memory);

    function PAUSER_ROLE() external view returns (bytes32);

    function PERIOD_SECONDS() external view returns (uint256);

    function RAND_TOKEN() external view returns (string memory);

    function READER_ROLE() external view returns (bytes32);

    function REGISTRY() external view returns (address);

    function SAFETY_MODULE() external view returns (string memory);

    function VESTING_CONTROLLER() external view returns (string memory);

    function VESTING_CONTROLLER_SIGNER() external view returns (string memory);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function baseURI() external view returns (string memory);

    function burn(uint256 tokenId) external;

    function claimTokens(uint256 tokenId, uint256 amount) external;

    function distributeTokens(
        bytes memory signature,
        uint256 signatureTimestamp,
        address recipient,
        uint256 rndTokenAmount
    ) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function getClaimableTokens(
        uint256 tokenId
    ) external view returns (uint256);

    function getInvestmentInfo(
        uint256 tokenId
    )
        external
        view
        returns (
            uint256 rndTokenAmount,
            uint256 rndClaimedAmount,
            uint256 vestingPeriod,
            uint256 vestingStartTime,
            uint256 rndStakedAmount
        );

    function getInvestmentInfoForNFT(
        uint256 nftTokenId
    ) external view returns (uint256 rndTokenAmount, uint256 rndClaimedAmount);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getTokenIdOfNFT(
        uint256 tokenIdNFT
    ) external view returns (uint256 tokenId);

    function grantRole(bytes32 role, address account) external;

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function initialize(
        string memory _erc721_name,
        string memory _erc721_symbol,
        uint256 _periodSeconds,
        address _registry
    ) external;

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function mintNewInvestment(
        bytes memory signature,
        uint256 signatureTimestamp,
        MintParameters memory params,
        uint8 nftLevel
    ) external returns (uint256 tokenId);

    function mintNewInvestment(
        bytes memory signature,
        uint256 signatureTimestamp,
        MintParameters memory params
    ) external returns (uint256 tokenId);

    function modifyStakedAmount(uint256 tokenId, uint256 amount) external;

    function name() external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function proxiableUUID() external view returns (bytes32);

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function unpause() external;

    function updateRegistryAddress(address newAddress) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external;
}
