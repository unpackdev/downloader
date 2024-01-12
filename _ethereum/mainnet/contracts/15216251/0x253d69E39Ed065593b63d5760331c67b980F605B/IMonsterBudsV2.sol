// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0 <0.8.12;

interface IMonsterBudsV2 {
    
    // Events Section 

    /**
     * @dev Emitted when new tokens are minted by user.
    */

    event TokenDetails(
        address owner,          // owner address of token 
        string[] tokenURI,      // newly created token uri's
        uint256[] tokenId,      // newly created token Id's
        uint256 totalValue       // total price to create them
    );

    /**
     * @dev Emitted when token is purchased by buyer.
    */

    event buyTransfer(
        address indexed sellerAddress,     // sender address
        address indexed buyerAddress,       // buyer address
        uint256 indexed tokenId,           // purchase token id
        uint256 price                      // price of token id
    );

    /**
     * @dev Emitted when new token is minted from two owned tokens.
    */

    event breedSelf(
        address indexed selfAddress,  // msg.sender address
        uint256 motherTokenId,        
        uint256 donorTokenId,
        string tokenURI,             // child seed uri 
        uint256 newTokenId,          // new minted child id 
        uint256 sktFeePrice          // fee to skt wallet 
    );

    /**
     * @dev Emitted when new tokens is minted by hybreed between owned and another users tokens.
    */

    event hybreed(
        address indexed requesterEthAddress,  // msg.sender address
        address indexed accepterEthAddress,   // wallet address of accepter
        uint256 motherTokenId,                // token id of msg.sender
        uint256 donorTokenId,                 // token id of accepter
        string tokenURI,                      // new minted child uri
        uint256 newTokenId,                   // new minted child id
        uint256 breedReqId,                   // breed request id
        uint256 sktFeePrice,                  // fee to skt wallet
        uint256 accepterFeePrice              // fee to accepter
    );

    /**
     * @dev Emitted when free token is minted by ppp user.
    */

    event FreeTokenDetails(
        uint256 parentTokenId,
        address owner,          // owner address of token 
        string tokenURI,      // newly created token uri
        uint256 tokenId,    // newly created token Id
        bool status
    );

    /**
     * @dev Emitted when token is upgraded by user.
    */

    event PfpDetails(
        address tokenOwner, 
        uint256 tokenId,
        uint256 price
    );

    /**
     * @dev mints the ERC721 NFT tokens.
     * 
     * Returns
     * - array of newly token counts.
     *
     * Emits a {TokenDetails} event.
    */
    
    function createCollectible(uint256 quantity) external payable returns (uint256[] memory);

    /**
     * @dev user can create new ERC721 token by hybriding with another token.
     *
     * Returns
     * - new token count.
     *
     * Emits a {hybreed} event.
    */

    function hybreedCollectiable( uint256 req_token_id, uint256 accept_token_id, uint256 breed_req_id) external payable returns (uint256);

    // /**
    //  * @dev free mint for ppp users.
    //  *
    //  * Returns
    //  * - new token count.
    //  *
    //  * Emits a {FreeTokenDetails} event.
    // */
    // function freeMint() external returns(uint256);

}