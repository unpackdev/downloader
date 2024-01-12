// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./Strings.sol";

contract FundsLock is Ownable {
    using Strings for uint256;

    struct Deposit {
        uint256 amount;
        uint256 lockupPeriodEnd;
        bool withdrawn;
    }

    mapping(address => Deposit[]) balances;
    address[] allowedContracts;

    constructor() {}

    modifier onlyAllowedContracts() {
        bool allowedContract;
        for (uint256 i = 0; i < allowedContracts.length; i++) {
            if (msg.sender == allowedContracts[i]) {
                allowedContract = true;
                break;
            }
        }
        require(allowedContract, "You are not authorized to deposit!");
        _;
    }

    function getBalances(address _address)
        public
        view
        returns (Deposit[] memory)
    {
        return balances[_address];
    }

    function depositFunds(address _recipent, uint256 _lockupInSeconds)
        public
        payable
        onlyAllowedContracts
    {
        require(msg.value > 0, "No ETH deposited!");
        Deposit memory deposit = Deposit({amount: msg.value, lockupPeriodEnd: block.timestamp + _lockupInSeconds, withdrawn: false});
        balances[_recipent].push(deposit);
    }

    function withdraw() external {
        for (uint i = 0; i < balances[msg.sender].length; i++) {
            if (!balances[msg.sender][i].withdrawn && balances[msg.sender][i].lockupPeriodEnd <= block.timestamp) {
                balances[msg.sender][i].withdrawn = true;
                (bool success, ) = payable(msg.sender).call{
                    value: balances[msg.sender][i].amount
                }("");
                require(success, "Withdrawal failed!");
            }
        }
    }

    function addAllowedContract(address _address) external onlyOwner {
        allowedContracts.push(_address);
    }

    function removeAllowedContract(address _address) external onlyOwner {
        for (uint i = 0; i < allowedContracts.length; i++) {
            if (allowedContracts[i] == _address) {
                removeFromAllowedContractsByIndex(i);
            }
        }
    }

    function removeFromAllowedContractsByIndex(uint _index) internal {
        allowedContracts[_index] = allowedContracts[
            allowedContracts.length - 1
        ];
        allowedContracts.pop();
    }
}
