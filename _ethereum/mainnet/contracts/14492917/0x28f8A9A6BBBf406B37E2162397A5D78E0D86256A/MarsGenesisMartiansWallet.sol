///// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AccessControlEnumerable.sol";

/// @title MarsGenesis Martians wallet contract
/// @author MarsGenesis
/// @dev Equity values are 0 to 10000 (representing 0 to 100 with decimals). So an equity of 3000 means 30%
/// @notice Encapsulates the wallet and cap table management
contract MarsGenesisMartiansWallet is AccessControlEnumerable {

    /// @dev Address of the deployer account
    address private _deployerAddress;

    
    /*** CAP TABLE ***/

    address[] private _founders;
    mapping(address => uint) public founderToEquity;
    mapping(address => FounderAuthorization[]) private _addressToFounderAuthorization;

    /// @dev A mapping of cxo address to their pending withdrawal
    mapping (address => uint) public addressToPendingWithdrawal;
    
    /// @dev The max shares being 100 represented by 10000 (to accept decimal positions)
    uint private constant TOTAL_CAP = 10000;

    struct FounderAuthorization {      
        address founder;
        uint equity;
        bool approved;
        bool isRemoval;
    }

    /*** INIT ***/
    /// @notice Inits the wallet
    /// @dev defines a initial cap table with specific equity per founder. Equity values 0 - 10000 representing 0-100% equity
    /// @param cxo1 founder 1     
    /// @param cdo1 founder 2
    constructor (address cxo1, address cdo1) {
        _deployerAddress = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Initial cap table
        createInitialFounder(cxo1, 9500);
        createInitialFounder(cdo1, 500);
    }

    /// @notice Inits the a initial founder.
    /// @dev Only callable once on contract construction
    /// @param founderAddress The address of a initial founder 
    /// @param equity The equity of the initial founder. Equity values 0 - 10000 representing 0-100% equity
    function createInitialFounder(address founderAddress, uint equity) private {
        require(msg.sender == _deployerAddress, "ONLY_DEPLOYER");
        require(equity <= TOTAL_CAP, "INVALID EQUITY (0-10000)");

        _founders.push(founderAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, founderAddress);
        founderToEquity[founderAddress] = equity;
    }


    /*** PUBLIC ***/

    /// @notice Wallet should receive ether from MarsGenesisMartiansCore and MarsGenesisMartiansAuction
    /// @dev Ether received is splitted by equity among wallet founders
    receive() external payable {
        require(msg.value > 0, "INVALID_AMOUNT");
        _updatePendingWithdrawals(msg.value);
    }

    function withdraw() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
        
        uint amount = addressToPendingWithdrawal[_msgSender()];
        addressToPendingWithdrawal[_msgSender()] = 0;
        
        payable(_msgSender()).transfer(amount);
    }

    function _updatePendingWithdrawals(uint amount) private {
        for (uint i = 0; i < _founders.length; i++) {
            addressToPendingWithdrawal[_founders[i]] = addressToPendingWithdrawal[_founders[i]] + (amount * founderToEquity[_founders[i]] / TOTAL_CAP);
        }
    }
}