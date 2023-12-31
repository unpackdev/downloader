// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IDepositContract.sol";
import "./IBatchDepositWithELRVault.sol";

contract BatchDepositWithELRVault is IBatchDepositWithELRVault, Ownable {
    address public immutable depositContract;

    /// @notice Constant value
    uint256 public constant DEPOSIT_AMOUNT = 32 ether;
    
    /// @notice Maximum number of validators activated for a single transaction
    uint256 public maxPerDeposit;

    /// @notice Determine if the pubkey is used
    mapping(bytes32 => bool) internal existingPubKeys;

    constructor(address _depositContract, uint256 _maxPerDeposit) payable {
        depositContract = _depositContract;
        maxPerDeposit = _maxPerDeposit;
    }

    /// @dev update maxPerDeposit
    /// @param newMaxPerDeposit new maxPerDeposit value
    function updateMaxPerDeposit(uint256 newMaxPerDeposit) external onlyOwner {
        if(newMaxPerDeposit == 0) revert ZeroValueSet();
        if(newMaxPerDeposit == maxPerDeposit) revert RepeatSetup();
        maxPerDeposit = newMaxPerDeposit; 
        emit UpdateMaxPerDeposit(newMaxPerDeposit);
    }

    /// @dev batch deposit ETH to ETH2 depositContract
    /// @param pubkeys array of publickey
    /// @param withdrawalCredentials array of withdrawal_credential
    /// @param signatures array of signature
    /// @param depositDataRoots array of depositDataRoot
    /// @param tag user`s tag
    function batchDeposit(
        uint256 quantity,
        bytes[] calldata pubkeys, 
        bytes[] calldata withdrawalCredentials, 
        bytes[] calldata signatures,
        bytes32[] calldata depositDataRoots,
        bytes32 tag
        ) public payable {
        if(quantity > maxPerDeposit) revert ExceedingMaxLimit();
        if(msg.value != quantity * DEPOSIT_AMOUNT) revert InvalidETHAmount();
        if(pubkeys.length != quantity) revert PubkeysCountError(); 
        if(withdrawalCredentials.length != quantity) revert WithdrawalCredentialsCountError();
        if(signatures.length != quantity) revert SignaturesCountError(); 
        if(depositDataRoots.length != quantity) revert DepositDataRootsCountError();

        for(uint256 i = 0; i < quantity; ) {
            if(existingPubKeys[keccak256(pubkeys[i])]) revert PubkeyUsed();
            existingPubKeys[keccak256(pubkeys[i])] = true;
            IDepositContract(depositContract).deposit{value: DEPOSIT_AMOUNT}(pubkeys[i], abi.encodePacked(withdrawalCredentials[i]), signatures[i], depositDataRoots[i]);

            unchecked { ++i; }
        }

        emit BatchDeposited(msg.sender, tag, pubkeys, msg.value);
    }

    /// @dev sweep ETH in this contract 
    /// @param receiver receiver address
    function sweep(address receiver) public onlyOwner {
        if(address(receiver) == address(0)) revert ZeroValueSet();
        uint256 currentBalance = address(this).balance;
        if(currentBalance == 0) revert InvalidETHAmount();
        (bool sent, ) = payable(receiver).call{value: currentBalance}("");
        require(sent, "failed");

        emit Swept(msg.sender, receiver, currentBalance);
    }

    receive() external payable {}
}
