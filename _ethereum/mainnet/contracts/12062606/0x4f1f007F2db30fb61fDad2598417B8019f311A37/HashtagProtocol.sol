// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC721Token.sol";
import "./IERC721Receiver.sol";

import "./HashtagAccessControls.sol";

import "./ERC165.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Context.sol";

/**
 * @title Hashtag Protocol contract
 * @notice Core smart contract of the protocol that governs the creation of hashtag tokens
 * @author Hashtag Protocol
*/
contract HashtagProtocol is IERC721Token, ERC165, Context {
    using SafeMath for uint256;

    event MintHashtag(
        uint256 indexed tokenId,
        string displayHashtag,
        address indexed publisher,
        address creator
    );

    event HashtagReset(
        uint256 indexed tokenId,
        address indexed owner
    );

    event HashtagRenewed(
        uint256 indexed tokenId,
        address indexed caller
    );

    event OwnershipTermLengthUpdated(
        uint256 originalOwnershipLength,
        uint256 updatedOwnershipLength
    );

    event RenewalPeriodUpdated(
        uint256 originalRenewalPeriod,
        uint256 updatedRenewalPeriod
    );

    // @notice ERC165 interface for ERC721
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    // @notice ERC165 interface for ERC721 Metadata
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /// @notice Token name
    string public name = "Hashtag Protocol";

    /// @notice Token symbol
    string public symbol = "HASHTAG";

    /// @notice minimum time in seconds that a hashtag is owned
    uint256 public ownershipTermLength = 730 days;

    // @notice Function selector for ERC721Receiver.onERC721Received
    // 0x150b7a02
    bytes4 constant internal ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    // @notice Mapping of tokenId => owner
    mapping(uint256 => address) internal owners;

    // @notice Mapping of tokenId => approved address
    mapping(uint256 => address) internal approvals;

    // @notice Mapping of owner => number of tokens owned
    mapping(address => uint256) internal balances;

    // @notice Mapping of owner => operator => approved
    mapping(address => mapping(address => bool)) internal operatorApprovals;

    /// @notice baseURI for looking up up tokenURI for a token
    string public baseURI = "https://api.hashtag-protocol.io/";

    /// @notice Definition of a Hashtag which bundles associated metadata
    struct Hashtag {
        address originalPublisher;
        address creator;
        string displayVersion;
    }

    /// @notice current tip of the hashtag tokens (and total supply) as minted consecutively
    uint256 public tokenPointer;

    /// @notice lookup of Hashtag info from token ID
    mapping(uint256 => Hashtag) public tokenIdToHashtag;

    /// @notice lookup of (lowercase) Hashtag string to token ID
    mapping(string => uint256) public hashtagToTokenId;

    /// @notice Last time a token was interacted with
    mapping(uint256 => uint256) public tokenIdToLastTransferTime;

    /// @notice core Hashtag protocol account
    address payable public platform;

    /// @notice minimum hashtag length
    uint256 constant public hashtagMinStringLength = 3;

    /// @notice maximum hashtag length
    uint256 public hashtagMaxStringLength = 32;

    /// @notice access controls smart contract
    HashtagAccessControls public accessControls;

    /**
     * @notice Admin only execution guard
     * @dev When applied to a method, only allows execution when the sender has the admin role
    */
    modifier onlyAdmin() {
        require(accessControls.isAdmin(_msgSender()), "Caller must be admin");
        _;
    }

    /**
      * @notice Constructs the smart contract with access controls and platform address
      * @param _accessControls core contract for managing access and roles
      * @param _platform address of the Hashtag protocol core account
     */
    constructor (HashtagAccessControls _accessControls, address payable _platform) public {
        accessControls = _accessControls;
        platform = _platform;

        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }


    /**
     * @notice Admin method for updating the base token URI of a hashtag
     * @param _baseURI Base URI for all tokens
    */
    function setBaseURI(string memory _baseURI) onlyAdmin public {
        baseURI = _baseURI;
    }

    /**
     * @notice Admin method for updating the max string length of a hashtag
     * @param _hashtagMaxStringLength max length
    */
    function setHashtagMaxStringLength(uint256 _hashtagMaxStringLength) onlyAdmin public {
        hashtagMaxStringLength = _hashtagMaxStringLength;
    }

    /**
     * @notice Admin method for updating the ownership length for all hashtag tokens i.e. a global param
     * @param _ownershipTermLength New length in unix epoch seconds
    */
    function setOwnershipTermLength(uint256 _ownershipTermLength) onlyAdmin public {
        emit OwnershipTermLengthUpdated(ownershipTermLength, _ownershipTermLength);
        ownershipTermLength = _ownershipTermLength;
    }

    /**
     * @notice Method that a publisher can call to create a hashtag
     * @param _hashtag String version of the hashtag to mint
     * @param _publisher Address of the publisher through which the hashtag is being created
     * @param _creator Address of the account to be attributed with creation
     * @return _tokenId ID of the new hashtag
    */
    function mint(string calldata _hashtag, address payable _publisher, address _creator) payable external returns (uint256 _tokenId) {
        require(accessControls.isPublisher(_publisher), "Mint: The publisher must be whitelisted");

        // Perform basic hashtag validation
        string memory lowerHashtagToMint = _assertHashtagIsValid(_hashtag);

        // generate the new hashtag token id
        tokenPointer = tokenPointer.add(1);
        uint256 tokenId = tokenPointer;

        // create the hashtag
        tokenIdToHashtag[tokenId] = Hashtag({
        displayVersion : _hashtag,
        originalPublisher : _publisher,
        creator : _creator
        });

        // store a reverse lookup and mint the tag
        hashtagToTokenId[lowerHashtagToMint] = tokenId;

        // Minting events
        emit Transfer(address(0), platform, tokenId);
        emit MintHashtag(tokenId, _hashtag, _publisher, _creator);

        return tokenId;
    }

    /**
     * @notice Admin functionality for updating the address that receives the commission on behalf of the platform
     * @param _platform Address that receives minted NFTs
    */
    function setPlatform(address payable _platform) onlyAdmin external {
        platform = _platform;
    }

    /**
     * @notice Returns the commission addresses related to a token
     * @param _tokenId ID of a hashtag
     * @return _platform Platform commission address
     * @return _owner Address of the owner of the hashtag
    */
    function getPaymentAddresses(uint256 _tokenId) public view returns (
        address payable _platform,
        address payable _owner
    ) {
        return (
        platform,
        payable(ownerOf(_tokenId))
        );
    }

    /**
     * @notice Admin functionality for updating the access controls
     * @param _accessControls Address of the access controls contract
    */
    function updateAccessControls(HashtagAccessControls _accessControls) onlyAdmin external {
        require(address(_accessControls) != address(0), "HashtagProtocol.updateAccessControls: Cannot be zero");
        accessControls = _accessControls;
    }

    /**
     * @notice Returns creator of a token
     * @param _tokenId ID of a hashtag
     * @return _creator creator of the hashtag
    */
    function getCreatorAddress(uint256 _tokenId) public view returns (address _creator) {
        return tokenIdToHashtag[_tokenId].creator;
    }

    /**
     * @notice Existence check on a token
     * @param _tokenId token ID
     * @return true if exists
    */
    function exists(uint256 _tokenId) public view returns (bool) {
        return tokenIdToHashtag[_tokenId].creator != address(0);
    }

    /**
     * @notice token URI for a token
     * @param _tokenId token ID
     * @return token URI of the token, if exists
    */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(tokenIdToHashtag[_tokenId].creator != address(0), "Token ID must exist");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///      operator, or the approved address for this NFT. Throws if `_from` is
    ///      not the current owner. Throws if `_to` is the zero address. Throws if
    ///      `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///      checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///      `onERC721Received` on `_to` and throws if the return value is not
    ///      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    )
    override
    external
    {
        transferFrom(
            _from,
            _to,
            _tokenId
        );

        uint256 receiverCodeSize;
        assembly {
            receiverCodeSize := extcodesize(_to)
        }
        if (receiverCodeSize > 0) {
            bytes4 selector = IERC721Receiver(_to).onERC721Received(
                _msgSender(),
                _from,
                _tokenId,
                _data
            );
            require(
                selector == ERC721_RECEIVED,
                "ERC721_INVALID_SELECTOR"
            );
        }
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///      except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    override
    external
    {
        transferFrom(
            _from,
            _to,
            _tokenId
        );

        uint256 receiverCodeSize;
        assembly {
            receiverCodeSize := extcodesize(_to)
        }
        if (receiverCodeSize > 0) {
            bytes4 selector = IERC721Receiver(_to).onERC721Received(
                _msgSender(),
                _from,
                _tokenId,
                ""
            );
            require(
                selector == ERC721_RECEIVED,
                "ERC721_INVALID_SELECTOR"
            );
        }
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///      Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///      operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId)
    override
    external
    {
        address owner = ownerOf(_tokenId);
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721_INVALID_SENDER"
        );

        approvals[_tokenId] = _approved;
        emit Approval(
            owner,
            _approved,
            _tokenId
        );
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///         all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///      multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved)
    override
    external
    {
        operatorApprovals[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(
            _msgSender(),
            _operator,
            _approved
        );
    }

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///      function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner)
    override
    external
    view
    returns (uint256)
    {
        require(
            _owner != address(0),
            "ERC721_ZERO_OWNER"
        );
        return balances[_owner];
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///         TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///         THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///      operator, or the approved address for this NFT. Throws if `_from` is
    ///      not the current owner. Throws if `_to` is the zero address. Throws if
    ///      `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    override
    public
    {
        require(
            _to != address(0),
            "ERC721_ZERO_TO_ADDRESS"
        );

        require(
            _to != platform,
            "ERC721_CANNOT_TRANSFER_TO_PLATFORM"
        );

        address owner = ownerOf(_tokenId);
        require(
            _from == owner,
            "ERC721_OWNER_MISMATCH"
        );

        address spender = _msgSender();
        address approvedAddress = getApproved(_tokenId);

        if (owner == platform) {
            require(
                spender == owner ||
                accessControls.isSmartContract(spender) ||
                isApprovedForAll(owner, spender) ||
                approvedAddress == spender,
                "ERC721_INVALID_SPENDER"
            );
        } else {
            require(
                spender == owner ||
                isApprovedForAll(owner, spender) ||
                approvedAddress == spender,
                "ERC721_INVALID_SPENDER"
            );
        }

        _transferFrom(_tokenId, approvedAddress, _to, _from);
    }

    /// @notice Renews a hash tag by setting its last transfer time to be now
    /// @dev Can only be called by token owner
    /// @param _tokenId The identifier for an NFT
    function renewHashtag(uint256 _tokenId) external {
        require(_msgSender() == ownerOf(_tokenId), "renewHashtag: Invalid sender");

        tokenIdToLastTransferTime[_tokenId] = block.timestamp;

        emit HashtagRenewed(_tokenId, _msgSender());
    }

    /// @notice Recycling a hashtag i.e. transferring ownership back to the platform due to stale ownership
    /// @dev Token must exist, be not already be owned by platform and time of TX must be greater than lastTransferTime
    /// @param _tokenId The identifier for the hashtag being recycled
    function recycleHashtag(uint256 _tokenId) external {
        require(exists(_tokenId), "recycleHashtag: Invalid token ID");
        require(ownerOf(_tokenId) != platform, "recycleHashtag: Already owned by the platform");

        uint256 lastTransferTime = tokenIdToLastTransferTime[_tokenId];
        require(
            lastTransferTime.add(ownershipTermLength) < block.timestamp,
            "recycleHashtag: Token not eligible for recycling yet"
        );

        _transferFrom(_tokenId, getApproved(_tokenId), platform, ownerOf(_tokenId));

        emit HashtagReset(_tokenId, _msgSender());
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///      about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId)
    override
    public
    view
    returns (address)
    {
        address owner = owners[_tokenId];
        if (owner == address(0) && tokenIdToHashtag[_tokenId].creator != address(0)) {
            return platform;
        }

        require(owner != address(0), "ERC721_ZERO_OWNER");
        return owner;
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId)
    override
    public
    view
    returns (address)
    {
        return approvals[_tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator)
    override
    public
    view
    returns (bool)
    {
        return operatorApprovals[_owner][_operator];
    }

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @notice Private method used for validating a hashtag before minting
     * @dev A series of assertions are performed reverting the transaction for any validation violations
     * @param _hashtag Proposed hashtag string
    */
    function _assertHashtagIsValid(string memory _hashtag) private view returns (string memory) {
        bytes memory hashtagStringBytes = bytes(_hashtag);
        require(
            hashtagStringBytes.length >= hashtagMinStringLength && hashtagStringBytes.length <= hashtagMaxStringLength,
            "Invalid format: Hashtag must not exceed length requirements"
        );

        require(hashtagStringBytes[0] == 0x23, "Must start with #");

        string memory hashtagKey = _lower(_hashtag);
        require(hashtagToTokenId[hashtagKey] == 0, "Hashtag validation: Hashtag already owned.");

        uint256 alphabetCharCount = 0;
        // start from first char after #
        for (uint256 i = 1; i < hashtagStringBytes.length; i++) {
            bytes1 char = hashtagStringBytes[i];

            // Generally ensure that the character is alpha numeric
            bool isInvalidCharacter = !(char >= 0x30 && char <= 0x39) && //0-9
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A);
            //a-z

            require(!isInvalidCharacter, "Invalid character found: Hashtag may only contain characters A-Z, a-z, 0-9 and #");

            // Should the char be alphabetic, increment alphabetCharCount
            if ((char >= 0x41 && char <= 0x5A) || (char >= 0x61 && char <= 0x7A)) {
                alphabetCharCount = alphabetCharCount.add(1);
            }
        }

        // Ensure alphabetCharCount is at least 1
        require(alphabetCharCount >= 1, "Invalid format: Hashtag must contain at least 1 alphabetic character.");

        return hashtagKey;
    }

    /**
     * @notice Converts a string to its lowercase equivalent
     * @param _base String to convert
     * @return string Lowercase version of string supplied
    */
    function _lower(string memory _base) private pure returns (string memory) {
        bytes memory bStr = bytes(_base);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    /// @notice Internal method for handling token transfer flow, has special case handling for platform transfers as
    ///         to not change its balance which is always set to zero by design
    /// @param _tokenId The identifier for an NFT
    /// @param _approvedAddress The approval address, can set set to zero address
    /// @param _to Who will be receiving the token after transfer
    /// @param _from Who is transferring the token
    function _transferFrom(uint256 _tokenId, address _approvedAddress, address _to, address _from) private {
        if (_approvedAddress != address(0)) {
            approvals[_tokenId] = address(0);
        }

        owners[_tokenId] = _to;

        if (_from != platform) {
            balances[_from] = balances[_from].sub(1);
        }

        // Ensure last transfer time is set to now
        tokenIdToLastTransferTime[_tokenId] = block.timestamp;

        if (_to != platform) {
            balances[_to] = balances[_to].add(1);
        }

        emit Transfer(
            _from,
            _to,
            _tokenId
        );
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
    private returns (bool)
    {
        if (!isContract(to)) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                _msgSender(),
                from,
                tokenId,
                _data
            ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == ERC721_RECEIVED);
        }
    }
}
