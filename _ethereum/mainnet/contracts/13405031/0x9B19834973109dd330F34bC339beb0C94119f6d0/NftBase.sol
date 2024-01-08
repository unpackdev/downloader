// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./SafeMath.sol";
import "./IERC721.sol";
import "./ERC165.sol";
import "./IERC721Metadata.sol";

contract NftBase is ERC165, IERC721,IERC721Metadata {
    // Libraries 
    using SafeMath for uint256;

    // -----------------------------------------------------------------------
    // STATE 
    // -----------------------------------------------------------------------

    // Counter for minted tokens
    uint256 private totalMinted_;
    // Accurate count of circulating supply (decremented on burns)
    uint256 private circulatingSupply_;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    struct TokenInfo{
        address creator;
        address currentOwner;
        string uri;
    }
    string _name;
    string _symbol; 

    // token ID => Owner 
    mapping(uint256 => TokenInfo) internal tokens_;
    // Owner => Token IDs => is owner
    mapping(address => mapping(uint256 => bool)) internal owners_;
    // Owner => tokens owned counter
    mapping(address => uint256) internal ownerBalances_;
    // Approvals for token spending | owner => spender => token ID => approved
    mapping(address => mapping(address => mapping (uint256 => bool))) internal approvals_;
    // Counter for batch mints
    uint256 internal batchMintCounter_;
    // Storage for batch minted tokens (where they are duplicates)
    struct BatchTokens {
        uint256 baseToken;
        uint256[] tokenIDs;
        bool limitedStock;
        uint256 totalMinted;
    }
    // Storage of Batch IDs to their batch tokens
    mapping(uint256 => BatchTokens) internal batchTokens_;
    // Token ID => their batch number. 0 if they are not batch tokens
    mapping(uint256 => uint256) internal isBatchToken_;


    // -----------------------------------------------------------------------
    // EVENTS 
    // -----------------------------------------------------------------------

    event ApprovalSet(
        address owner,
        address spender,
        uint256 tokenID,
        bool approval
    );

    event BatchTransfer(
        address from,
        address to,
        uint256[] tokenIDs
    );

    // -----------------------------------------------------------------------
    // CONSTRUCTOR 
    // -----------------------------------------------------------------------

    constructor(string memory name,
        string memory symbol) {
            _name = name;
            _symbol = symbol;
    }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    /**
     * @param   _tokenID The ID of the token
     * @return  address of the owner for this token  
     */
    function ownerOf(uint256 _tokenID) public override view returns(address) {
        return tokens_[_tokenID].currentOwner;
    }

    /**
     * @param   _tokenID The ID of the token
     * @return  address of the creator of the token
     */
    function creatorOf(uint256 _tokenID) external view returns(address) {
        return tokens_[_tokenID].creator; 
    }

    /**
     * @param   _owner The address of the address to check
     * @return  uint256 The number of tokens the user owns
     */
    function balanceOf(address _owner) public override view returns(uint256) {
        return ownerBalances_[_owner];
    }

    /**
     * @return  uint256 The total number of circulating tokens
     */
    function totalSupply() public  view returns(uint256) {
        return circulatingSupply_;
    } 

    /**
     * @return  uint256 The total number of unique tokens minted
     */
    function totalMintedTokens() external view returns(uint256) {
        return totalMinted_;
    }
   function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
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
        returns(bool)
    {
        return approvals_[_owner][_spender][_tokenID];
    }

    /**
     * @param   _tokenId ID of the token to get the URI of
     * @return  string the token URI
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return tokens_[_tokenId].uri;
    }

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
        external 
    {
        require(
            msg.sender != _spender, 
            "NFT: cannot approve self"
        );
        require(
            tokens_[_tokenID].currentOwner == msg.sender,
            "NFT: Only owner can approve"
        );
        // Set approval status
        approvals_[msg.sender][_spender][_tokenID] = _approvalSpender;

        emit ApprovalSet(
            msg.sender,
            _spender,
            _tokenID,
            _approvalSpender
        );
    }

    // -----------------------------------------------------------------------
    // ERC721 Functions
    // -----------------------------------------------------------------------

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function transferFrom(address from, address to, uint256 tokenId) virtual external override {
         _transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);

        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
    }
    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) virtual external override{
         _transferFrom(from, to, tokenId);

    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) virtual external override{
         _transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool _approved) virtual external override{
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = _approved;
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    // -----------------------------------------------------------------------
    // INTERNAL STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param    _oldOwner Address of the old owner losing the token
     * @param   _newOwner Address of the new owner gaining the token
     * @param   _tokenID ID of the token getting transferred
     */
    function _changeOwner(
        address _oldOwner,
        address _newOwner,
        uint256 _tokenID
    )
        internal
    {
        // Changing the tokens owner to the new owner
        tokens_[_tokenID].currentOwner = _newOwner;
        // Removing the token from the old owner
        owners_[_oldOwner][_tokenID] = false;
        // Reducing the old owners token count
        ownerBalances_[_oldOwner] = ownerBalances_[_oldOwner].sub(1);
        // Adding the token to the new owner
        owners_[_newOwner][_tokenID] = true;
        // Increasing the new owners token count
        ownerBalances_[_newOwner] = ownerBalances_[_newOwner].add(1);
    }

    /**
     * @param   _to Address to transfer to
     * @param   _tokenID Token being transferred
     * @notice  Will revert if to address is the 0x address. Will revert if the 
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function _transfer(
        address _to,
        uint256 _tokenID
    )
        internal 
    {
        require(_to != address(0), "NFT: Cannot send to zero address");
        require(
            tokens_[_tokenID].currentOwner == msg.sender,
            "NFT: Only owner can transfer"
        );
        require(
            _to != msg.sender,
            "NFT: Cannot transfer to self"
        );
        // Updating storage to reflect transfer
        _changeOwner(
            msg.sender,
            _to,
            _tokenID
        );
        emit Transfer(
            msg.sender,
            _to,
            _tokenID
        );
    }

    /**
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Will revert if to address is the 0x address. Will revert if the 
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function _batchTransfer(
        address _to,
        uint256[] memory _tokenIDs
    )
        internal
    {
        require(_to != address(0), "NFT: Cannot send to zero address");
        require(
            _to != msg.sender,
            "NFT: Cannot transfer to self"
        );

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            require(
                tokens_[_tokenIDs[i]].currentOwner == msg.sender,
                "NFT: Only owner can transfer"
            );
            // Updating storage to reflect transfer
            _changeOwner(
                msg.sender,
                _to,
                _tokenIDs[i]
            );
        }

        emit BatchTransfer(
            msg.sender,
            _to,
            _tokenIDs
        );
    }

    /**
     * @param   _from Address being transferee from 
     * @param   _to Address to transfer to
     * @param   _tokenID ID of token being transferred
     * @notice  Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if 
     *          _from is _to address.
     */
    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenID
    )
        internal
    {
        require(_to != address(0), "NFT: Cannot send to zero address");
        require(
            approvals_[_from][msg.sender][_tokenID],
            "NFT: Caller not approved"
        );
        require(
            tokens_[_tokenID].currentOwner == _from,
            "NFT: From is not token owner"
        );
        require(
            _to != _from,
            "NFT: Cannot transfer to self"
        );
        // Removing spender as approved spender of token on owner
        approvals_[_from][msg.sender][_tokenID] = false;
        // Updating storage to reflect transfer
        _changeOwner(
            _from,
            _to,
            _tokenID
        );

        emit Transfer(
            _from,
            _to,
            _tokenID
        );
    }

    /**
     * @param   _from Address being transferee from 
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if 
     *          _from is _to address.
     */
    function _batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIDs
    )
        internal
    {
        require(_to != address(0), "NFT: Cannot send to zero address");
        require(
            _to != _from,
            "NFT: Cannot transfer to self"
        );

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            require(
                approvals_[_from][msg.sender][_tokenIDs[i]],
                "NFT: Caller not approved"
            );
            // Removing spender as approved spender of token on owner
            approvals_[_from][msg.sender][_tokenIDs[i]] = false;
            require(
                tokens_[_tokenIDs[i]].currentOwner == _from,
                "NFT: From is not token owner"
            );
            // Updating storage to reflect transfer
            _changeOwner(
                _from,
                _to,
                _tokenIDs[i]
            );
        }
        
        emit BatchTransfer(
            _from,
            _to,
            _tokenIDs
        );
    }

    /**
     * @param   _owner Address of the owner of the newly created token
     * @param   _tokenID Token ID of the new token created
     */
    function _createToken(
        address _owner,
        address _creator,
        uint256 _tokenID,
        string memory _uri
    )
        internal
    {
        // Setting the creator
        tokens_[_tokenID].creator = _creator;
        // Adding the tokens owner
        tokens_[_tokenID].currentOwner = _owner;
        // Adding the URI for the token
        tokens_[_tokenID].uri = _uri;
        // Adding the token to the owner
        owners_[_owner][_tokenID] = true;
        // Increasing the owners token count
        ownerBalances_[_owner] = ownerBalances_[_owner].add(1);
    }

    /**
     * @param   _to Address receiving the newly minted token
     * @return  uint256 The ID of the new token created
     * @notice  Will revert if _to is the 0x address
     */
    function _mint(address _to, address _creator, string memory _uri) internal returns(uint256) {
        require(_to != address(0), "NFT: Cannot mint to zero address");
        // Incrementing token trackers
        totalMinted_ = totalMinted_.add(1);
        circulatingSupply_ = circulatingSupply_.add(1);

        uint256 tokenID = totalMinted_;
        // Updating the state with the new token
        _createToken(
            _to,
            _creator,
            tokenID,
            _uri
        );

        emit Transfer(
            address(0),
            _to,
            tokenID
        );

        return tokenID;
    }

     /**
     * @param   _to Address receiving the newly minted tokens
     * @param   _amount The amount of tokens to mint
     * @return  uint256[] The IDs of the new tokens created
     * @notice  Will revert if _to is the 0x address
     */
    function _batchMint(
        address _to, 
        address _creator,
        uint256 _amount,
        uint256 _originalTokenID,
        uint256 _batchID
    ) 
        internal 
        returns(uint256[] memory, uint256) 
    {
        require(_to != address(0), "NFT: Cannot mint to zero address");

        uint256[] memory tokenIDs = new uint256[](_amount);

        string memory uri = this.tokenURI(_originalTokenID);

        uint256 batch;

        if(_batchID == 0) {
            batchMintCounter_ += 1;
            batch = batchMintCounter_;
        }

        for (uint256 i = 0; i < _amount; i++) {
            _mint(_to, _creator, uri);
            tokenIDs[i] = totalMinted_;
            batchTokens_[batch].tokenIDs.push(totalMinted_);
        }

        emit BatchTransfer(
            address(0),
            _to,
            tokenIDs
        );

        return (tokenIDs, batch);
    }

    /**
     * @param   _owner Address of the owner 
     * @param   _tokenID Token ID of the token being destroyed
     */
    function _destroyToken(
        address _owner,
        uint256 _tokenID
    )
        internal
    {
        // Reducing circulating supply. 
        circulatingSupply_ = circulatingSupply_.sub(1);
        // Removing the tokens owner
        tokens_[_tokenID].currentOwner = address(0);
        // Remove the tokens creator
        tokens_[_tokenID].creator = address(0);
        // Removing the token from the owner
        owners_[_owner][_tokenID] = false;
        // Decreasing the owners token count
        ownerBalances_[_owner] = ownerBalances_[_owner].sub(1);
    }

    /**
     * @param   _from Address that was the last owner of the token
     * @param   _tokenID Token ID of the token being burnt
     */
    function _burn(address _from, uint256 _tokenID) internal {
        require(_from != address(0), "NFT: Cannot burn from zero address");

        _destroyToken(
            _from,
            _tokenID
        );

        emit Transfer(
            _from,
            address(0),
            _tokenID
        );
    }

    /**
     * @param   _from Address that was the last owner of the token
     * @param   _tokenIDs Array of the token IDs being burnt
     */
    function _batchBurn(address _from, uint256[] memory _tokenIDs) internal {
        require(_from != address(0), "NFT: Cannot burn from zero address");

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            _destroyToken(
                _from,
                _tokenIDs[i]
            );
        }

        emit BatchTransfer(
            _from,
            address(0),
            _tokenIDs
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokens_[tokenId].currentOwner != address(0);
    }
}