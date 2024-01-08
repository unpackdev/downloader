// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface INft {

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    /**
     * @param   _tokenID The ID of the token
     * @return  address of the owner for this token  
     */
    function ownerOf(uint256 _tokenID) external view returns(address);

    /**
     * @param   _tokenID The ID of the token
     * @return  address of the creator of the token
     */
    function creatorOf(uint256 _tokenID) external view returns(address);

    /**
     * @param   _owner The address of the address to check
     * @return  uint256 The number of tokens the user owns
     */
    function balanceOf(address _owner) external view returns(uint256);

    /**
     * @return  uint256 The total number of circulating tokens
     */
    function totalSupply() external view returns(uint256);

    /**
     * @param   _owner Address of the owner
     * @param   _spender The address of the spender
     * @param   _tokenID ID of the token to check
     * @return  bool The approved status of the spender against the owner
     */
    function isApprovedSpenderOf(
        address _owner, 
        address _spender, 
        uint256 _tokenID
    )
        external
        view
        returns(bool);

    /**
     * @param   _minter Address of the minter being checked
     * @return  isMinter If the minter has the minter role
     * @return  isActiveMinter If the minter is an active minter 
     */
    function isMinter(
        address _minter
    ) 
        external 
        view 
        returns(
            bool isMinter, 
            bool isActiveMinter
        );

    function isActive() external view returns(bool);

    function isTokenBatch(uint256 _tokenID) external view returns(uint256);

    function getBatchInfo(
        uint256 _batchID
    ) 
        external 
        view
        returns(
            uint256 baseTokenID,
            uint256[] memory tokenIDs,
            bool limitedStock,
            uint256 totalMinted
        );

    // -----------------------------------------------------------------------
    // PUBLIC STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _spender The address of the spender
     * @param   _tokenID ID of the token to check
     * @param   _approvalSpender The status of the spenders approval on the 
     *          owner
     * @notice  Will revert if msg.sender is the spender or if the msg.sender
     *          is not the owner of the token.
     */
    function approveSpender(
        address _spender,
        uint256 _tokenID,
        bool _approvalSpender
    )
        external;

    // -----------------------------------------------------------------------
    //  ONLY AUCTIONS (hub or spokes) STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _to Address of receiver 
     * @param   _tokenID Token to transfer
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if the 
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function transfer(
        address _to,
        uint256 _tokenID
    )
        external;

    /**
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if the 
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function batchTransfer(
        address _to,
        uint256[] memory _tokenIDs
    )
        external;

    /**
     * @param   _from Address being transferee from 
     * @param   _to Address to transfer to
     * @param   _tokenID ID of token being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if 
     *          _from is _to address.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenID
    )
        external;

    /**
     * @param   _from Address being transferee from 
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if 
     *          _from is _to address.
     */
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIDs
    )
        external;

    // -----------------------------------------------------------------------
    // ONLY MINTER STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _tokenCreator Address of the creator. Address will receive the 
     *          royalties from sales of the NFT
     * @param   _mintTo The address that should receive the token. Note that on
     *          the initial sale this address will not receive the sale 
     *          collateral. Sale collateral will be distributed to creator and
     *          system fees
     * @notice  Only valid active minters will be able to mint new tokens
     */
    function mint(
        address _tokenCreator, 
        address _mintTo,
        string calldata identifier,      
        string calldata location,
        bytes32 contentHash 
    ) external returns(uint256);

    /**
     * @param   _mintTo The address that should receive the token. Note that on
     *          the initial sale this address will not receive the sale 
     *          collateral. Sale collateral will be distributed to creator and
     *          system fees
     * @param   _amount Amount of tokens to mint
     * @param   _baseTokenID ID of the token being duplicated
     * @param   _isLimitedStock Bool for if the batch has a pre-set limit
     */
    function batchDuplicateMint(
        address _mintTo,
        uint256 _amount,
        uint256 _baseTokenID,
        bool _isLimitedStock
    )
        external
        returns(uint256[] memory);
}