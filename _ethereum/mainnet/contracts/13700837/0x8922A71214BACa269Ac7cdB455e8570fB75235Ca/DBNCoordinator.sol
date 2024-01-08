//SPDX-License-Identifier: MIT
//Copyright 2021 Louis Sobel
pragma solidity ^0.8.0;

/*

    88888888ba,   88888888ba  888b      88 88888888888 888888888888
    88      `"8b  88      "8b 8888b     88 88               88
    88        `8b 88      ,8P 88 `8b    88 88               88
    88         88 88aaaaaa8P' 88  `8b   88 88aaaaa          88
    88         88 88""""""8b, 88   `8b  88 88"""""          88
    88         8P 88      `8b 88    `8b 88 88               88
    88      .a8P  88      a8P 88     `8888 88               88
    88888888Y"'   88888888P"  88      `888 88               88



https://dbnft.io
Generate NFTs by compiling the DBN language to EVM opcodes, then
deploying a contract that can render your art as a bitmap.

> Line 0 0 100 100
         ╱               
        ╱                
       ╱                 
      ╱                  
     ╱                   
    ╱                    
   ╱                     
  ╱                      
 ╱                       
╱                        
*/


import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Strings.sol";

import "./DBNERC721Enumerable.sol"; 
import "./OpenSeaTradable.sol"; 
import "./OwnerSignedTicketRestrictable.sol"; 

import "./Drawing.sol";
import "./Token.sol";
import "./Serialize.sol";

/**
 * @notice Compile DBN drawings to Ethereum Virtual Machine opcodes and deploy the code as NFT art.
 * @dev This contract implements the ERC721 (including Metadata and Enumerable extensions)
 * @author Louis Sobel
 */
