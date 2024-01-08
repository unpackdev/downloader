//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./NftBase.sol";
import "./IHub.sol";
import "./Registry.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract OpenNFT is  NftBase, Ownable {
    using SafeMath for uint256;
    // -----------------------------------------------------------------------
    // STATE
    // -----------------------------------------------------------------------

    // Storage for the registry
    Registry internal registryInstance_;

    // Storage for minter role
    struct Minter {
        bool isMinter; // Is this address a minter
        bool isActive; // Is this address an active minter
        bool isDuplicateBatchMinter; // Is this address able to batch mint duplicates
    }
    // Storage for minters
    mapping(address => Minter) internal minters_;

    // -----------------------------------------------------------------------
    // EVENTS
    // -----------------------------------------------------------------------

    event MinterUpdated(
        address minter,
        bool isDuplicateMinter,
        bool isMinter,
        bool isActiveMinter,
        string userIdentifier
    );

    event NewTokensMinted(
        uint256[] tokenIDs, // ID(s) of token(s).
        uint256 batchID, // ID of batch. 0 if not batch
        address indexed creator, // Address of the royalties receiver
        address indexed minter, // Address that minted the tokens
        address indexed receiver, // Address receiving token(s)
        string identifier, // Content ID within the location
        string location, // Where it is stored i.e IPFS, Arweave
        string contentHash // Checksum hash of the content
    );

    event NewTokenMinted(
        // uint256 batchTokenID == 0
        uint256 tokenID,
        address indexed minter,
        address indexed creator,
        address indexed receiver
    );

    event NewBatchTokenMint(
        // uint256 batchTokenID
        uint256[] tokenIDs,
        address indexed minter,
        address indexed creator,
        address indexed receiver
    );

    // -----------------------------------------------------------------------
    // MODIFIERS
    // -----------------------------------------------------------------------

    modifier onlyMinter() {
        require(
            minters_[msg.sender].isMinter && minters_[msg.sender].isActive,
            "Not active minter"
        );
        _;
    }

    modifier onlyBatchDuplicateMinter() {
        require(
            minters_[msg.sender].isDuplicateBatchMinter,
            "Not active batch copy minter"
        );
        _;
    }

    modifier onlyAuctions() {
        IHub auctionHubInstance_ = IHub(registryInstance_.getHub());

        uint256 auctionID = auctionHubInstance_.getAuctionID(msg.sender);
        require(
            msg.sender == address(auctionHubInstance_) ||
                auctionHubInstance_.isAuctionActive(auctionID),
            "NFT: Not hub or auction"
        );
        _;
    }

    // -----------------------------------------------------------------------
    // CONSTRUCTOR
    // -----------------------------------------------------------------------

    constructor(string memory name,
        string memory symbol) NftBase(name, symbol) Ownable() {

        }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    /**
     * @param   _minter Address of the minter being checked
     * @return  isMinter If the minter has the minter role
     * @return  isActiveMinter If the minter is an active minter
     */
    function isMinter(address _minter)
        external
        view
        returns (bool isMinter, bool isActiveMinter)
    {
        isMinter = minters_[_minter].isMinter;
        isActiveMinter = minters_[_minter].isActive;
    }

    function isActive() external view returns (bool) {
        return true;
    }

    function isTokenBatch(uint256 _tokenID) external view returns (uint256) {
        return isBatchToken_[_tokenID];
    }

    function getBatchInfo(uint256 _batchID)
        external
        view
        returns (
            uint256 baseTokenID,
            uint256[] memory tokenIDs,
            bool limitedStock,
            uint256 totalMinted
        )
    {
        baseTokenID = batchTokens_[_batchID].baseToken;
        tokenIDs = batchTokens_[_batchID].tokenIDs;
        limitedStock = batchTokens_[_batchID].limitedStock;
        totalMinted = batchTokens_[_batchID].totalMinted;
    }

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
    function transfer(address _to, uint256 _tokenID) external {
        _transfer(_to, _tokenID);
    }

    /**
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if the
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function batchTransfer(address _to, uint256[] memory _tokenIDs)
        external
        onlyAuctions()
    {
        _batchTransfer(_to, _tokenIDs);
    }

    /**
     * @param   from Address being transferee from
     * @param   to Address to transfer to
     * @param   tokenId ID of token being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if
     *          _from is _to address.
     */
    function transferFrom(
        address from, address to, uint256 tokenId
    ) public override {
        _transferFrom(from, to, tokenId);
    }

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
    ) external onlyAuctions() {
        _batchTransferFrom(_from, _to, _tokenIDs);
    }

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
        string calldata contentHash
    ) external onlyMinter() returns (uint256) {
        require(_isValidCreator(_tokenCreator), "NFT: Invalid creator");
        // Minting token
        uint256 tokenID = _mint(_mintTo, _tokenCreator, location);
        // Creating temp array for token ID
        uint256[] memory tempTokenIDs = new uint256[](1);
        tempTokenIDs[0] = tokenID;
        {
            // Emitting event
            emit NewTokensMinted(
                tempTokenIDs,
                0,
                _tokenCreator,
                msg.sender,
                _mintTo,
                identifier,
                location,
                contentHash
            );
        }

        return tokenID;
    }

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
    ) external onlyBatchDuplicateMinter() returns (uint256[] memory) {
        require(
            tokens_[_baseTokenID].creator != address(0),
            "Mint token before batch"
        );
        uint256 originalBatchID = isBatchToken_[_baseTokenID];
        uint256 batch;
        // Minting tokens
        uint256[] memory tokenIDs;
        (tokenIDs, batch) = _batchMint(
            _mintTo,
            tokens_[_baseTokenID].creator,
            _amount,
            _baseTokenID,
            originalBatchID
        );

        // If this is the first batch mint of the base token
        if (originalBatchID == 0) {
            // Storing batch against base token
            isBatchToken_[_baseTokenID] = batch;
            // Storing all info as a new object
            batchTokens_[batch] = BatchTokens(
                _baseTokenID,
                tokenIDs,
                _isLimitedStock,
                _amount
            );
        } else {
            batch = isBatchToken_[_baseTokenID];
            batchTokens_[batch].totalMinted += _amount;
        }
        // Wrapping for the stack
        {
            // Emitting event
            emit NewTokensMinted(
                tokenIDs,
                batch,
                tokens_[_baseTokenID].creator,
                msg.sender,
                _mintTo,
                "",
                "",
                ""
            );
        }
        return tokenIDs;
    }

    // -----------------------------------------------------------------------
    // ONLY OWNER STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _minter Address of the minter
     * @param   _hasMinterPermissions If the address has minter permissions. If
     *          false user will not be able to mint, nor will they be able to be
     *          set as the creator of a token
     * @param   _isActiveMinter If the minter is an active minter. If they do
     *          not have minter permissions they will not be able to be assigned
     *          as the creator of a token
     */
    function updateMinter(
        address _minter,
        bool _hasMinterPermissions,
        bool _isActiveMinter,
        string calldata _userIdentifier
    ) external onlyOwner() {
        minters_[_minter].isMinter = _hasMinterPermissions;
        minters_[_minter].isActive = _isActiveMinter;

        emit MinterUpdated(
            _minter,
            false,
            _hasMinterPermissions,
            _isActiveMinter,
            _userIdentifier
        );
    }

    function setDuplicateMinter(address _minter, bool _isDuplicateMinter)
        external
        onlyOwner()
    {
        minters_[_minter].isDuplicateBatchMinter = _isDuplicateMinter;
        minters_[_minter].isMinter = _isDuplicateMinter;
        minters_[_minter].isActive = _isDuplicateMinter;

        emit MinterUpdated(
            _minter,
            _isDuplicateMinter,
            _isDuplicateMinter,
            _isDuplicateMinter,
            "Auction"
        );
    }

    function setRegistry(address _registry) external onlyOwner() {
        require(_registry != address(0), "NFT: cannot set REG to 0x");
        require(
            address(registryInstance_) != _registry,
            "NFT: Cannot set REG to existing"
        );
        registryInstance_ = Registry(_registry);
        require(registryInstance_.isActive(), "NFT: REG instance invalid");
    }

    fallback() external payable {
        revert();
    }

    // -----------------------------------------------------------------------
    // INTERNAL STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _creator Address to check
     * @return  bool If the address to check is a valid creator
     * @notice  Will return true if the user is a minter, or is an active minter
     */
    function _isValidCreator(address _creator) internal view returns (bool) {
        if (minters_[_creator].isMinter) {
            return true;
        } else if (minters_[_creator].isMinter && minters_[_creator].isActive) {
            return true;
        }
        return false;
    }
}
