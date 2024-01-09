// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface ERC20 {
    function transfer(address, uint256) external;
}

struct Grant {
    uint256 amount; // Total grant amount
    uint256 claimed; // Amount of grant claimed
}

contract VestingContract {

    event Claim(address indexed beneficiary, uint256 indexed amt);

    // Mapping of grant beneficiaries to grants
    mapping(address => Grant) public s_grants;

    // Owner of this contract (Ballast team multisig)
    address public s_owner = 0x6A65174b874e357b711B948d523ceB62319E292b;

    // The address of the BLST token
    address constant TOKEN_ADDRESS = 0xE7B40046a1f6f5561a6Edf329F61874f3fDcd3b1;

    // The grant start and end times
    uint48 constant START = 1643651983;             // timestamp of IDO
    uint48 constant END = START + (2629746 * 3);    // IDO + 3 months

    // The contract contructor
    constructor(address[] memory addresses, uint256[] memory amounts) {
        for (uint256 i = 0; i < addresses.length; i += 1) {
            s_grants[addresses[i]] =  Grant(amounts[i], 0);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner, "sender-not-owner");
        _;
    }

    // ----------- PERMISSIONED FUNCTIONS (Note : The owner should be burned once the grants are set up) ----------------
    // Owner can withdraw tokens
    function withdrawTokens(uint256 amt) public onlyOwner {
        ERC20(TOKEN_ADDRESS).transfer(msg.sender, amt);
    }

    // Transfer ownership of this contract
    // Note: Transfer to address(0) to burn ownership
    function transferOwnership(address newOwner) public onlyOwner {
        s_owner = newOwner;
    }

    // Can be used to add a new grant, and change the terms (or destroy) an existing grant
    function overwriteGrant(address beneficiary, uint256 amount, uint256 claimed) public onlyOwner {
        s_grants[beneficiary] = Grant(amount, claimed);
    }

    // ------------------------------------------------------------------------------------------------

    // A beneficiary can give rights to their grant to another address (as long as it is not already a beneficiary)
    function changeBeneficiary(address newBeneficiary) public {
        require(s_grants[newBeneficiary].amount == 0, "not-new-beneficiary");
        Grant memory grant = s_grants[msg.sender];
        delete s_grants[msg.sender];
        s_grants[newBeneficiary] = grant;
    }

    // Claim tokens which are accrued but not yet claimed
    function claim() public {
        Grant memory grant = s_grants[msg.sender];
        uint256 amt = unpaidInternal(grant.amount, grant.claimed);
        s_grants[msg.sender].claimed = grant.claimed + amt;
        ERC20(TOKEN_ADDRESS).transfer(msg.sender, amt);
        emit Claim(msg.sender, amt);
    }

    // The total number of tokens accrued (paid and unpaid)
    function accrued(address beneficiary) public view returns (uint256 amt) {
        Grant memory grant = s_grants[beneficiary];
        amt = accruedInternal(grant.amount);
    }

    // The number of accrued but unpaid tokens
    function unpaid(address beneficiary) public view returns (uint256 amt) {
        Grant memory grant = s_grants[beneficiary];
        amt = unpaidInternal(grant.amount, grant.claimed);
    }

    // Calculates accrued tokens
    function accruedInternal(
        uint256 amount
    ) internal view returns (uint256 amt) {
        uint256 time = block.timestamp;
        if (time < START) {
            amt = 0;
        } else if (time >= END) {
            amt = amount;
        } else {
            amt = (amount * (time - START)) / (END - START);
        }
    }

    // Calculates unpaid tokens
    function unpaidInternal(
        uint256 amount,
        uint256 claimed
    ) internal view returns (uint256 amt) {
        amt = accruedInternal(amount) - claimed;
    }
}