contract DBNCoordinator is Ownable, DBNERC721Enumerable, OpenSeaTradable, OwnerSignedTicketRestrictable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /**
     * @dev There's two ~types of tokenId out of the 10201 (101x101) total tokens
     *        - 101 "allowlisted ones" [0, 100]
     *        - And "Open" ones        [101, 10200]
     *      Minting of the allowlisted ones is through mintTokenId function
     *      Minting of the Open ones is through plain mint
     */
    uint256 private constant LAST_ALLOWLISTED_TOKEN_ID = 100;
    uint256 private constant LAST_TOKEN_ID = 10200;

    /**
     * @dev Event emitted when a a token is minted, linking the token ID
     *      to the address of the deployed drawing contract
     */
    event DrawingDeployed(uint256 tokenId, address addr);

    // Configuration
    enum ContractMode { AllowlistOnly, Open }
    ContractMode private _contractMode;
    uint256 private _mintPrice;
    string private _baseExternalURI;

    address payable public recipient;
    bool public recipientLocked;

    // Minting
    Counters.Counter private _tokenIds;
    mapping (uint256 => address) private _drawingAddressForTokenId;

    /**
     * @dev Initializes the contract
     * @param owner address to immediately transfer the contract to
     * @param baseExternalURI URL (like https//dbnft.io/dbnft/) to which
     *        tokenIDs will be appended to get the `external_URL` metadata field
     * @param openSeaProxyRegistry address of the opensea proxy registry, will
     *        be saved and queried in isAllowedForAll to facilitate opensea listing
     */
    constructor(
        address owner,
        string memory baseExternalURI,
        address payable _recipient,
        address openSeaProxyRegistry
    ) ERC721("Design By Numbers NFT", "DBNFT") {
        transferOwnership(owner);

        _baseExternalURI = baseExternalURI;
        _contractMode = ContractMode.AllowlistOnly;

        // first _open_ token id
        _tokenIds._value = LAST_ALLOWLISTED_TOKEN_ID + 1;

        // initial mint price
        _mintPrice = 0;

        // initial recipient
        recipient = _recipient;

        // set up the opensea proxy registry
        _setOpenSeaRegistry(openSeaProxyRegistry);
    }


    /******************************************************************************************
     *      _____ ____  _   _ ______ _____ _____ 
     *     / ____/ __ \| \ | |  ____|_   _/ ____|
     *    | |   | |  | |  \| | |__    | || |  __ 
     *    | |   | |  | | . ` |  __|   | || | |_ |
     *    | |___| |__| | |\  | |     _| || |__| |
     *     \_____\____/|_| \_|_|    |_____\_____|
     *
     * Functions for configuring / interacting with the contract itself
     */

    /**
     * @notice The current "mode" of the contract: either AllowlistOnly (0) or Open (1).
     *         In AllowlistOnly mode, a signed ticket is required to mint. In Open mode,
     *         minting is open to all.
     */
    function getContractMode() public view returns (ContractMode) {
        return _contractMode;
    }

    /**
     * @notice Moves the contract mode to Open. Only the owner can call this. Once the
     *         contract moves to Open, it cannot be moved back to AllowlistOnly
     */
    function openMinting() public onlyOwner {
        _contractMode = ContractMode.Open;
    }

    /**
     * @notice Returns the current cost to mint. Applies to either mode.
     *         (And of course, this does not include gas ⛽️)
     */
    function getMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    /**
     * @notice Sets the cost to mint. Only the owner can call this.
     */
    function setMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    /**
     * @notice Sets the recipient. Cannot be called after the recipient is locked.
     *         Only the owner can call this.
     */
    function setRecipient(address payable to) public onlyOwner {
        require(!recipientLocked, "RECIPIENT_LOCKED");
        recipient = to;
    }

    /**
     * @notice Prevents any future changes to the recipient.
     *         Only the owner can call this.
     * @dev This enables post-deploy configurability of the recipient,
     *      combined with the ability to lock it in to facilitate
     *      confidence as to where the funds will be able to go.
     */
    function lockRecipient() public onlyOwner {
        recipientLocked = true;
    }

    /**
     * @notice Disburses the contract balance to the stored recipient.
     *         Only the owner can call this.
     */
    function disburse() public onlyOwner {
        recipient.transfer(address(this).balance);
    }


    /******************************************************************************************
     *     __  __ _____ _   _ _______ _____ _   _  _____ 
     *    |  \/  |_   _| \ | |__   __|_   _| \ | |/ ____|
     *    | \  / | | | |  \| |  | |    | | |  \| | |  __ 
     *    | |\/| | | | | . ` |  | |    | | | . ` | | |_ |
     *    | |  | |_| |_| |\  |  | |   _| |_| |\  | |__| |
     *    |_|  |_|_____|_| \_|  |_|  |_____|_| \_|\_____|
     *
     * Functions for minting tokens!
     */

    /**
     * @notice Mints a token by deploying the given drawing bytecode
     * @param bytecode The bytecode of the drawing to mint a token for.
     *        This bytecode should have been created by the DBN Compiler, otherwise
     *        the behavior of this function / the subsequent token is undefined.
     *
     * Requires passed value of at least the current mint price.
     * Will revert if there are no more tokens available or if the current contract
     * mode is not yet Open.
     */
    function mint(bytes memory bytecode) public payable {
        require(_contractMode == ContractMode.Open, "NOT_OPEN");

        uint256 tokenId = _tokenIds.current();
        require(tokenId <= LAST_TOKEN_ID, 'SOLD_OUT');
        _tokenIds.increment();

        _mintAtTokenId(bytecode, tokenId);
    }

    /**
     * @notice Mints a token at the specific token ID by deploying the given drawing bytecode.
     *         Requires passing a ticket id and a signature generated by the contract owner
     *         granting permission for the caller to mint the specific token ID.
     * @param bytecode The bytecode of the drawing to mint a token for
     *        This bytecode should have been created by the DBN Compiler, otherwise
     *        the behavior of this function / the subsequent token is undefined.
     * @param tokenId The token ID to mint. Needs to be in the range [0, LAST_ALLOWLISTED_TOKEN_ID]
     * @param ticketId The ID of the ticket; included as part of the signed data
     * @param signature The bytes of the signature that must have been generated
     *        by the current owner of the contract.
     *
     * Requires passed value of at least the current mint price.
     */
    function mintTokenId(
        bytes memory bytecode,
        uint256 tokenId,
        uint256 ticketId,
        bytes memory signature
    ) public payable onlyWithTicketFor(tokenId, ticketId, signature) {
        require(tokenId <= LAST_ALLOWLISTED_TOKEN_ID, 'WRONG_TOKENID_RANGE');

        _mintAtTokenId(bytecode, tokenId);
    }

    /**
     * @dev Internal function that does the actual minting for both open and allowlisted mint
     * @param bytecode The bytecode of the drawing to mint a token for
     * @param tokenId The token ID to mint
     */
    function _mintAtTokenId(
        bytes memory bytecode,
        uint256 tokenId
    ) internal {
        require(msg.value >= _mintPrice, "WRONG_PRICE");

        // Deploy the drawing
        address addr = Drawing.deploy(bytecode, tokenId);

        // Link the token ID to the drawing address
        _drawingAddressForTokenId[tokenId] = addr;

        // Mint the token (to the sender)
        _safeMint(msg.sender, tokenId);

        emit DrawingDeployed(tokenId, addr);
    }


    /**
     * @notice Allows gas-less trading on OpenSea by safelisting the ProxyRegistry of the user
     * @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
     * @inheritdoc ERC721
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator) || _isOwnersOpenSeaProxy(owner, operator);
    }


    /******************************************************************************************
     *     _______ ____  _  ________ _   _   _____  ______          _____  ______ _____   _____  
     *    |__   __/ __ \| |/ /  ____| \ | | |  __ \|  ____|   /\   |  __ \|  ____|  __ \ / ____| 
     *       | | | |  | | ' /| |__  |  \| | | |__) | |__     /  \  | |  | | |__  | |__) | (___   
     *       | | | |  | |  < |  __| | . ` | |  _  /|  __|   / /\ \ | |  | |  __| |  _  / \___ \  
     *       | | | |__| | . \| |____| |\  | | | \ \| |____ / ____ \| |__| | |____| | \ \ ____) | 
     *       |_|  \____/|_|\_\______|_| \_| |_|  \_\______/_/    \_\_____/|______|_|  \_\_____/  
     *
     * Functions for reading / querying tokens
     */

    /**
     * @dev Helper that gets the address for a given token and reverts if it is not present
     * @param tokenId the token to get the address of
     */
    function _addressForToken(uint256 tokenId) internal view returns (address) {
        address addr = _drawingAddressForTokenId[tokenId];
        require(addr != address(0), "UNKNOWN_ID");

        return addr;
    }

    /**
     * @dev Helper that pulls together the metadata struct for a given token
     * @param tokenId the token to get the metadata for
     * @param addr the address of its drawing contract
     */
    function _getMetadata(uint256 tokenId, address addr) internal view returns (Token.Metadata memory) {
        string memory tokenIdAsString = tokenId.toString();

        return Token.Metadata(
            string(abi.encodePacked("DBNFT #", tokenIdAsString)),
            string(Drawing.description(addr)),
            string(abi.encodePacked(_baseExternalURI, tokenIdAsString)),
            uint256(uint160(addr)).toHexString()
        );
    }

    /**
     * @notice The ERC721 tokenURI of the given token as an application/json data URI
     * @param tokenId the token to get the tokenURI of
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        address addr = _addressForToken(tokenId);
        (, bytes memory bitmapData) = Drawing.render(addr);

        Token.Metadata memory metadata = _getMetadata(tokenId, addr);
        return Serialize.tokenURI(bitmapData, metadata);
    }

    /**
     * @notice Returns the metadata of the token, without the image data, as a JSON string
     * @param tokenId the token to get the metadata of
     */
    function tokenMetadata(uint256 tokenId) public view returns (string memory) {
        address addr = _addressForToken(tokenId);
        Token.Metadata memory metadata = _getMetadata(tokenId, addr);
        return Serialize.metadataAsJSON(metadata);
    }

    /**
     * @notice Returns the underlying bytecode of the drawing contract
     * @param tokenId the token to get the drawing bytecode of
     */
    function tokenCode(uint256 tokenId) public view returns (bytes memory) {
        address addr = _addressForToken(tokenId);
        return addr.code;
    }

    /**
     * @notice Renders the token and returns an estimate of the gas used and the bitmap data itself
     * @param tokenId the token to render
     */
    function renderToken(uint256 tokenId) public view returns (uint256, bytes memory) {
        address addr = _addressForToken(tokenId);
        return Drawing.render(addr);
    }

    /**
     * @notice Returns a list of which tokens in the [0, LAST_ALLOWLISTED_TOKEN_ID]
     *         have already been minted.
     */
    function mintedAllowlistedTokens() public view returns (uint256[] memory) {
        uint8 count = 0;
        for (uint8 i = 0; i <= LAST_ALLOWLISTED_TOKEN_ID; i++) {
            if (_exists(i)) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        count = 0;
        for (uint8 i = 0; i <= LAST_ALLOWLISTED_TOKEN_ID; i++) {
            if (_exists(i)) {
                result[count] = i;
                count++;
            }
        }

        return result;
    }
}
