pragma solidity ^0.8.11;

import "./Auth.sol";
import "./SafeTransferLib.sol";

contract QuantumSplitter is Auth {

    /// >>>>>>>>>>>>>>>>>>>>>>>  STRUCTS  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    struct Split {
        uint256 balance;
        address[] recipients;
        uint256[] shares;
    }

    /// >>>>>>>>>>>>>>>>>>>>>>>  STATE  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    address payable public treasury = payable(0xe0faf18f33c307Ca812B80c771ad3c9E5f043Fe9);
    uint256 public treasuryShare = 2000;
    mapping (uint256 => Split) public splits;

    /// >>>>>>>>>>>>>>>>>>>>>>>  CONSTRUCTOR  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    constructor(address owner, address authority) Auth(owner, Authority(authority)) {
    }


    /// >>>>>>>>>>>>>>>>>>>>>>>  RESTRICTED  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Set a split
    /// @param dropId dropId corresponding to the split
    /// @dev Treasury payout is already taken in account
    /// @param recipients array of recipients
    /// @dev The fee denominator is 10000 in BPS.
    /// @param shares array of shares
    /*
        Example

        This would set the fee at 5%

        ```
        setSplit(0, [0xBEEF], [500])
        ```
    */
    function setSplit(
        uint256 dropId,
        address[] calldata recipients,
        uint256[] calldata shares)
    requiresAuth public 
    {
        require(recipients.length == shares.length, "UNMATCHED_LENGTH");
        /// @dev reads balance in case of split wasn't defined before it received eth
        splits[dropId] = Split(splits[dropId].balance, recipients, shares);
    }

    /// @notice Sets the treasury address
    /// @param treasury_ address of the treasury
    function setTreasury(address payable treasury_) requiresAuth public {
        treasury = treasury_;
    }

    /// @notice Sets the treasury's share of all splits
    /// @param share share of the treasury
    /// @dev The fee denominator is 10000 in BPS.
    /*
        Example

        This would set the fee at 5%

        ```
        setTreasuryShare(500)
        ```
    */
    function setTreasuryShare(uint256 share) requiresAuth public {
        treasuryShare = share;
    }

    /// @notice Withdraws all the funds held by the splitt
    /// @param to recipient of funds
    /// @param amount amount to withdraw
    function withdraw(address payable to, uint256 amount) requiresAuth public {
        SafeTransferLib.safeTransferETH(to, amount);
    }


    /// >>>>>>>>>>>>>>>>>>>>>>>  EXTERNAL  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Deposit funds for a dropId
    /// @dev split should exist beforehand
    /// @param dropId dropId corresponding to the split
    function deposit(uint256 dropId) public payable {
        require(splits[dropId].recipients.length > 0, "INVALID_SPLIT");
        splits[dropId].balance += msg.value;
    }

    /// @notice distribute funds of a split
    function distribute(uint256 dropId) public {
        Split memory split = splits[dropId];
        uint256 balance = split.balance;
        // initialize with Quantum's share
        uint256 toSend = balance * treasuryShare / 10000;
        uint256 length = split.recipients.length;

        SafeTransferLib.safeTransferETH(treasury, toSend);
        balance -= toSend;
        split.balance -= toSend;
        
        for(uint i; i < length; i++) {
            toSend = (split.balance * split.shares[i]) / 10000;
            balance -= toSend;
            SafeTransferLib.safeTransferETH(split.recipients[i], toSend);
        }
        require(balance == 0, "INSUFFICIENT_FUNDS");
        splits[dropId].balance = 0;
    }
}