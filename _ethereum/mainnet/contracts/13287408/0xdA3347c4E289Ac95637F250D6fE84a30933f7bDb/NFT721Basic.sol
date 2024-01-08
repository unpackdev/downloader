pragma solidity ^0.8.4;

import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721TokenReceiver.sol";
import "./IERC721Metadata.sol";
import "./support-interface.sol";
import "./address.sol";
import "./safe-math.sol";

/**
 * @dev Implementation of ERC-721 non-fungible token standard.
 */
contract NFT721Basic is
    ERC721,
    ERC721Metadata,
    ERC721TokenReceiver,
    SupportsInterface
{
    using SafeMath for uint256;
    using Address for address;

    /**
     * @dev Magic value of a smart contract that can recieve NFT.
     * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
     */
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    /**
     * @dev An abbreviated name for NFTokens.
     */
    string internal _symbol;

    /**
     * @dev A descriptive name for a collection of NFTs.
     */
    string internal _name;

    /**
     * @dev Count avaiable token id, auto increment.
     */
    uint256 internal _availableId = 0;

    /**
     * @dev Array of all NFT IDs.
     */
    uint256[] public tokens;

    /**
     * @dev Contract owner
     */
    address internal root;

    /**
     * @dev Mapping from token ID to its index in global tokens array.
     */
    mapping(uint256 => uint256) internal idToIndex;

    /**
     * @dev Mapping from NFT ID to metadata uri.
     */
    mapping(uint256 => string) internal idToUri;

    /**
     * @dev A mapping from NFT ID to the address that owns it.
     */
    mapping(uint256 => address) internal idToOwner;

    /**
     * @dev Mapping from owner to list of owned NFT IDs.
     */
    mapping(address => uint256[]) internal ownerToIds;

    /**
     * @dev Mapping from NFT ID to its index in the owner tokens list.
     */
    mapping(uint256 => uint256) internal idToOwnerIndex;

    /**
     * @dev Mapping from NFT ID to approved address.
     */
    mapping(uint256 => address) internal idToApproval;

    /**
     * @dev Mapping from owner address to mapping of operator addresses.
     */
    mapping(address => mapping(address => bool)) internal ownerToOperators;

    /**
     * @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
     * @param _tokenId ID of the NFT to validate.
     */
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender ||
                ownerToOperators[tokenOwner][msg.sender],
            "not owner or operator"
        );
        _;
    }

    /**
     * @dev Guarantees that the msg.sender is allowed to transfer NFT.
     * @param _tokenId ID of the NFT to transfer.
     */
    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender ||
                idToApproval[_tokenId] == msg.sender ||
                ownerToOperators[tokenOwner][msg.sender],
            "not owner approved or operator"
        );
        _;
    }

    /**
     * @dev Guarantees that _tokenId is a valid Token.
     * @param _tokenId ID of the NFT to validate.
     */
    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), "not valid nft");
        _;
    }

    /**
     * @dev Guarantees that sender is the root account.
     */
    modifier onlyRoot() {
        require(msg.sender == root, "should be root account");
        _;
    }

    /**
     * @dev Contract constructor.
     */
    constructor(string memory name, string memory symbol) public {
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
        supportedInterfaces[0x150b7a02] = true; // ERC721TokenReceiver
        _name = name;
        _symbol = symbol;
        root = msg.sender;
    }

    /**
     * @dev Transfers the ownership of an NFT from one address to another address. This function can
     * be changed to payable.
     * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
     * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
     * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
     * function checks if `_to` is a smart contract (code size > 0). If so, it calls
     * `onERC721Received` on `_to` and throws if the return value is not
     * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     * @param _data Additional data with no specified format, sent in call to `_to`.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Transfers the ownership of an NFT from one address to another address. This function can
     * be changed to payable.
     * @notice This works identically to the other function with an extra data parameter, except this
     * function just sets data to ""
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
     * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
     * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
     * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
     * they maybe be permanently lost.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "not owner");
        require(_to != address(0), "zero address");

        _transfer(_to, _tokenId);
    }

    /**
     * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
     * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
     * the current NFT owner, or an authorized operator of the current owner.
     * @param _approved Address to be approved for the given NFT ID.
     * @param _tokenId ID of the token to be approved.
     */
    function approve(address _approved, uint256 _tokenId)
        external
        override
        canOperate(_tokenId)
        validNFToken(_tokenId)
    {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner, "approved address is token owner");

        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    /**
     * @dev Enables or disables approval for a third party ("operator") to manage all of
     * `msg.sender`'s assets. It also emits the ApprovalForAll event.
     * @notice This works even if sender doesn't own any tokens at the time.
     * @param _operator Address to add to the set of authorized operators.
     * @param _approved True if the operators is approved, false to revoke approval.
     */
    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
     * considered invalid, and this function throws for queries about the zero address.
     * @param _owner Address for whom to query the balance.
     * @return Balance of _owner.
     */
    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        require(_owner != address(0), "zero address");
        return _getOwnerNFTCount(_owner);
    }

    /**
     * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
     * invalid, and queries about them do throw.
     * @param _tokenId The identifier for an NFT.
     * @return _owner Address of _tokenId owner.
     */
    function ownerOf(uint256 _tokenId)
        external
        view
        override
        returns (address _owner)
    {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0), "not valid nft");
    }

    /**
     * @dev Get the approved address for a single NFT.
     * @notice Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId ID of the NFT to query the approval of.
     * @return Address that _tokenId is approved for.
     */
    function getApproved(uint256 _tokenId)
        external
        view
        override
        validNFToken(_tokenId)
        returns (address)
    {
        return idToApproval[_tokenId];
    }

    /**
     * @dev Checks if `_operator` is an approved operator for `_owner`.
     * @param _owner The address that owns the NFTs.
     * @param _operator The address that acts on behalf of the owner.
     * @return True if approved for all, false otherwise.
     */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        return ownerToOperators[_owner][_operator];
    }

    /**
     * @dev Actually preforms the transfer.
     * @notice Does NO checks.
     * @param _to Address of a new owner.
     * @param _tokenId The NFT that is being transferred.
     */
    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    /**
     * @dev Mints a new NFT.
     * @param to The address that will own the minted NFT.
     * @param uri of the NFT to be minted by the msg.sender.
     */
    function mint(
        address to,
        string calldata uri,
        uint256 num
    ) external onlyRoot returns (uint256[] memory) {
        return _mint(to, uri, num);
    }

    /**
     * @dev Mints a new NFT.
     * @param targets The address list that will own the minted NFT.
     * @param uris Uri list to be assigned to minted NFT.
     */
    function mintMulti(address[] calldata targets, string[] calldata uris)
        external
        onlyRoot
        returns (uint256[] memory tokenIds)
    {
        require(
            targets.length > 0 && uris.length > 0,
            "target list should not be empty"
        );
        require(
            targets.length == uris.length,
            "targets'length not equal to uris"
        );
        uint256 num = targets.length;
        tokenIds = new uint256[](num);
        for (uint256 i = 0; i < num; i++) {
            string memory _uri = uris[i];
            require(bytes(_uri).length < 256, "uri too long");
            uint256[] memory _tokenIds = _mint(targets[i], _uri, 1);
            for (uint256 j = 0; j < _tokenIds.length; j++) {
                tokenIds[tokenIds.length - 1] = _tokenIds[j];
            }
        }
    }

    /**
     * @dev Mints a new NFT.
     * @notice This is an internal function which should be called from user-implemented external
     * mint function. Its purpose is to show and properly initialize data structures when using this
     * implementation.
     * @param _to The address that will own the minted NFT.
     * @param _uri of the NFT to be minted by the msg.sender.
     */
    function _mint(
        address _to,
        string memory _uri,
        uint256 _num
    ) internal virtual returns (uint256[] memory tokenIds) {
        require(_to != address(0), "zero address");
        require(bytes(_uri).length <= 256, "uri too long");
        tokenIds = new uint256[](_num);
        for (uint256 i = 0; i < _num; i++) {
            // avaialbe token id
            uint256 _tokenId = _availableId++;

            _addNFToken(_to, _tokenId);

            emit Transfer(address(0), _to, _tokenId);

            _setTokenUri(_tokenId, _uri);

            tokens.push(_tokenId);
            tokenIds[i] = _tokenId;
            idToIndex[_tokenId] = tokens.length - 1;
        }
    }

    /**
     * @dev Burns a NFT.
     * @param tokenId ID of the NFT to be burned.
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    /**
     * @dev Burns a NFT.
     * @notice This is an internal function which should be called from user-implemented external burn
     * function. Its purpose is to show and properly initialize data structures when using this
     * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
     * NFT.
     * @param _tokenId ID of the NFT to be burned.
     */
    function _burn(uint256 _tokenId) internal virtual validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        _clearApproval(_tokenId);
        _removeNFToken(tokenOwner, _tokenId);
        emit Transfer(tokenOwner, address(0), _tokenId);

        if (bytes(idToUri[_tokenId]).length != 0) {
            delete idToUri[_tokenId];
        }

        uint256 tokenIndex = idToIndex[_tokenId];
        uint256 lastTokenIndex = tokens.length - 1;
        uint256 lastToken = tokens[lastTokenIndex];

        tokens[tokenIndex] = lastToken;

        tokens.pop();
        // This wastes gas if you are burning the last token but saves a little gas if you are not.
        idToIndex[lastToken] = tokenIndex;
        idToIndex[_tokenId] = 0;
    }

    /**
     * @dev Removes a NFT from owner.
     * @notice Use and override this function with caution. Wrong usage can have serious consequences.
     * @param _from Address from wich we want to remove the NFT.
     * @param _tokenId Which NFT we want to remove.
     */
    function _removeNFToken(address _from, uint256 _tokenId) internal virtual {
        require(idToOwner[_tokenId] == _from, "not owner");
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length - 1;

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].pop();
    }

    /**
     * @dev Assignes a new NFT to owner.
     * @notice Use and override this function with caution. Wrong usage can have serious consequences.
     * @param _to Address to wich we want to add the NFT.
     * @param _tokenId Which NFT we want to add.
     */
    function _addNFToken(address _to, uint256 _tokenId) internal virtual {
        require(idToOwner[_tokenId] == address(0), "nft exists");
        idToOwner[_tokenId] = _to;

        ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = ownerToIds[_to].length - 1;
    }

    /**
     * @dev Set a distinct URI (RFC 3986) for a given NFT ID.
     * @notice This is an internal function which should be called from user-implemented external
     * function. Its purpose is to show and properly initialize data structures when using this
     * implementation.
     * @param _tokenId Id for which we want uri.
     * @param _uri String representing RFC 3986 URI.
     */
    function _setTokenUri(uint256 _tokenId, string memory _uri)
        internal
        validNFToken(_tokenId)
    {
        idToUri[_tokenId] = _uri;
    }

    /**
     * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
     * extension to remove double storage (gas optimization) of owner nft count.
     * @param _owner Address for whom to query the count.
     * @return Number of _owner NFTs.
     */
    function _getOwnerNFTCount(address _owner)
        internal
        view
        virtual
        returns (uint256)
    {
        return ownerToIds[_owner].length;
    }

    /**
     * @dev Actually perform the safeTransferFrom.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     * @param _data Additional data with no specified format, sent in call to `_to`.
     */
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "not owner");
        require(_to != address(0), "zero address");

        _transfer(_to, _tokenId);

        if (_to.isContract()) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                _data
            );
            require(
                retval == MAGIC_ON_ERC721_RECEIVED,
                "not able to receive nft"
            );
        }
    }

    /**
     * @dev Clears the current approval of a given NFT ID.
     * @param _tokenId ID of the NFT to be transferred.
     */
    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }

    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        return MAGIC_ON_ERC721_RECEIVED;
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view override returns (string memory) {
        return _name;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId)
        external
        view
        override
        returns (string memory)
    {
        return idToUri[_tokenId];
    }

    /**
     * @notice Return the tokens owned by an address.
     */
    function tokensByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return ownerToIds[_owner];
    }
}
