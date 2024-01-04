pragma solidity ^0.5.16;

import "./Ownable.sol";

contract UniverseChart is Ownable {
    /**
     * @dev The struct of account information
     * @param id The account id
     * @param referrer The referrer addresss (cannot be address 0)
     * @notice company is the root account with id = 0 on initialization
     */
    struct Account {
        uint128 id;
        uint128 referrerId;
    }

    uint128 public lastId = 1;
    mapping(address => Account) public accounts;
    mapping(uint128 => address) public accountIds;

    event Register(uint128 id, address user, address referrer);

    constructor(address _company) public {
        setCompany(_company);
    }

    /**
     * @dev Utils function to change default company address
     * @param _referrer The referrer address;
     */
    function register(address _referrer) external {
        require(
            accounts[_referrer].id != 0 || _referrer == accountIds[0],
            "Invalid referrer address"
        );
        require(accounts[msg.sender].id == 0, "Account has been registered");

        Account memory account =
            Account({id: lastId, referrerId: accounts[_referrer].id});

        accounts[msg.sender] = account;
        accountIds[lastId] = msg.sender;

        emit Register(lastId++, msg.sender, _referrer);
    }

    /**
     * @dev Utils function to change default company address
     * @param _company The new company address;
     */
    function setCompany(address _company) public onlyOwner {
        require(
            _company != accountIds[0],
            "You entered the same company address"
        );
        require(
            accounts[_company].id == 0,
            "Company was registered on the chart"
        );
        Account memory account = Account({id: 0, referrerId: 0});
        accounts[_company] = account;
        accountIds[0] = _company;
    }
}
