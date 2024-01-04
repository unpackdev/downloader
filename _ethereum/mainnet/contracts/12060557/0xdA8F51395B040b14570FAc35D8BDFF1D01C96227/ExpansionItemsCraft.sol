// SPDX-License-Identifier: WTFPL
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

// import "./IERC20.sol";
import "./SafeMath.sol";

// Inheritance
import "./Ownable.sol";
import "./ERC20Staking.sol";

// Interfaces
import "./IERC1155TokenReceiver.sol";
import "./ILootCitadel.sol";

/**
 * @title Expansion ItemsCraft
 * @author TheLootMaster
 * @notice Stake LOOT to earn gold and craft items
 * @dev Manages staking of LOOT to earn rewards points for minting ERC1155 items
 */
contract ExpansionItemsCraft is ERC20Staking, Ownable {
    /***********************************|
    |   Libraries                       |
    |__________________________________*/
    using SafeMath for uint256;

    /***********************************|
    |   Constants                       |
    |__________________________________*/
    // Citadel
    ILootCitadel public citadel;

    // Points
    bool public priceLockup;
    uint256 public pointsPerDay;

    // Administation
    mapping(uint256 => bool) public exists;
    mapping(uint256 => uint256) public items;

    // User Rewards
    mapping(address => uint256) public points;
    mapping(address => uint256) public lastUpdateTime;

    /***********************************|
    |   Events                          |
    |__________________________________*/

    /**
     * @notice Staked
     * @dev Event fires when user stakes LOOT for earning points
     */
    event Staked(address user, uint256 amount);

    /**
     * @notice Withdrawl
     * @dev Event fires when user withdrew LOOT from staking
     */
    event Withdrawl(address user, uint256 amount);

    /**
     * @notice ItemAdded
     * @dev Event fires when a new item is added to crafing catalog
     */
    event ItemAdded(uint256 item, uint256 cost);

    /**
     * @notice ItemUpdated
     * @dev Event fires when the cost of item crafting is updated
     */
    event ItemUpdated(uint256 item, uint256 cost);

    /**
     * @notice ItemRemoved
     * @dev Event fires when the item can no longer be crafted
     */
    event ItemRemoved(uint256 item);

    /**
     * @notice ItemCrafted
     * @dev Event fires when a user burns points for item crafting
     */
    event ItemCrafted(uint256 item, address user);

    /***********************************|
    |   Modifiers                       |
    |__________________________________*/
    /**
     * @notice Update users reward balance
     * @dev Set the expansion confiration parameters
     * @param account Citadel target address
     */
    modifier updateReward(address account) {
        if (account != address(0)) {
            points[account] = earned(account);
            lastUpdateTime[account] = block.timestamp;
        }
        _;
    }

    /***********************************|
    |   Constructor                     |
    |__________________________________*/

    /**
     * @notice Smart Contract Constructor
     * @dev Set the expansion confiration parameters
     * @param _citadel Citadel target address
     * @param _loot loot address
     * @param _pointsPerDay loot address
     */
    constructor(
        address _citadel,
        address _loot,
        uint256 _pointsPerDay
    ) public ERC20Staking(_loot) {
        citadel = ILootCitadel(_citadel);
        pointsPerDay = _pointsPerDay;
    }

    /***********************************|
    |   Points and Staking              |
    |__________________________________*/

    /**
     * @notice Calculates earned points
     * @dev Streams points to users every second by dividing pointsPerDay by 86400
     * @param account Address of user
     * @return Points calculated at current block timestamp.
     */
    function earned(address account) public view returns (uint256) {
        uint256 blockTime = block.timestamp;

        return
            points[account].add(
                blockTime
                    .sub(lastUpdateTime[account])
                    .mul(pointsPerDay)
                    .div(86400)
                    .mul(balanceOf(account).div(1e18))
            );
    }

    /**
     * @notice Update pointsPerDay for each staked LOOT
     * @dev The points are streamed each second by dividing by 86400
     * @param _pointsPerDay Points per day with 18 decimals
     * @return True
     */
    function updatePointsPerDay(uint256 _pointsPerDay)
        external
        onlyOwner
        returns (bool)
    {
        // Set Points Allocation
        pointsPerDay = _pointsPerDay;

        return true;
    }

    /**
     * @notice Stake LOOT in Expansion ItemsCraft
     * @dev Stakes designated token using the ERC20Staking methods
     * @param amount Amount of LOOT to stake
     * @return Amount stake
     */
    function stake(uint256 amount)
        external
        updateReward(msg.sender)
        returns (uint256)
    {
        // Enforce 100,000 LOOT Staked
        require(
            amount.add(balanceOf(msg.sender)) <= 100000 ether,
            "Staking Limited to 100,000 LOOT"
        );

        // Stake LOOT
        _stake(amount);

        // Emit Staked
        emit Staked(msg.sender, amount);

        return amount;
    }

    /**
     * @notice Withdraw LOOT from ItemCraft.
     * @dev Withdraws designated token using the ERC20Staking methods
     * @param amount Amount of LOOT to withdraw
     * @return Amount withdrawn
     */
    function withdraw(uint256 amount)
        external
        updateReward(msg.sender)
        returns (uint256)
    {
        // Check User Staked Balance
        require(amount <= balanceOf(msg.sender));

        // Withdraw Staked LOOT
        _withdraw(amount);

        // Emit Withdrawl
        emit Withdrawl(msg.sender, amount);
    }

    /**
     * @notice Enables priceLockup
     * @dev Permanently prevents owner from updating the cost of item crafting.
     * @return Current priceLock boolean state
     */
    function enablePriceLock() external onlyOwner returns (bool) {
        require(priceLockup == false);
        priceLockup = true;
        return priceLockup;
    }

    /****************************************|
    |   Items                       |
    |_______________________________________*/

    /**
     * @notice Add Item and Crafting Cost
     * @dev Adds a items availabled in an existing ERC1155 smart contact.
     * @param id Item ID
     * @param cost Points to redeem Item
     * @return True
     */
    function addItem(uint256 id, uint256 cost) public onlyOwner returns (bool) {
        // Check if item exists or is being updated
        if (exists[id] == false) {
            // Set Item Cost
            items[id] = cost;

            // Set Creator
            exists[id] = true;

            // Emit ItemAdded
            emit ItemAdded(id, cost);
        } else {
            // Price Lockup is not activated
            require(!priceLockup, "Item Price Locked");

            // Set Item Cost
            items[id] = cost;

            // Emit ItemUpdated
            emit ItemUpdated(id, cost);
        }

        return true;
    }

    /**
     * @notice Batch ddd Items and Crafting Costs
     * @dev Adds a items availabled in an existing ERC1155 smart contact.
     * @param ids Item IDs
     * @param costs Points to craft items
     * @return True
     */
    function addItemBatch(uint256[] calldata ids, uint256[] calldata costs)
        external
        onlyOwner
        returns (bool)
    {
        // IDs and Cost Arrays length Match
        require(ids.length == costs.length);

        // Iterate Items and Crafting Cost
        for (uint256 index = 0; index < ids.length; index++) {
            addItem(ids[index], costs[index]);
        }

        return true;
    }

    /**
     * @notice Remove craftable item
     * @dev Prevents item from being crafted by setting crafting cost to zero
     * @param id Item ID
     * @return True
     */
    function removeItem(uint256 id) external onlyOwner returns (bool) {
        // Item Cost Set to Zero
        items[id] = 0;

        // Emit ItemRemoved
        emit ItemRemoved(id);

        return true;
    }

    /**
     * @notice Crafts item using earned points
     * @dev Mints a new ERC1155 item by calling the Citadel with the MINTER role.
     * Updates the users earned points before executing the crafting process.
     * @param id Item ID
     * @return True
     */
    function redeem(uint256 id)
        external
        updateReward(msg.sender)
        returns (bool)
    {
        // Check Item Is Available to Craft
        require(items[id] != 0, "Item Unavailable");

        // Sufficient User Points
        require(points[msg.sender] >= items[id], "Insufficient Points");

        // Update User Points
        points[msg.sender] = points[msg.sender].sub(items[id]);

        // Mint Item
        citadel.alchemy(msg.sender, id, 1);

        // Emit ItemCrafted
        emit ItemCrafted(id, msg.sender);

        return true;
    }
}
