// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC1155.sol";
import "./IERC721.sol";

import "./AccessControlUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";

// import "./console.sol";

contract HBBPortal is
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    event PortalActivated(
        address indexed owner,
        uint256 indexed tokenId,
        address indexed contractAddress,
        ContractType contractType
    );
    event PortalDeactivated(
        address indexed owner,
        uint256 indexed tokenId,
        address indexed contractAddress,
        ContractType contractType
    );
    event WhitelistUpdated(
        address indexed token,
        ContractType indexed contractTypeBefore,
        ContractType indexed contractTypeAfter
    );
    event TimeDelayUpdated(
        uint256 indexed timeDelayBefore,
        uint256 indexed timeDelayAfter
    );

    enum ContractType {
        NOTHING, // 0
        ERC721, // 1
        ERC1155 // 2
    }

    modifier timeDelayPassed() {
        require(
            block.timestamp - lastExecutionTime > execution_delay,
            "HBBPortal: Portal is recharging"
        );
        _;
    }

    uint256 lastExecutionTime;
    uint256 execution_delay;

    mapping(address => mapping(address => mapping(uint256 => bool)))
        public balances;

    mapping(address => ContractType) public whitelist;

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ERC1155Holder_init();
        __ERC721Holder_init();
        __ReentrancyGuard_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setTimeDelay(30 seconds);
    }

    /**
     * @notice Allows another token to use the Portal
     *
     * Requirements
     * - Only the default admin can call this function
     * - Must emit WhiteListUpdated event
     */
    function setWhitelist(address _tokenToWhitelist, ContractType _contractType)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ContractType contractTypeBefore = whitelist[_tokenToWhitelist];
        whitelist[_tokenToWhitelist] = _contractType;
        emit WhitelistUpdated(
            _tokenToWhitelist,
            contractTypeBefore,
            _contractType
        );
    }

    /**
     * @notice Sets the time delay between the last execution and the next one
     *
     * Requirements
     * - Only the default admin can call this function
     * - Must emit TimeDelayUpdated event
     */
    function setTimeDelay(uint256 _timeDelay)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 timeDelayBefore = execution_delay;
        execution_delay = _timeDelay;
        emit TimeDelayUpdated(timeDelayBefore, execution_delay);
    }

    /**
     * @notice Enables the caller to withdraw selected tokens from the portal
     *
     * Requirements
     * - Only one token can be withdrawn at a time
     * - Caller must own the token
     * - Time delay must be passed
     * - Token must be whitelisted
     * - Must emit PortalDeactivated event
     */
    function withdrawBatch(address token, uint256[] memory _ids)
        public
        nonReentrant
        timeDelayPassed
    {
        require(
            _ids.length == 1,
            "HBBPortal: Only one token can be withdrawn at a time"
        ); // Remove this line for batch withdraws
        if (whitelist[token] == ContractType.ERC721) {
            lastExecutionTime = block.timestamp;
            for (uint256 i = 0; i < _ids.length; i++) {
                require(
                    balances[token][msg.sender][_ids[i]],
                    "HBBPortal: You dont own this token"
                );
                balances[token][msg.sender][_ids[i]] = false;
                IERC721(token).safeTransferFrom(
                    address(this),
                    msg.sender,
                    _ids[i]
                );
                emit PortalDeactivated(
                    msg.sender,
                    _ids[i],
                    token,
                    whitelist[token]
                );
            }
        } else if (whitelist[token] == ContractType.ERC1155) {
            lastExecutionTime = block.timestamp;
            uint256[] memory _amounts = new uint256[](_ids.length);
            for (uint256 i = 0; i < _ids.length; i++) {
                require(
                    balances[token][msg.sender][_ids[i]],
                    "HBBPortal: You dont own this tokens"
                );
                balances[token][msg.sender][_ids[i]] = false;
                _amounts[i] = 1;
                emit PortalDeactivated(
                    msg.sender,
                    _ids[i],
                    token,
                    whitelist[token]
                );
            }
            IERC1155(token).safeBatchTransferFrom(
                address(this),
                msg.sender,
                _ids,
                _amounts,
                ""
            );
        } else {
            revert("HBBPortal: This contract is not whitelisted");
        }
    }

    /**
     * @notice Triggers portal events and state when an ERC721 is received
     *
     * Requirements
     * - Time delay must be passed
     * - Token must be whitelisted
     * - Must emit PortalActivated event
     */
    function onERC721Received(
        address from,
        address,
        uint256 tokenId,
        bytes memory
    ) public virtual override timeDelayPassed returns (bytes4) {
        require(
            whitelist[msg.sender] == ContractType.ERC721,
            "HBBPortal: You are not whitelisted to use this contract"
        );
        lastExecutionTime = block.timestamp;
        balances[msg.sender][from][tokenId] = true;
        emit PortalActivated(from, tokenId, msg.sender, whitelist[msg.sender]);
        return this.onERC721Received.selector;
    }

    /**
     * @notice Triggers portal events and state when an ERC1155 is received
     *
     * Requirements
     * - Time delay must be passed
     * - Token must be whitelisted
     * - Only one token can be received at a time
     * - You cant deposit two tokens with the same tokenID
     * - Must emit PortalActivated event
     */
    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 amount,
        bytes memory
    ) public virtual override timeDelayPassed returns (bytes4) {
        require(
            whitelist[msg.sender] == ContractType.ERC1155,
            "HBBPortal: You are not whitelisted to use this contract"
        );
        lastExecutionTime = block.timestamp;
        require(amount == 1, "HBBPortal: Amount must be 1");
        require(
            balances[msg.sender][from][id] == false,
            "HBBPortal: You already submitted this token"
        );
        balances[msg.sender][from][id] = true;
        emit PortalActivated(from, id, msg.sender, whitelist[msg.sender]);
        return this.onERC1155Received.selector;
    }

    /**
     * @notice Triggers portal events and state when an ERC1155 is received in batch
     *
     * Requirements
     * - Must not accept batch transfers
     */
    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] memory ids,
        uint256[] memory amount,
        bytes memory
    ) public virtual override timeDelayPassed returns (bytes4) {
        revert("HBBPortal: Batch ERC1155 transactions are not allowed");
        // require(
        //     whitelist[msg.sender] != ContractType.NOTHING,
        //     "HBBPortal: You are not whitelisted to use this contract"
        // );
        // lastExecutionTime = block.timestamp;
        // for (uint256 i = 0; i < ids.length; i++) {
        //     require(amount[i] == 1, "HBBPortal: Amount must be 1");
        //     require(balances[msg.sender][from][ids[i]] == false, "HBBPortal: You already submitted this token");
        //     balances[msg.sender][from][ids[i]] = true;
        //     emit PortalActivated(from, ids[i], msg.sender, whitelist[msg.sender]);
        // }
        // return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}
