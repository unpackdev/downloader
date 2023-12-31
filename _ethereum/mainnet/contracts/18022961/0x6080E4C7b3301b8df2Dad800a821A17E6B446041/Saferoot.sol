// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./ErrorReporter.sol";
import "./SaferootDefinitions.sol";

/**
 * @title Saferoot Contract
 * @author Staging Labs
 * @notice This contract is implemented using the Minimal Proxy/Clone pattern for the purpose
 * of gas deployment cost savings. This contract is deployed by SaferootFactory.sol
 */
contract Saferoot is
    ErrorReporter,
    AccessControl,
    Initializable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using Address for address;

    /************************************ Variables ************************************/

    /// @notice role hash for a user
    bytes32 public immutable USER_ROLE = keccak256("USER_ROLE");
    /// @notice role hash for the service account
    bytes32 public immutable SERVICE_ROLE = keccak256("SERVICE_ROLE");
    /// @notice counter to keep track of how many safeguards there are
    uint256 public currentSafeguardKey;

    struct Addresses {
        /// @notice user address
        address user;
        /// @notice backup wallet address
        address backup;
        /// @notice service account address
        address service;
    }
    Addresses public addresses;

    /// @notice mapping a unique ERC-721 / ERC-1155 key to its safeguard tokenID
    mapping(bytes32 => uint256) public keyToTokenIDMapping;

    /*********************************** Modifier **************************************/

    /// @notice modifier for ensuring the caller has the user role
    modifier onlyUser() {
        if (!hasRole(USER_ROLE, msg.sender)) {
            revert NotUser(msg.sender);
        }
        _;
    }

    /// @notice modifier for ensuring the caller has the service role
    modifier onlyService() {
        if (!hasRole(SERVICE_ROLE, msg.sender)) {
            revert NotService(msg.sender);
        }
        _;
    }

    /*********************************** Events ****************************************/

    event BackupUpdated(address indexed walletAddress);
    event SafeguardInitiated(bytes32 key);
    event TransferSkip(bytes32 key, uint256 indexed tokenType);
    event ERC20SafeguardAdded(bytes32 key);
    event ERC721SafeguardAdded(bytes32 key);
    event ERC1155SafeguardAdded(bytes32 key);

    /******************************* Constructor **********************************/

    /**
     * @notice Constructor function for the Saferoot contract
     * @dev This contract is deployed by SaferootFactory.sol
     * @dev This contract is implemented using the Minimal Proxy/Clone pattern for the purpose
     * of gas deployment cost savings. This contract is deployed by SaferootFactory.sol
     */
    constructor() {
        _disableInitializers();
    }

    /**
        @notice Initializer function for proxy deployment
        @param _service address of the token
        @param _user type of transfer
        @param _backup backup wallet
    */
    function initialize(
        address _service,
        address _user,
        address _backup
    ) public initializer {
        if (_service == address(0) || _user == address(0) || _backup == address(0)) {
            revert ZeroAddress();
        }
        addresses.user = _user;
        addresses.backup = _backup;
        addresses.service = _service;
        _grantRole(SERVICE_ROLE, _service);
        _grantRole(USER_ROLE, _user);
    }

    /**
        @notice Initializer function for proxy deployment + adding safeguards
        @param _service address of the token
        @param _user type of transfer
        @param _backup backup wallet
    */
    function initializeAndAddSafeguard(
        address _service,
        address _user,
        address _backup,
        SafeguardEntry[] calldata _ercEntries
    ) public initializer {
        if (_service == address(0) || _user == address(0) || _backup == address(0)) {
            revert ZeroAddress();
        }
        addresses.user = _user;
        addresses.backup = _backup;
        addresses.service = _service;
        _grantRole(SERVICE_ROLE, _service);
        _grantRole(USER_ROLE, _user);
        initializeAddSafeguard(_ercEntries);
    }

    /** 
        @notice Initializer function for adding new safeguards for ERC20, ERC721, and ERC1155 tokens
        @param _ercEntries the safeguard entries to add
    */
    function initializeAddSafeguard(SafeguardEntry[] calldata _ercEntries)
        private
    {
        uint256 currentKey = currentSafeguardKey;
        uint256 ercEntriesLength = _ercEntries.length;
        for (uint256 index; index < ercEntriesLength;) {
            SafeguardEntry memory incomingSafeguard = _ercEntries[index];
            if (incomingSafeguard.contractAddress == address(0)) {
                revert ZeroAddress();
            }
            if (!incomingSafeguard.contractAddress.isContract()) {
                revert InvalidContractAddress();
            }

            if (incomingSafeguard.tokenType == TokenType_ERC20) {
                if (incomingSafeguard.tokenId != 0) {
                    revert InvalidTokenID();
                }
                emit ERC20SafeguardAdded(encodeKey(incomingSafeguard.contractAddress, incomingSafeguard.tokenType, 0));
            } else if (incomingSafeguard.tokenType == TokenType_ERC721) {
                bytes32 key = encodeKey(incomingSafeguard.contractAddress, incomingSafeguard.tokenType, currentKey);
                keyToTokenIDMapping[key] = incomingSafeguard.tokenId;
                unchecked { ++currentKey; }
                emit ERC721SafeguardAdded(key);
            } else if (incomingSafeguard.tokenType == TokenType_ERC1155) {
                bytes32 key = encodeKey(incomingSafeguard.contractAddress, incomingSafeguard.tokenType, currentKey);
                keyToTokenIDMapping[key] = incomingSafeguard.tokenId;
                unchecked { ++currentKey; }
                emit ERC1155SafeguardAdded(key);
            } else {
                revert InvalidTokenType();
            }
            // Increment the index without deep checks
            unchecked { ++index; }
        }

        if (currentKey != currentSafeguardKey) {
            currentSafeguardKey = currentKey;
        }
    }

    /******************************* Service Functions **********************************/

    /** 
        @notice Internal method to calculate a transfer of an ERC20
        @param _key the unique identifier of the safeguard
        @param _contractAddress address of the token
    */
    function _transfer20(
        bytes32 _key,
        address _contractAddress
    ) internal returns (bool) {
        uint256 allowance = IERC20(_contractAddress).allowance(
            addresses.user,
            address(this)
        );
        uint256 balance = IERC20(_contractAddress).balanceOf(addresses.user);

        // If the balance or allowance is 0, then skip
        if (balance == 0 || allowance == 0) {
            emit TransferSkip(_key, TokenType_ERC20);
            return false;
        }

        // Calculate the amount to transfer
        uint256 transferAmount = (allowance < balance) ? allowance : balance;
        IERC20(_contractAddress).safeTransferFrom(addresses.user, addresses.backup, transferAmount);

        return true;
    }

    /** 
        @notice Internal method to calculate a transfer of an ERC721
        @param _key the unique identifier of the safeguard
        @param _contractAddress address of the token
        @param _tokenId id of the ERC721
    */
    function _transfer721(
        bytes32 _key,
        address _contractAddress,
        uint256 _tokenId
    ) internal returns (bool) {
        IERC721 token = IERC721(_contractAddress);
        address owner = token.ownerOf(_tokenId);
        if (
            (token.getApproved(_tokenId) != address(this) &&
                !token.isApprovedForAll(owner, address(this))) || owner != addresses.user
        ) {
            emit TransferSkip(_key, TokenType_ERC721);
            return false;
        }
        token.safeTransferFrom(addresses.user, addresses.backup, _tokenId);

        return true;
    }

    /** 
        @notice Internal method to calculate a transfer of an ERC1155
        @param _key the unique identifier of the safeguard
        @param _contractAddress address of the token
        @param _tokenId id of the ERC1155
    */
    function _transfer1155(
        bytes32 _key,
        address _contractAddress,
        uint256 _tokenId
    ) internal returns (bool) {
        // Check if the user owns tokens
        uint256 amount = IERC1155(_contractAddress).balanceOf(addresses.user, _tokenId);

        // Check if the contract is approved to manage user's tokens
        if (
            !IERC1155(_contractAddress).isApprovedForAll(addresses.user, address(this)) ||
            amount == 0
        ) {
            emit TransferSkip(_key, TokenType_ERC1155);
            return false;
        }

        IERC1155(_contractAddress).safeTransferFrom(
            addresses.user,
            addresses.backup,
            _tokenId,
            amount,
            ""
        );

        return true;
    }

    /** 
        @notice Initiating a safeguard
        @param _safeguardKeys the unique identifiers of the tokens to be safeguarded
    */
    function initiateSafeguard(bytes32[] calldata _safeguardKeys)
        external
        onlyService
        nonReentrant
    {
        uint256 safeguardKeysLength = _safeguardKeys.length;
        for (uint256 index; index < safeguardKeysLength;) {
            bytes32 key = _safeguardKeys[index];
            address contractAddress = decodeKeyAddress(key);
            uint256 tokenType = decodeKeyTokenType(key);

            // Increment the index without deep checks before the continue check
            unchecked { ++index; }

            if (contractAddress == address(0) || !contractAddress.isContract() ) {
                continue;
            }

            if (tokenType == TokenType_ERC20) {
                // Transfer token
                if (_transfer20(key, contractAddress)) {
                    emit SafeguardInitiated(key);
                }
                // Move on to the next loop iteration immediately
                continue;
            } else if (tokenType == TokenType_ERC721) {
                // Transfer token
                 if (_transfer721(key, contractAddress, keyToTokenIDMapping[key])) {
                    emit SafeguardInitiated(key);
                }
                // Move on to the next loop iteration immediately
                continue;
            } else if (tokenType == TokenType_ERC1155) {
                // Transfer token
                if (
                    _transfer1155(
                        key,
                        contractAddress,
                        keyToTokenIDMapping[key]
                    )
                ) {
                    emit SafeguardInitiated(key);
                }
                // Move on to the next loop iteration immediately
                continue;
            }
        }
    }

    /******************************* User Functions **********************************/

    /** 
        @notice Adding new safeguards for ERC20, ERC721, and ERC1155 tokens
        @param _ercEntries the safeguard entries to add
    */
    function addSafeguard(SafeguardEntry[] calldata _ercEntries)
        external
        onlyUser
    {
        uint256 currentKey = currentSafeguardKey;
        uint256 ercEntriesLength = _ercEntries.length;
        for (uint256 index; index < ercEntriesLength;) {
            SafeguardEntry memory incomingSafeguard = _ercEntries[index];
            if (incomingSafeguard.contractAddress == address(0)) {
                revert ZeroAddress();
            }
            if (!incomingSafeguard.contractAddress.isContract()) {
                revert InvalidContractAddress();
            }

            if (incomingSafeguard.tokenType == TokenType_ERC20) {
                if (incomingSafeguard.tokenId != 0) {
                    revert InvalidTokenID();
                }
                emit ERC20SafeguardAdded(encodeKey(incomingSafeguard.contractAddress, incomingSafeguard.tokenType, 0));
            } else if (incomingSafeguard.tokenType == TokenType_ERC721) {
                bytes32 key = encodeKey(incomingSafeguard.contractAddress, incomingSafeguard.tokenType, currentKey);
                keyToTokenIDMapping[key] = incomingSafeguard.tokenId;
                unchecked { ++currentKey; }
                emit ERC721SafeguardAdded(key);
            } else if (incomingSafeguard.tokenType == TokenType_ERC1155) {
                bytes32 key = encodeKey(incomingSafeguard.contractAddress, incomingSafeguard.tokenType, currentKey);
                keyToTokenIDMapping[key] = incomingSafeguard.tokenId;
                unchecked { ++currentKey; }
                emit ERC1155SafeguardAdded(key);
            } else {
                revert InvalidTokenType();
            }
            // Increment the index without deep checks
            unchecked { ++index; }
        }

        if (currentKey != currentSafeguardKey) {
            currentSafeguardKey = currentKey;
        }
    }

    /** 
        @notice Setting a new backup wallet
        @param _backup address of the new backup wallet
    */
    function setBackupWallet(address _backup) external onlyUser {
        if (_backup == address(0)) {
            revert ZeroAddress();
        }
        addresses.backup = _backup;
        emit BackupUpdated(_backup);
    }

    /**
        @notice Withdraws all ERC20 tokens from the contract (safety feature)
        @param _tokenAddress address of the token
    */
    function withdrawERC20(address _tokenAddress) external onlyUser {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(addresses.user, balance), "Transfer failed");
    }

    /**
        @notice Withdraws all ERC721 tokens from the contract (safety feature)
        @param _tokenAddress address of the token
        @param tokenId id of the ERC721
    */
    function withdrawERC721(address _tokenAddress, uint256 tokenId) external onlyUser {
        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(tokenId) == address(this), "Token not owned by contract");
        token.safeTransferFrom(address(this), addresses.user, tokenId);
    }

    /******************************* View Functions **********************************/
    /// @notice Byte mask for the Ethereum address
    uint256 private constant MASK_160 = (1 << 160) - 1;
    /// @notice Byte mask for the counter
    uint256 private constant MASK_88 = (1 << 88) - 1;

    /**
        @notice Returns the encoded key
        @param _addr the Ethereum address
        @param _tokenType the type of token
        @param _counter the unique counter (must be less than 2^88)
    */
    function encodeKey(address _addr, uint8 _tokenType, uint256 _counter)
        public
        pure
        returns (bytes32)
    {
        require(_counter <= MASK_88, "Counter exceeds allowed value");
        return bytes32((uint256(uint8(_tokenType)) << 248) | (_counter << 160) | uint256(uint160(_addr)));
    }

    /**
        @notice Returns the token type of the ID
        @param _key the encoded key
    */
    function decodeKeyTokenType(bytes32 _key) public pure returns (uint256) {
        return uint256(_key) >> 248;
    }

    /**
        @notice Returns the counter from the key
        @param _key the encoded key
    */
    function decodeKeyCounter(bytes32 _key) public pure returns (uint256) {
        return (uint256(_key) >> 160) & MASK_88;
    }

    /**
        @notice Returns the Ethereum address from the key
        @param _key the encoded key
    */
    function decodeKeyAddress(bytes32 _key) public pure returns (address) {
        return address(uint160(uint256(_key) & MASK_160));
    }

}