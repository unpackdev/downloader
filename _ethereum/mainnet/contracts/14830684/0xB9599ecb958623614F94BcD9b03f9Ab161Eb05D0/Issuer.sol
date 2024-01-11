//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CoreRef.sol";
import "./IKeysManager.sol";
import "./IDepositContract.sol";
import "./IIssuer.sol";
import "./ReentrancyGuard.sol";

/// @author PStake
/// @title Issuer
/// @notice contract for issuance of StkEth
contract Issuer is CoreRef, IIssuer, ReentrancyGuard {
    uint256 public constant VALIDATOR_DEPOSIT = 31e18;
    uint256 public constant VERIFICATION_DEPOSIT = 1e18;

    uint256 public constant BASIS_POINT = 10000;

    IDepositContract public immutable DEPOSIT_CONTRACT;
    uint256 public override pendingValidators;
    uint256 public pendingValidatorsLimit;
    uint256 public ethStaked = 0;


    /// @notice constructor for initializing core
    /// @param core address of the core 
    /// @param _pendingValidatorsLimit ...
    /// @param _depositContract Deposit Contract address for Eth2
    constructor(
        address core,
        uint256 _pendingValidatorsLimit,
        address _depositContract
    ) CoreRef(core) {
        require(_depositContract != address(0), "Issuer: Zero address");
        DEPOSIT_CONTRACT = IDepositContract(_depositContract);
        require(_pendingValidatorsLimit < BASIS_POINT, "Issuer: invalid limit");
        pendingValidatorsLimit = _pendingValidatorsLimit;
    }


    /// @notice function returns pending validator limit.
    /// @return pendingValidatorsLimit number of pending validators.
    function pendingValidatorLimit()
    public
    view
    returns (uint256)
    {
        return pendingValidatorsLimit;
    }

    function ethStakedIssuer()
    public override
    view
    returns (uint256)
    {
        return ethStaked;
    }


    /// @notice function for setting the count of pending validators limit.
    /// @param _pendingValidatorsLimit integer limit for number of pending validators.
    function setPendingValidatorsLimit(uint256 _pendingValidatorsLimit)
    external
    onlyGovernor
    {
        require(_pendingValidatorsLimit < BASIS_POINT, "Issuer: invalid limit");
        pendingValidatorsLimit = _pendingValidatorsLimit;
        emit SetPendingValidatorsLimit(_pendingValidatorsLimit);
    }


    /// @notice function for updating the count of pending validators with new activated validators.
    /// @param newActiveValidators the number of new activated validators.
    function updatePendingValidator(uint256 newActiveValidators)
    external
    override
    {
        require(
            core().oracle() == msg.sender,
            "Issuer: Only oracle can update"
        );

        pendingValidators = pendingValidators - newActiveValidators;
        emit UpdatePendingValidators(pendingValidators);
    }


    /// @notice function to mint Stk Eth for Eth.
    /// @param amount amount of ether.
    /// @param user address of user.
    function mintStkEthForEth(uint256 amount, address user) internal {
        uint256 stkEthToMint = (amount * 1e18) / stkEth().pricePerShare();

        stkEth().mint(user, stkEthToMint);
    }

    /// @notice function for issuer to stake
    function stake() public payable whenNotPaused {
        require(msg.value > 0, "Issuer: can't stake zero");
        emit Stake(msg.sender, msg.value, block.timestamp);
        ethStaked = ethStaked + msg.value;
        mintStkEthForEth(msg.value, msg.sender);
    }

    /// @notice function for deposit of 32 Ether.
    /// @param publicKey public key of the validator.
    function depositToEth2(bytes calldata publicKey) external {
        require(address(this).balance >= VALIDATOR_DEPOSIT + VERIFICATION_DEPOSIT, "Issuer: Not enough ether deposited");
        IKeysManager.Validator memory validator = IKeysManager(
            core().keysManager()
        ).validators(publicKey);

        withdrawalverificationDeposit(validator.nodeOperator);

        IKeysManager(core().keysManager()).depositValidator(publicKey);

        pendingValidators = pendingValidators + 1;
        DEPOSIT_CONTRACT.deposit{value : VALIDATOR_DEPOSIT}(
            publicKey, //
            abi.encodePacked(core().withdrawalCredential()),
            validator.signature,
            validator.deposit_root
        );
    }


    /// @notice function for sending 1 Ether to a node operator address.
    /// @param nodeOperator address of the node operator
    function withdrawalverificationDeposit(address nodeOperator) internal nonReentrant {

        (bool sent,) = nodeOperator.call{value : VERIFICATION_DEPOSIT}("");
        require(sent, "Issuer: Failed to send to Node Operator");
    }

}



