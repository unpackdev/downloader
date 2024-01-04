// SPDX-License-Identifier: WTFPL
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

// Access Control
import "./AccessControl.sol";

// Libraries
import "./SafeMath.sol";

// Helpers
import "./ReentrancyGuard.sol";

contract LootCitadel is ReentrancyGuard, AccessControl {
    /***********************************|
    |   Libraries                       |
    |__________________________________*/
    using SafeMath for uint256;

    /***********************************|
    |   Constants                       |
    |__________________________________*/

    // Citadel Metadata
    string public name = "LootCitadel";
    string public version = "1.0.0";

    // Access Control
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    // Citadel Managment
    bool public CITADEL_INITIALIZED;
    uint256 public immutable EXPANSION_ENABLE_DELAY = 7 days;

    /**
     * @dev An array of proposed expansions core addresses.
     */
    address[] public expansionList;

    /**
     * @dev Expansion Configuration
     */
    struct Expansion {
        bool active;
        address core;
        address proxy;
        address token;
        uint256 balance;
        uint256 timestamp;
    }

    /**
     * @dev Mapping of the Citadel expansions.
     */
    mapping(address => Expansion) public expansions;

    /***********************************|
    |   Events                          |
    |__________________________________*/

    /**
     * @dev Expansion has executed an ERC20 reward action (alchemy) for specific token.
     */
    event Alchemy(address core, address user, address token, uint256 amount);

    /**
     * @dev Expansion has executed an ERC1155 reward action (alchemy) for specific token.
     */
    event AlchemyItem(
        address core,
        address user,
        address token,
        uint256 id,
        uint256 amount
    );

    /**
     * @dev A new expansion is proposed
     */
    event ExpansionProposed(
        address core,
        address proxy,
        address token,
        uint256 balance,
        string ipfs,
        uint256 timestamp
    );

    /**
     * @dev A expansion is enabled.
     */
    event ExpansionEnabled(address core);

    /**
     * @dev A expansion is paused.
     */
    event ExpansionPaused(address core);

    /**
     * @dev A expansion proxy is updated.
     */
    event ExpansionUpdated(address core, address proxy);

    /***********************************|
    |   Constructor                     |
    |__________________________________*/

    /**
     * @dev Initialize the LOOT Citadel
     */
    constructor() public {
        _setRoleAdmin(CONTROLLER_ROLE, CONTROLLER_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, CONTROLLER_ROLE);
        _setupRole(CONTROLLER_ROLE, msg.sender);
        _setupRole(PROPOSER_ROLE, msg.sender);
    }

    /***********************************|
    |   Expansion Administration        |
    |__________________________________*/

    /**
     * @dev The total number of proposed expansions.
     * @return expansionList array length
     */
    function getExpansionCount() public view returns (uint256) {
        return expansionList.length;
    }

    /**
     * @dev Return exansion data for smart contract reference
     * @param core The expansion core address
     */
    function getExpansion(address core)
        external
        view
        returns (Expansion memory expansion)
    {
        return expansions[core];
    }

    /**
     * @dev Propose a new Citadel expansion
     * @param core Core expansion logic
     * @param proxy Proxy to execute alchemy logic
     * @param token Token associated with expansion
     * @param balance Allocated token balance of the expansion
     * @param ipfs Reference to the expansion metadata
     */
    function proposeExpansion(
        address core,
        address proxy,
        address token,
        uint256 balance,
        string calldata ipfs
    ) external returns (bool) {
        require(hasRole(PROPOSER_ROLE, msg.sender));

        // Verify Expansion Is New
        require(expansions[core].core == address(0), "Expansion Exists");

        // Add expansion to list.
        expansionList.push(core);

        // Create Expansion Struct
        expansions[core] = Expansion({
            active: false,
            core: core,
            proxy: proxy,
            token: token,
            balance: balance,
            timestamp: block.timestamp
        });

        // Emit ExpansionProposed
        emit ExpansionProposed(
            core,
            proxy,
            token,
            balance,
            ipfs,
            block.timestamp
        );

        return true;
    }

    /**
     * @dev Enable Citadel Expansion
     * @param _core Expansion Address
     */
    function enableExpansion(address _core) external returns (bool) {
        // Required the controller role.
        require(hasRole(CONTROLLER_ROLE, msg.sender));

        // Load Expansion Struct
        Expansion storage expansion = expansions[_core];

        // Verify Expansion Exists
        require(expansions[_core].core != address(0), "Expansion Non-Existent");

        // Expansion Currently Paused
        require(expansion.active == false, "Expansion Enabled");

        // Check Citadel Initialized Status
        if (CITADEL_INITIALIZED) {
            // Delay Requirements Satisfied
            require(
                expansion.timestamp.add(EXPANSION_ENABLE_DELAY) <=
                    block.timestamp
            );
        }

        // Enable Expansion
        expansion.active = true;

        // Emit Expansion Enabled
        emit ExpansionEnabled(_core);

        return true;
    }

    /**
     * @dev Pause Citadel Expansion
     * @param _core Expansion Address
     */
    function pauseExpansion(address _core) external returns (bool) {
        // Controller Role Required
        require(hasRole(CONTROLLER_ROLE, msg.sender));

        // Load Expansion Struct
        Expansion storage expansion = expansions[_core];

        // Expansion Currently Enabled
        require(expansion.active == true);

        // Pause Expansion
        expansion.active = false;

        // Emit ExpansionPaused
        emit ExpansionPaused(_core);

        return true;
    }

    /**
     * @dev Update Citadel Expansion proxy to change alchemy logic
     * @param _expansion Expansion Address
     */
    function updateExpansionProxy(address _expansion, address _proxy)
        external
        returns (bool)
    {
        // Controller Role Required
        require(hasRole(CONTROLLER_ROLE, msg.sender));

        // Load Expansion Struct
        Expansion storage expansion = expansions[_expansion];

        // New Proxy
        require(expansion.proxy != _proxy);

        // Save Proxy to Expansion Struct
        expansion.proxy = _proxy;

        // Emit ExpansionUpdated
        emit ExpansionUpdated(_expansion, _proxy);

        return true;
    }

    /**
     * @dev Retrieve current expansion balance.
     * @param core Core expansion smart contract.
     * @return current expansion balance
     */
    function expansionBalance(address core) external view returns (uint256) {
        return expansions[core].balance;
    }

    /***********************************|
    |   Alchemy                         |
    |__________________________________*/
    /**
     * @dev Call expansion ERC20 proxy to issue rewards.
     * @param to Receiver of rewards
     * @param amount Amount of rewards
     */
    function alchemy(address to, uint256 amount)
        external
        nonReentrant
        returns (bool)
    {
        // Load Expansion Struct from Message Sender
        Expansion storage expansion = expansions[msg.sender];

        // Expansion Unavailable
        require(expansion.core != address(0), "Citadal: Expansion Unavailable");

        // Expansion Active
        require(expansion.active == true, "Citadal: Expansion Paused");

        // Check Amount is Valid
        require(expansion.balance.sub(amount) >= 0);

        // Update Remaining Balance
        expansion.balance = expansion.balance.sub(amount);

        // ERC20 Alchemy Logic
        (bool success, ) =
            expansion.proxy.delegatecall(
                abi.encodeWithSignature(
                    "alchemy(address,address,uint256)",
                    expansion.token,
                    to,
                    amount
                )
            );

        // Alchemy Success
        require(success == true, "Citadel: Alchemy Failed");

        // Emit Alchemy
        emit Alchemy(msg.sender, to, expansion.token, amount);

        return true;
    }

    /**
     * @dev Call expansion ERC1155 proxy to issue rewards.
     * @param to Receiver of rewards
     * @param id Item ID
     * @param amount Amount of rewards
     */
    function alchemy(
        address to,
        uint256 id,
        uint256 amount
    ) external nonReentrant returns (bool) {
        // Load Expansion Struct
        Expansion storage expansion = expansions[msg.sender];

        // Expansion Unavailable
        require(expansion.core != address(0), "Citadal: Expansion Unavailable");

        // Expansion Active
        require(expansion.active == true, "Citadal: Expansion Paused");

        // Check Amount is Valid
        require(expansion.balance.sub(amount) >= 0);

        // Update Remaining Balance
        expansion.balance = expansion.balance.sub(amount);

        // ERC1155 Alchemy Logic
        (bool success, ) =
            expansion.proxy.delegatecall(
                abi.encodeWithSignature(
                    "alchemy(address,address,uint256,uint256)",
                    expansion.token,
                    to,
                    id,
                    amount
                )
            );

        // Alchemy Success
        require(success == true, "Citadel: Alchemy Failed");

        // Emit Alchemy
        emit AlchemyItem(msg.sender, to, expansion.token, id, amount);

        return true;
    }

    /****************************************|
    |   Admin                                |
    |_______________________________________*/
    function initializedComplete() external returns (bool) {
        // Controller Role Required
        require(hasRole(CONTROLLER_ROLE, msg.sender));

        // Citadel Unitialized
        require(CITADEL_INITIALIZED == false);

        // Toggle Citadel Intialized
        CITADEL_INITIALIZED = true;

        return CITADEL_INITIALIZED;
    }

    function transferTokenOwnership(address token, address newOwner)
        external
        returns (bool)
    {
        // Controller Role Required
        require(hasRole(CONTROLLER_ROLE, msg.sender));

        // Transfer Child Contract Ownership
        (bool success, ) =
            token.call(
                abi.encodeWithSignature("transferOwnership(address)", newOwner)
            );

        // Ownership Transfer Success
        require(success == true, "Citadel: Child Owner Transfer Failed");

        return true;
    }
}
