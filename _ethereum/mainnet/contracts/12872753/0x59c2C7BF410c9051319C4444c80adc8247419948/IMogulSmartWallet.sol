//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.2;

interface IMogulSmartWallet {
    function owner() external returns (address);

    function initialize(
        address _owner,
        address[] calldata _guardians,
        uint256 _minGuardianVotesRequired,
        uint256 _pausePeriod
    ) external;

    function addGuardians(address[] calldata newGuardians) external;

    function removeGuardians(address[] calldata newGuardians) external;

    function getGuardiansAmount() external view returns (uint256);

    function getAllGuardians() external view returns (address[100] memory);

    function isGuardian(address accountAddress) external view returns (bool);

    function changeOwnerByOwner(address newOwner) external;

    function createChangeOwnerProposal(address newOwner) external;

    function addVoteChangeOwnerProposal() external;

    function removeVoteChangeOwnerProposal() external;

    function changeOwnerByGuardian() external;

    function setMinGuardianVotesRequired(uint256 _minGuardianVotesRequired)
        external;

    function approveERC20(
        address erc20Address,
        address spender,
        uint256 amt
    ) external;

    function transferERC20(
        address erc20Address,
        address recipient,
        uint256 amt
    ) external;

    function transferFromERC20(
        address erc20Address,
        address sender,
        address recipient,
        uint256 amt
    ) external;

    function transferFromERC721(
        address erc721Address,
        address sender,
        address recipient,
        uint256 tokenId
    ) external;

    function safeTransferFromERC721(
        address erc721Address,
        address sender,
        address recipient,
        uint256 tokenId
    ) external;

    function safeTransferFromERC721(
        address erc721Address,
        address sender,
        address recipient,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function approveERC721(
        address erc721Address,
        address spender,
        uint256 tokenId
    ) external;

    function setApprovalForAllERC721(
        address erc721Address,
        address operator,
        bool approved
    ) external;

    function safeTransferFromERC1155(
        address erc1155Address,
        address sender,
        address recipient,
        uint256 tokenId,
        uint256 amt,
        bytes calldata data
    ) external;

    function safeBatchTransferFromERC1155(
        address erc1155Address,
        address sender,
        address recipient,
        uint256[] calldata tokenIds,
        uint256[] calldata amts,
        bytes calldata data
    ) external;

    function setApprovalForAllERC1155(
        address erc1155Address,
        address operator,
        bool approved
    ) external;

    function transferNativeToken(address payable recipient, uint256 amt)
        external;
}
