// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./IERC721Receiver.sol";

interface IFramer is IERC721Receiver {

    enum FrameEventType {
        Frame,
        Unframe
    }

    /**
        * @dev Emits event when NFT is "framed" or "unframed"
        *
        * @param state framing event type
        * @param tokenIds Token ID for ERC721 and ERC1155 tokens to frame
        * @param tokenContracts contract address for each token
        * @param framedId is the id for the framed token that is either created or burned
        * 
     */
    event FrameEvent(FrameEventType state, address owner, uint256 framedId, address[] tokenContracts, uint256[] tokenIds);


    /**
        * @dev Creates a new NFT that represents two coupled NFTs.
        * Emits a FramedEvent with Frame FrameEventType
        * Creates a new framedNFT, issued to OWNER of token A and B, that represents joined NFT
        * REQUIREUEMTS:
        *   - Owner of token A and B MUST be the same.
        *   - Caller must be authorized to transfer tokens A and B.
        *   - This contract must be preapproved to transfer tokens from contracts at tokenAddress A and B.
        *       - This contract will become the owner of those NFTs, and issue a framedNFT that represents 
        * @param tokenContracts contract address for each token
        * @param tokenIds Token ID for ERC721 and ERC1155 tokens to frame
        * @return framedId token ID of new "framed" NFT
    
     */
    function frame(address[] calldata tokenContracts, uint256[] calldata tokenIds) external returns (uint256 framedId);


    /**
        * @dev ************ WARNING --- USE WITH EXTREME CAUTION! *********************
        * This function will BURN all incoming tokens and issue a new token. This is one way, and 
        * CANNOT be undone. Only use if you know what you are doing.
     */
    //function frameAndBurn(address[] calldata tokenContracts, uint256[] calldata tokenIds) external returns (uint256 framedId);


    /**
        * @dev Unframes two nfts, returning their ownership to the owner of the framed NFT.
        * This also will burn the framed NFT.
        * Emits a FramedEvent with Unframe FrameEventType
        * 
        * @param framedId the ID of the framed token to unframe
    
    
     */
    function unframe(uint256 framedId) external returns (address[] memory tokenContracts, uint256[] memory tokenIds);


    /**
        * @dev Returns the framed data of contained NFTs for a specific frame.
     */
     // frameData?
    function framedDetails(uint256 framedId) external view returns (address[] memory tokenContracts, uint256[] memory tokenIds);




}