// SPDX-License-Identifier: GPL-3.0

/*
       %%%%%%%   &%%%%%,      %%      %%%     %%%    %%%%%%    %%%%%%        %%%%%%%%%%%%%%%%%%%    
       %%#       &%   %%.    (%%%     %%%%   #%%%    %%        %%   %%                       %%%    
       %%#       &%   &%     %&.%.    %%%%%  % %%    %%        %%   %%                       %%%    
       %%%%%%    &%%%%#     &%  %%    %%% %%%% %%    %%%%%%    %%   %%                       %%%    
       %%#       &%  %%     %%%%%%(   %%% #%%  %%    %%        %%   %%                       %%%    
       %%#       &%   %%    %%   %%   %%%      %%    %%        %%   %%                       %%%    
       %%#       &%    %%   %%   %%   %%%      %%    %%%%%%    %%&%&%%                       %%%    
                                                                                             %%%    
                                                                                             %%%    
                                                                                             %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                               Framer Contract                                     %%%    
       %%#                              https://framed.app                                   %%%    
       %%#                                 @nft_framed                                       %%%    
       %%#                                   2021-12                                         %%%    
       %%#                               Code by JD & BC                                     %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   &%%    
       %%#                                                                                          
       %%#                                                                                          
       %%#                                                                                          
       %%#                                                         %%    %%    %%%%%%  %%%%%%%%%%    
       %%#                                                         %%%   %%    %%          %%       
       %%#                                                         %%%%  %%    %%          %%       
       %%#                                                         %% %% %%    %%%%%%      %%       
       %%#                                                         %%  %%%%    %%          %%       
       %%%                                                         %%   %%%    %%          %%       
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&          %%    %%    %%          %%           
*/


pragma solidity >=0.7.0 <0.9.0;

import "./IFramer.sol";
import "./Counters.sol";
import "./Address.sol";
import "./ERC721.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";
import "./IERC165.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./IFrameMetadata.sol";

interface IERC721Simplified {
    function ownerOf(uint256 tokenId) external returns (address);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC1155Simplified {
    function balanceOf(address account, uint256 id) external returns (uint256);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}


contract Framer is 
    ERC721,
    ERC721Holder,
    ERC1155Holder,
    Ownable,
    ReentrancyGuard,
    IFramer
{
    using Address for address;
    using Counters for Counters.Counter;
    using Strings for uint256;

    struct FramedData {
        address[] tokenContracts;
        uint256[] tokenIds;
    }

    // Interfaces to be used for checking NFT type
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    string public baseURI;

    // Mapping framedId to the framed token data
    mapping(uint256 /* framedId */ => FramedData) private _framedData;

    Counters.Counter private _tokenIdTracker;


    constructor(

    ) ERC721( "Framed", "FRAMED" ) {

    }


    /**
        * @dev Returns the framed data of contained NFTs for a specific frame.
     */
    function framedDetails(uint256 framedId) override public view returns (address[] memory tokenContracts, uint256[] memory tokenIds) {
        FramedData memory framedData = _framedData[framedId];
        return (framedData.tokenContracts, framedData.tokenIds);
    }


    /**
        * @dev Custom URI routing -- will proxy to external contract if first token contract is IFrameMetadata compatible
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Framer: URI query for nonexistent token");
        FramedData memory framedData = _framedData[tokenId];

        if(IERC165(framedData.tokenContracts[0]).supportsInterface(type(IFrameMetadata).interfaceId)) {
            return IFrameMetadata(framedData.tokenContracts[0]).framedURI(tokenId);
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    /** 
    * @notice Get token metadata base uri
    * @param newURI new base URI
    */
    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }


