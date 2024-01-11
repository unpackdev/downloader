//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Implmenentation Contract import -- Twali's Base
import "./TwaliContract.sol";

// library imports
import "./Clones.sol";
import "./Ownable.sol";

contract TwaliContractFactory is Ownable {

        /// Implementation contract address
        address public contractImplementation;
        /// Mapping of all clone deployments
        mapping(address => address[]) public cloneContracts;

        constructor(address _contractImplementation) {
                contractImplementation = _contractImplementation;
        }

        // @dev Creates a contract clone of the Logic Implementation TwaliContract.sol.
        // @param - Initialized with (Contract Owner, SOW metadata URI, contract payment amount, start date, end date, timestamp it was created)
        function createTwaliClone(
                string memory _sowMetaData,
                uint _contract_payment_amount,
                uint _contract_start_date,
                uint _contract_end_date
                ) 
                external 
                onlyOwner
        {
                address payable clone = payable(Clones.clone(contractImplementation));
                TwaliContract(clone).initialize(owner(),
                                                _sowMetaData,
                                                _contract_payment_amount,
                                                _contract_start_date,
                                                _contract_end_date,
                                                block.timestamp);
                
                cloneContracts[msg.sender].push(clone);
        }

        /// @param _admin address is setReturn all created Clone contracrts
        function returnContractClones(address _admin) external view returns (address[] memory){
                return cloneContracts[_admin];
        }
}

