//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @summary: Vesting contract that serves as an escrow for tokens to be locked (70% of all allocations)
 * @author: Boot Finance
 */

import "AccessControl.sol";
import "Pausable.sol";
import "SafeMath.sol";
import "IMinter.sol";

/// @title VestingMinter Contract
/// @dev Authorized addresses can vest tokens into this contract with amount, releaseTimestamp, revocable.
///      Either the grantee or GRANTOR_ROLE may mint (if unlocked as per the schedule).

contract VestingMinter is AccessControl, Pausable {
    using SafeMath for uint256;

    // DEFAULT_ADMIN_ROLE may grant/revoke DEFAULT_ADMIN_ROLE and GRANTOR_ADMIN_ROLE.

    // GRANTOR_ADMIN_ROLE may grant/revoke GRANTOR_ROLE.
    bytes32 public constant GRANTOR_ADMIN_ROLE = keccak256("GRANTOR_ADMIN_ROLE");

    // GRANTOR_ROLE may vest/revoke and pause/unpause.
    bytes32 public constant GRANTOR_ROLE = keccak256("GRANTOR_ROLE");

    IMinter public minter;
    uint256 public totalVestedAmount;
    uint256 public totalMintedAmount;

    struct Timelock {
        uint256 amount;
        uint256 duration;
        uint256 releaseTimestamp;
    }

    mapping(address => Timelock[]) public timelocks;
    mapping(address => uint256) public benMinted;       // total tokens minted
    mapping(address => uint256) public benVested;       // total tokens vested as of the last mint
    mapping(address => uint256) public benTotal;        // total locked in contract for user
    mapping(address => uint256) public benVestingIndex; // index to start the for loop for the user ignoring completely vested timelock

    event Vested(address indexed sender, uint256 amount, uint256 duration, uint256 releaseTimestamp);
    event Minted(address indexed beneficiary, uint256 amount);
    event Revoked(address indexed beneficiary, uint256 amount);

    /// @notice Constructor
    /// @param daoMultiSig DAO multi-sig address, default admin and grantor
    /// @param _minter Minter of vested tokens.
    constructor(address daoMultiSig, IMinter _minter) {
        require(address(_minter) != address(0), "Invalid address");
        minter = _minter;

        totalVestedAmount = 0;
        totalMintedAmount = 0;

        _setRoleAdmin(GRANTOR_ROLE, GRANTOR_ADMIN_ROLE);

        _grantRole(DEFAULT_ADMIN_ROLE, daoMultiSig);
        _grantRole(GRANTOR_ADMIN_ROLE, daoMultiSig);
        _grantRole(GRANTOR_ROLE, daoMultiSig);

        // temporary for allowing airdrop to vest 
        _grantRole(GRANTOR_ADMIN_ROLE, msg.sender);
    }

    /// Declares a new vesting for a specific grantee account in addition to any prior declaration for same account.
    /// @notice Grantor vest function
    /// @param beneficiary beneficiary address
    /// @param amount vesting amount
    function vest(address beneficiary, uint256 amount, uint256 duration, uint256 releaseTimestamp)
        external
        onlyRole(GRANTOR_ROLE)
    {
        require(beneficiary != address(0), "Invalid address");
        require(amount > 0, "amount cannot be 0");
        require(duration > 0, "duration cannot be 0");

        Timelock memory newVesting = Timelock(amount, duration, releaseTimestamp);
        timelocks[beneficiary].push(newVesting);

        totalVestedAmount = totalVestedAmount.add(amount);
        benTotal[beneficiary] = benTotal[beneficiary].add(amount);

        emit Vested(beneficiary, amount, duration, releaseTimestamp);
    }

    /// @notice Revoke vesting
    /// @param _addr beneficiary address
    function revoke(address _addr)
        external
        onlyRole(GRANTOR_ROLE)
    {
        uint256 amount = _mintableAmount(_addr).sub(benMinted[_addr]);
        require(amount <= benTotal[_addr]);
    
        benMinted[_addr] = benMinted[_addr].add(amount);
        totalMintedAmount = totalMintedAmount.add(amount);

        emit Minted(_addr, amount);

        uint256 locked = 0;
        for (uint256 i = 0; i < timelocks[_addr].length; i++) {
            locked = locked.add(timelocks[_addr][i].amount);
        }
        delete timelocks[_addr];

        uint256 bal = locked.sub(benMinted[_addr]);
        emit Revoked(_addr, bal);
        
        //clean slate
        delete benMinted[_addr];
        delete benVested[_addr];
        delete benTotal[_addr];
        delete benVestingIndex[_addr];
        
        if (bal > 0) {
            totalVestedAmount.sub(bal);
        }

        minter.mint(_addr, amount); //send vested
    }

    /// @notice Calculate amount mintable for beneficiary according to curent block time
    /// @param _addr beneficiary address
    function mintableAmount(address _addr)
        external
        view
        returns (uint256 sum)
    {
        // iterate across all the vestings
        // & check if the releaseTimestamp is elapsed
        // add all the amounts as mintable amount
        for (uint256 i = 0; i < timelocks[_addr].length; i++) {
            Timelock storage timelock = timelocks[_addr][i];
            if (block.timestamp >= timelock.releaseTimestamp) {
                sum = sum.add(timelock.amount);
            }
            else {
                sum = sum.add(block.timestamp.sub(timelock.releaseTimestamp.sub(timelock.duration)).mul(timelock.amount).div(timelock.duration));
            }
        }
    }
    
    /// @notice Mint whatever amount has vested for the sender.
    function mint()
        external
        whenNotPaused
    {
        _mint(msg.sender);
    }

    /// @notice Mint whatever amount has vested for the grantee.
    /// @param grantee The grantee that has a vested amount to mint.
    function mintFor(address grantee)
        external
        onlyRole(GRANTOR_ROLE)
        whenNotPaused
    {
        _mint(grantee);
    }

    /// @notice Pause contract 
    function pause()
        external
        onlyRole(GRANTOR_ROLE)
        whenNotPaused
    {
        _pause();
    }

    /// @notice Unpause contract
    function unpause()
        external
        onlyRole(GRANTOR_ROLE)
        whenPaused
    {
        _unpause();
    }

    // Calculate amount mintable by a particular address
    function _mintableAmount(address _addr)
        private
        returns (uint256)
    {
        uint256 completely_vested = 0;
        uint256 partial_sum = 0;
        uint256 inc = 0;

        // iterate across all the vestings
        // & check if the releaseTimestamp is elapsed
        // then, add all the amounts as claimable amount
        for (uint256 i = benVestingIndex[_addr]; i < timelocks[_addr].length; i++) {
            Timelock storage timelock = timelocks[_addr][i];
            if (block.timestamp >= timelock.releaseTimestamp) {
                inc += 1;
                completely_vested = completely_vested.add(timelock.amount);
            }
            else {
                uint256 iTimeStamp = timelocks[_addr][i].releaseTimestamp.sub(timelock.duration);
                uint256 claimable = block.timestamp.sub(iTimeStamp).mul(timelock.amount).div(timelock.duration);
                partial_sum = partial_sum.add(claimable);
            }
        }

        benVestingIndex[_addr] += inc;
        benVested[_addr] = benVested[_addr].add(completely_vested);
        uint256 s = benVested[_addr].add(partial_sum);
        require(s <= benTotal[_addr]);
        return s;
    }

    function _mint(address grantee)
        private
    {
        uint256 amount = _mintableAmount(grantee).sub(benMinted[grantee]);
        if (amount > 0) {
            require(amount.add(benMinted[grantee]) <= benTotal[grantee], "Cannot withdraw more than unclaimed amount");

            benMinted[grantee] = benMinted[grantee].add(amount);
            totalMintedAmount = totalMintedAmount.add(amount);
            minter.mint(grantee, amount);        
            emit Minted(grantee, amount);
        }
    }
}