    /**
     * @dev Frame tokens into new ERC721
     * @param tokenContracts an array of the contract addresses for the tokens to frame
     * @param tokenIds an array of the token ids of the tokens to frame
     * @return framedId returns the tokenId of the framed ERC721
     */
    function frame(address[] calldata tokenContracts, uint256[] calldata tokenIds) override public nonReentrant returns (uint256 framedId) {

        address fromAddress = _msgSender();

        // ensure at least one token
        require(tokenIds.length > 0, "Framer: Cannot frame 0 tokens");

        // ensure tokenIds and addresses are same length
        require(tokenIds.length == tokenContracts.length, "Framer: Mismatch of token ids and addresses.");

        // OWNER IS VALIDATED AS PART OF TRANFER ASSET
        for (uint256 i = 0; i < tokenIds.length; i++) {
            transferAsset(fromAddress, address(this), tokenContracts[i], tokenIds[i]);
        }

        framedId = mintNextFrame(fromAddress);

        // Set frame data
        _framedData[framedId] = FramedData(tokenContracts, tokenIds);

        emit FrameEvent(FrameEventType.Frame, fromAddress, framedId, tokenContracts, tokenIds);

    }

    /**
        * @dev Mints next available frame.
        * Emits:
            - TransferEvent
     */
    function mintNextFrame (address to) internal returns (uint256) {
        // Mint new token that represents ownership of token A and token B
        uint256 framedId = _tokenIdTracker.current();
        _mint(to, framedId);

        // increment framedId
        _tokenIdTracker.increment();

        return framedId;
    }


    /**
     * @dev unframes the underlying NFTs in a frame and transfers them to the current owner of the frame. The framedNft is burnt
     * @param framedId the tokenId of the framed NFT
     * @return tokenContracts tokenIds the array of token contract addresses and ids of the unframed NFTs
     */
    function unframe(uint256 framedId) override public nonReentrant returns (address[] memory tokenContracts, uint256[] memory tokenIds) {
        require(_exists(framedId), "Framer: token does not exist");

        // ensure that caller is the owner
        address owner = ownerOf(framedId);
        require(_msgSender() == owner, "Framer: caller must be owner!");

        // try and transfer underlying tokens to the owner
        FramedData memory framedData = _framedData[framedId];

        // Cleanup:
        // Burn Frame token -- prevents reentrant attack for erc1155 tokens
        _burn(framedId);

        for (uint256 i = 0; i < framedData.tokenIds.length; i++) {
            transferAsset(address(this), owner, framedData.tokenContracts[i], framedData.tokenIds[i]);
        }

        emit FrameEvent(FrameEventType.Unframe, owner, framedId, framedData.tokenContracts, framedData.tokenIds);
        
        tokenContracts = framedData.tokenContracts;
        tokenIds = framedData.tokenIds;

        // clear frame data
        delete _framedData[framedId];
    }


    // FROM here must be msg.sender to prevent ability to take ownership of others' tokens
    function transferAsset(address from, address to, address tokenAddress, uint256 tokenId) internal {
        // check if contract suppoers EIP1155
        if((IERC165(tokenAddress)).supportsInterface(_INTERFACE_ID_ERC1155)) {
            transfer1155(from, to, tokenAddress, tokenId);
        } else {
            // default to 721
            transfer721(from, to, tokenAddress, tokenId);
        }
    }


    // NOTE: The from MUST be msg.sender when framing, otherwise could be able to transfer tokens without
    // permission of owner.
    function transfer721(address from, address to, address tokenAddress, uint256 tokenId) internal {
        // verify owner of token A and B are same owner
        IERC721Simplified tokenContract = IERC721Simplified(tokenAddress);

        // Try and transfer both tokens to this contract
        // Not using safeTransfer in order to support legacy nfts
        tokenContract.transferFrom(from, to, tokenId);

        // Now final check of owner again to ENSURE that correctly transferred to prevent NFT loss
        // and also prevent potential exploits from external NFT contracts (in an overriden transfer function)
        address newTokenOwner = tokenContract.ownerOf(tokenId);
        require(newTokenOwner == to, "Frames: ERC721 token transfer failed!");

    }
    
    function transfer1155(address from, address to, address contractAddress, uint256 tokenId) internal {
        IERC1155Simplified tokenContract = IERC1155Simplified(contractAddress);

        // store previous balance of to address to make sure transfer succeeds
        uint256 prevBalance = tokenContract.balanceOf(to, tokenId);

        // cast contract and attempt transfer
        tokenContract.safeTransferFrom(from, to, tokenId, 1, "");

        // verify transfer is complete and to address has proper balance
        uint256 currBalance = tokenContract.balanceOf(to, tokenId);
        require(currBalance == prevBalance + 1, "Frames: ERC1155 token transfer failed!");

    }
}