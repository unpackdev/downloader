// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

interface ERC20 {
    function transfer(address, uint256) external;
}

// This contract releases payments to entities.
contract PermissionedPayments {
    //////////////////////////
    /////// Storage //////////
    //////////////////////////

    /// The addresses of the active entities
    address[] public s_entities;

    /// The rates of each entity
    mapping(address => uint256) public s_rates;

    /// The permissioned owner of this contract
    address public s_owner;

    modifier onlyOwner() {
        require(msg.sender == s_owner, "sender-not-owner");
        _;
    }

    event Payment(address indexed payee, uint256 indexed amount);

    /// @notice The contract contructor
    /// @dev Sets the owner
    /// @param owner: The owner's address
    constructor(address owner) {
        s_owner = owner;
    }

    /// @notice Add a new entity and set their rate
    /// @param entity : The address of the entity
    /// @param rate : Their rate
    /// @dev For gas optimization, function DOES NOT check for duplication. Inspect 'entities' manually if unsure
    function addEntity(address entity, uint256 rate) public onlyOwner {
        // Add entity to array and set rate
        s_entities.push(entity);
        s_rates[entity] = rate;
    }

    /// @notice Add a batch of new entity and set their rates
    /// @param entities : The addresses of the entities
    /// @param rates : Their rates
    /// @dev See `addEntity`
    function addEntities(address[] memory entities, uint256[] memory rates) public onlyOwner {
        require(entities.length == rates.length, "length-mismatch");
        for (uint256 i = 0; i < entities.length; i += 1) {
            addEntity(entities[i], rates[i]);
        }
    }

    /// @notice Change an entity's rate
    /// @param entity : The address of the entity
    /// @param rate : Their new rate
    function changeEntity(address entity, uint256 rate) public onlyOwner {
        // Set new rate
        s_rates[entity] = rate;
    }

    /// @notice Remove an entity
    /// @param entity : The address of the entity
    function removeEntity(address entity) public onlyOwner {
        // Set rate to zero
        s_rates[entity] = 0;

        // To delete from array, find element, replace with last element in array, and pop last element
        for (uint256 i = 0; i < s_entities.length; i += 1) {
            if (s_entities[i] == entity) {
                s_entities[i] = s_entities[s_entities.length - 1];
                s_entities.pop();
            }
        }
    }

    /// @notice Withdraw tokens
    /// @param tokenAddress : The address of the token
    /// @param amt : The amount of token to withdraw
    function withdrawTokens(address tokenAddress, uint256 amt) public onlyOwner {
        ERC20(tokenAddress).transfer(msg.sender, amt);
    }

    /// @notice Transfer ownership of this contract
    /// @param newOwner : The new owner
    function transferOwnership(address newOwner) public onlyOwner {
        s_owner = newOwner;
    }

    /// @notice Main function to pay all the entities their set rates
    /// @param tokenAddress The address of the token to pay
    /// @return totalAmount : The total amount of token to pay
    function executeAutomatic(address tokenAddress) public onlyOwner returns (uint256 totalAmount) {
        totalAmount = 0;
        for (uint256 i = 0; i < s_entities.length; i += 1) {
            address payee = s_entities[i];
            uint256 amount = s_rates[payee];
            totalAmount += amount;
            ERC20(tokenAddress).transfer(payee, amount);
            emit Payment(payee, amount);
        }
    }

    /// @notice Manually pay a batch of entities, for example for expenses
    /// @param tokenAddress The address of the token to pay
    /// @param entities : The addresses of the entities to be paid
    /// @param amounts : The amount to pay
    /// @return totalAmount : The total amount of token to pay
    function executeManual(
        address tokenAddress,
        address[] memory entities,
        uint256[] memory amounts
    ) public onlyOwner returns (uint256 totalAmount) {
        totalAmount = 0;
        require(entities.length == amounts.length, "length-mismatch");
        for (uint256 i = 0; i < entities.length; i += 1) {
            totalAmount += amounts[i];
            ERC20(tokenAddress).transfer(entities[i], amounts[i]);
            emit Payment(entities[i], amounts[i]);
        }
    }
}