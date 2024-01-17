// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
pragma abicoder v2;

interface INFT {
    /* ================ EVENTS ================ */
    event Minted(
        address indexed payer,
        uint256 indexed tokenId,
        uint256 eventTime
    );

    /* ================ VIEWS ================ */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /* ================ ADMIN ACTIONS ================ */
    function setBaseURI(string memory newBaseURI) external;

    /**
     * @dev mint the amount of tokens to the _msgSender()
     * @notice the msg.values should be larger or equal than the tokens total price
     */
    function freeMint(bytes32[] calldata merkleProof) external;
}
