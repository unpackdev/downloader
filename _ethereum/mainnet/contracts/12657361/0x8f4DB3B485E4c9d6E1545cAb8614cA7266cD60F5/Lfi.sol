// SPDX-License-Identifier: GPLv3
pragma solidity ^0.7.6;

import "./AddressArray.sol";
import "./ILfi.sol";
import "./Reflect.sol";

contract Lfi is Reflect, ILfi {
    using AddressArray for address[];

    uint256 public immutable teamPreMinted;
    address public immutable teamAccount;

    address public governanceAccount;
    uint256 public cap;

    address[] private _treasuryPoolAddresses;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 cap_,
        uint8 feePercentage_,
        uint256 teamPreMinted_,
        address teamAccount_
    )
        Reflect(
            name_,
            symbol_,
            cap_,
            feePercentage_,
            teamPreMinted_,
            teamAccount_
        )
    {
        require(
            teamAccount_ != address(0),
            "LFI: team account is the zero address"
        );

        governanceAccount = msg.sender;
        cap = cap_;
        teamPreMinted = teamPreMinted_;
        teamAccount = teamAccount_;
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "LFI: sender not authorized");
        _;
    }

    modifier onlyTreasuryPool() {
        require(
            _treasuryPoolAddresses.contains(msg.sender),
            "LFI: sender not a treasury pool"
        );
        _;
    }

    function treasuryPoolAddresses() external view returns (address[] memory) {
        return _treasuryPoolAddresses;
    }

    function redeem(address to, uint256 amount)
        external
        override
        onlyTreasuryPool()
    {
        require(to != address(0), "LFI: redeem to the zero address");
        require(amount > 0, "LFI: redeem 0");

        _transfer(address(this), to, amount);
    }

    function setGovernanceAccount(address newGovernanceAccount)
        external
        onlyBy(governanceAccount)
    {
        require(
            newGovernanceAccount != address(0),
            "LFI: new governance account is the zero address"
        );

        governanceAccount = newGovernanceAccount;
    }

    function addTreasuryPoolAddress(address address_)
        external
        onlyBy(governanceAccount)
    {
        require(address_ != address(0), "LFI: address is the zero address");
        require(
            !_treasuryPoolAddresses.contains(address_),
            "LFI: address is already a treasury pool"
        );

        _treasuryPoolAddresses.push(address_);
    }

    function removeTreasuryPoolAddress(address address_)
        external
        onlyBy(governanceAccount)
    {
        require(address_ != address(0), "LFI: address is the zero address");

        uint256 index = _treasuryPoolAddresses.indexOf(address_);
        require(index > 0, "LFI: address not an existing treasury pool");

        _treasuryPoolAddresses.removeAt(index);
    }
}
