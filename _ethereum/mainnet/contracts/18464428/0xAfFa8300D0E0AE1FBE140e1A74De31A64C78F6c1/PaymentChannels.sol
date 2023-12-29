// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
/*
 *@#+:-*==   .:. :     =#*=.  ..    :=**-    :+%@@@@@#*+-..........        .-.-@@
 *%%*.. +*:    =%.--     :+***+=++**=.    .+%@@@@@*-            . . .     .  -+= 
 *         -==+++. :#:        ..       .=#@@@@@*-   .:=*#%@@@@%#*=.  ...:::::    
 *     .:-======+=--%@*.             .*@@@@@@+   .=#@@@@@@##*#%@@@@@*-           
 *-:::-===-::------+#@@@*.         :*@@@@@@=   :*@@@%*==------=--+@@@@@#=:    .-=
 *=++==:::      .:=+=:.-=. .-**+++#**#@@@+   -#@@%=-::==       :*+--*@@@@@@@@@@@@
 *.....-=*+***+-.   .+#*-    +@@@@@@@@@+.  -%@@%-::. .-     .::-@@@%- -#@@@@@@@@@
 *   :*=@@@@@@@@@@#=.  -*@%#%@@@@@@@@*.  :#@@%-::    :=    =*%@@@@@@@%++*+*%@@@@@
 * .+*%@#+-:-=+*##*#@#=.  -*%@@@@@#=.  -#@@%-::       -:       :+@@@@@@@@*:  ..  
 *@@@%=         .-. :*@@#=.   ...   .=%@@#-:-      :-=++#####+=:  -#@@@@@@@@%*+++
 *@*:       :-=+::..   -#@@%+==--=+#@@%=.:+*=  :=*%@@@@%@@@@@@@@@*- .+%@@@@ SMG @
 *.     .+%@@=%%%##=....  :+*%%@@%#+-. =%@@@@@@%@@@@@@@@@@@%%%%@@@@@#=:-+%@@@@@@@
 */
import "./SafeERC20.sol";
import "./ECDSA.sol";
import "./OperatorRecoverable.sol";

interface IWETH {
    function withdraw(uint wad) external;
}

/**
 * @title PaymentChannels 
 * @notice Copyright (c) 2023 Special Mechanisms Group
 *
 * @author SMG <dev@mechanism.org>
 *
 * @notice The PaymentChannels contract implements the on-chain portion of a
 *         payment channel system. 
 *
 *         A payment channel allows for two parties to conduct a series of
 *         transactions of the main blockchain, then record the final result
 *         onto the main blockchain in one transaction.
 *
 *         Their efficiency makes them ideally suited for high-performance
 *         micropayments.
 *
 *         A payment channel is created by locking funds in a smart contract,
 *         then exchanging of-chain commitments with the channel's counterparty.
 *         The channel can be "settled" at any time by providing a more recent
 *         commitment, and "closed" when both parties agree on the final state.
 *
 *         Closing a channel is done either by providing a special commitment 
 *         that both parties agree is the last, or by providing a commitment 
 *         and waiting for a challenge period where the counterparty is free to 
 *         provide a more recent commitment if one exists.
 */
contract PaymentChannels is OperatorRecoverable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS 
    //////////////////////////////////////////////////////////////*/

    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    bytes constant public INSTANT_UNSTAKE_COMMITMENT_DATA = bytes("INSTANT");

    // EIP-712 constants
    string private constant CONTRACT_NAME = "PaymentChannels";
    string private constant CONTRACT_VERSION = "1.0";
    bytes32 private constant TYPEHASH_DOMAIN = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 private constant TYPEHASH_STAKE_COMMITMENT = keccak256(
        "StakeCommitment(address stakerAddress,uint256 stakeSpentAmount,uint256 stakeCommitmentNonce,uint256 stakeChannelNonce,bytes data)"
    );
    bytes32 private constant TYPEHASH_CLAIM_COMMITMENT = keccak256(
        "ClaimCommitment(address claimerAddress,uint256 claimsEarnedAmount)"
    );
    bytes32 private immutable DOMAIN_SEPARATOR;

    /*//////////////////////////////////////////////////////////////
                               ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /** 
     * @notice Address of the stakeNotary 
     * @dev The stakeNotary is an Ethereum account which co-signs commitments 
     *      made by the stakerAddress on the stake payment channels. 
     */
    address public stakeNotaryAddress;

    /**
     * @notice Address of the claimNotary
     * @dev The claimNotary is an Ethereum account which co-signs commitments
     *      made by the claimerAddress on the claim payment channels. 
     */
    address public claimNotaryAddress;

    /*//////////////////////////////////////////////////////////////
                     PAYMENT CHANNEL STATE (STAKE)
    //////////////////////////////////////////////////////////////*/
    
    /** 
     * @notice Amount of WETH staked by a stakerAddress. 
     *
     * @dev This value is only changed after calling the functions `stake`, 
     *      `unstake`, or `safeUnstake`, the latter who of which reset its
     *      value to 0.
     */
    mapping (address => uint256) public stakedAmount;

    /**
     * @notice Nonce used to order StakeCommitments.
     *
     * @dev This nonce increments each time a StakeCommitment is made on the
     *      payment channel, but will only increment on this contract when
     *      those StakeCommitments are brought on-chain using the functions
     *      `settleStakeCommitments`, `unstake`, or `startTimelockedUnstake`. 
     *      Its value is reset to 0 when the payment channel is closed.
     */
    mapping (address => uint256) public stakeCommitmentNonce;

    /** 
     * @notice Amount of WETH spent since the payment channel was opened.
     *
     * @dev Cannot exceed `stakedAmount`. Resets to 0 when the payment channel
     *      is closed.
     */
    mapping (address => uint256) public stakeSpentAmount;

    /** 
     * @notice Nonce used to order each time the payment channel is opened. 
     * 
     * @dev This nonce increments each time the payment channel is closed,
     *      so that if the same address opens a new payment channel after
     *      having closed one, it will be unique. This prevents certain
     *      channel re-use attacks.
     */
    mapping (address => uint256) public stakeChannelNonce;

    /** 
     * @notice Timestamp used to measure the timelock for unstaking.
     *
     * @dev When this value is non-zero, it means the payment channel is in
     *      its timelocked unstaking period, limiting certain operations.
     * @dev Unlike the other mappings, this one is indexed by a hash of a 
     *      StakeCommitment rather than an address. This is to prevent the need
     *      for another write to zero out the timestamp each time a channel is
     *      closed. By using a StakeCommitment hash instead (which is unique 
     *      due to the `stakeCommitmentNonce` and `stakeChannelNonce`), we 
     *      avoid the need for that additional write, saving gas.
     */
    mapping (bytes32 => uint256) public timelockedUnstakeTimestamp;

    /*//////////////////////////////////////////////////////////////
                    PAYMENT CHANNEL STATE (CLAIMS)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Amount of WETH each claimerAddress has claimed.
     * 
     * @dev Note that this value never decreases and persists for the lifetime 
     *      of the claimerAddress.
     */
    mapping (address => uint256) public claimedAmount;

    /**
     * @notice Total amount of claimable WETH.
     *
     * @dev Updated when the functions `adjustTotalClaimableAmount`, 
     *      `addToTotalClaimableAmount` or `settleClaim` are called.
     */
    uint256 public totalClaimableAmount;

    /*//////////////////////////////////////////////////////////////
                                EVENTS 
    //////////////////////////////////////////////////////////////*/

    event Staked(address indexed _stakerAddress, uint256 _stakeChannelNonce, uint256 _amount);
    event Claimed(address indexed _claimerAddress, uint256 _amount);
    event SetStakeNotaryAddress(address indexed _oldStakeNotaryAddress, address indexed _newStakeNotaryAddress);
    event SetClaimNotaryAddress(address indexed _oldClaimNotaryAddress, address indexed _newClaimNotaryAddress);
    event Unstaked(address indexed _stakerAddress, uint256 _stakeChannelNonce, uint256 _amount);
    event StartedTimelockedUnstake(
        address indexed _stakerAddress, 
        uint256 _stakeSpentAmount, 
        uint256 _stakeCommitmentNonce, 
        uint256 _stakeChannelNonce, 
        uint256 _timelockedUnstakeTimestamp);
    event AddedToTotalClaimableAmount(uint256 _amount);
    event SettledStakeCommitments(uint256 _totalNewStakeRefundedAmount, uint256 _totalNewStakeSpentAmount);

    /*//////////////////////////////////////////////////////////////
                            DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice A commitment on the stake payment channel.
     *
     * @dev The data in the StakeCommitment is how we represent a distinct
     *      state transition on the payment channel, such as a "spend," a
     *      "refund," or an "unstake". This data is periodically written
     *      on-chain using `settleStakeCommitments`, or when calling `unstake`
     *      or `startTimelockedUnstake` to begin the process of closing a 
     *      payment channel.
     */
    struct StakeCommitment {
        /** 
         * @dev Address of the owner of the stake and the payment channel 
         */
        address stakerAddress;
        /** 
         * @dev Amount of WETH that the owner has spent since opening the 
         *      payment channel. 
         */
        uint256 stakeSpentAmount;
        /**
         * @dev The nonce of the commitment. 
         */
        uint256 stakeCommitmentNonce;
        /**
         * @dev The nonce of the channel.
         */
        uint256 stakeChannelNonce;
        /**
         * @dev Reserved for off-chain use. Typically holds the hash of the
         *      previous commitment in a chain to ensure that the state remains
         *      consistent. However it is also used in `unstake` to signal a
         *      special StakeCommitment.
         */
        bytes data;
        /**
         * @dev The signature of the staker on the output of the function
         *      `getStakeCommitmentHash` or a locally-computed equivalent.
         */
        bytes stakerSignature;
        /**
         * @dev The signature of the stakeNotary on the output of the function
         *      `getStakeCommitmentHash` or a locally-computed equivalent.
         */
        bytes stakeNotarySignature;
    }

    /*//////////////////////////////////////////////////////////////
                          UTILITY METHODS 
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Fetch the most recent settled state of a payment channel.
     *
     * @dev Remember that the actual most recent state of the payment channel
     *      may be running ahead of the one on-chain, if there are new 
     *      off-chain StakeCommitments that have yet to be settled. 
     *
     * @param _stakerAddress The staker address.
     * @return _stakedAmount The amount of WETH staked.
     * @return _stakeCommitmentNonce The stake commitment nonce.
     * @return _stakeSpentAmount The amount of WETH the staker has spent. 
     * @return _stakeChannelNonce The stake channel nonce.
     * @return _timelockedUnstakeTimestamp The timestamp when startTimelockedUnstake was called. 
     */
    function getStakeChannelState(
        address _stakerAddress
    ) 
        external 
        view 
        returns (
            uint256 _stakedAmount, 
            uint256 _stakeCommitmentNonce, 
            uint256 _stakeSpentAmount, 
            uint256 _stakeChannelNonce, 
            uint256 _timelockedUnstakeTimestamp
        ) 
    {
        return (
            stakedAmount[_stakerAddress], 
            stakeCommitmentNonce[_stakerAddress], 
            stakeSpentAmount[_stakerAddress], 
            stakeChannelNonce[_stakerAddress], 
            getTimelockedUnstakeTimestamp(_stakerAddress));
    }

    /** 
     * @notice Compute the commitment hash used for stake signatures.
     *
     * @dev Convenience function that can be used by a staker or stakeNotary 
     *      to generate the message they will sign to create a valid 
     *      stakerSignature or stakeNotarySignature.
     *
     * @param _stakerAddress A staker address.
     * @param _stakeSpentAmount The amount of WETH the staker has spent. 
     * @param _stakeCommitmentNonce The stake commitment nonce.
     * @param _stakeChannelNonce The stake channel nonce.
     * @return bytes32 Keccak256 hash of the given StakeCommitment properties.
     */
    function getStakeCommitmentHash(
        address _stakerAddress, 
        uint256 _stakeSpentAmount, 
        uint256 _stakeCommitmentNonce, 
        uint256 _stakeChannelNonce, 
        bytes memory _data
    ) 
        public 
        view 
        returns (bytes32) 
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        TYPEHASH_STAKE_COMMITMENT,
                        _stakerAddress, 
                        _stakeSpentAmount, 
                        _stakeCommitmentNonce, 
                        _stakeChannelNonce, 
                        keccak256(abi.encodePacked(_data))
                    )
                )
            )
        );
    }

    /** 
     * @notice Compute the commitment hash used for stake signatures.
     *
     * @dev Convenience function that can be used by a staker or stakeNotary 
     *      to generate the message they will sign to create a valid 
     *      stakerSignature or stakeNotarySignature.
     *
     * @param _commitment A StakeCommitment.
     * @return bytes32 Keccak256 hash of the given StakeCommitment properties.
     */
    function getStakeCommitmentHash(
        StakeCommitment memory _commitment
    ) 
        internal 
        view 
        returns (bytes32) 
    {
        return getStakeCommitmentHash(
            _commitment.stakerAddress, 
            _commitment.stakeSpentAmount, 
            _commitment.stakeCommitmentNonce, 
            _commitment.stakeChannelNonce, 
            _commitment.data);
    }

    /**
     * @notice Compute the commitment hash used for claim signatures.
     *
     * @dev Convenience function that can be used by a claimer or claimNotary
     *      to generate the message they will sign to create a valid 
     *      claimerSignature or claimNotarySignature.
     *
     * @param _claimerAddress Address of the claimer.
     * @param _claimsEarnedAmount Amount of WETH earned to date by the claimer.
     * @return bytes32 Keccak256 hash of the given claim properties.
     */
    function getClaimCommitmentHash(
        address _claimerAddress, 
        uint256 _claimsEarnedAmount
    ) 
        public 
        view 
        returns (bytes32) 
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        TYPEHASH_CLAIM_COMMITMENT,
                        _claimerAddress, 
                        _claimsEarnedAmount
                    )
                )
            )
        );
    }

    /** 
     * @notice Get the key to look up the timelocked unstake timestamp. 
     *
     * @dev Timestamps are stored by hashing the data from the StakeCommitment
     *      a caller provides to startTimelockedUnstake. Because this hash will 
     *      be unique for unique StakeCommitments, we never need to zero out 
     *      timestamp, saving gas.
     * 
     * @param _stakerAddress Address of the staker.
     * @param _stakeSpentAmount The amount of WETH the staker has spent.
     * @param _stakeCommitmentNonce The stake commitment nonce.
     * @param _stakeChannelNonce The stake channel nonce.
     * @return bytes32 Index into `timelockedUnstakeTimestamp` mapping.
     */
    function getTimelockedUnstakeTimestampKey(
        address _stakerAddress, 
        uint256 _stakeSpentAmount, 
        uint256 _stakeCommitmentNonce, 
        uint256 _stakeChannelNonce
    ) 
        public 
        pure 
        returns (bytes32) 
    {
        return keccak256(abi.encode(_stakerAddress, _stakeSpentAmount, _stakeCommitmentNonce, _stakeChannelNonce));
    }

    /** 
     * @notice Get the timelocked unstake timestamp for a payment channel. 
     * 
     * @dev When the return value is non-zero, it means the associated payment
     *      channel is in its timelocked unstake mode, limiting certain
     *      functionality.
     *
     * @param _stakerAddress The staker address that owns the payment channel.
     * @return uint256 The timestamp when startTimelockedUnstake was called. 
     */
    function getTimelockedUnstakeTimestamp(
        address _stakerAddress
    ) 
        public 
        view 
        returns (uint256) 
    {
        return timelockedUnstakeTimestamp[
            getTimelockedUnstakeTimestampKey(
                _stakerAddress, 
                stakeSpentAmount[_stakerAddress], 
                stakeCommitmentNonce[_stakerAddress], 
                stakeChannelNonce[_stakerAddress])];
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR  
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice constructor
     *
     * @param _stakeNotaryAddress Initial stakeNotaryAddress
     * @param _claimNotaryAddress Initial claimNotaryAddress
     */
    constructor(address _stakeNotaryAddress, address _claimNotaryAddress) {
        /* Set initial stakeNotary and claimNotary addresses. */
        stakeNotaryAddress = _stakeNotaryAddress;
        claimNotaryAddress = _claimNotaryAddress;

        /* 
         * We want the smart contract operator to have the ability to recover
         * non-WETH ERC20 tokens transferred to it accidentally. The inherited 
         * OperatorRecoverable contract allows this for any ERC20, and we use 
         * `setTokenUnrecoverable` to permanently exclude WETH. 
         * For more, see `OperatorRecoverable.sol`.
         */
        setTokenUnrecoverable(address(WETH));

        /* Initialize EIP-712 Domain Separator */
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                TYPEHASH_DOMAIN,
                keccak256(bytes(CONTRACT_NAME)),
                keccak256(bytes(CONTRACT_VERSION)),
                block.chainid,
                address(this)
            )
        );

        /* Emit events */
        emit SetStakeNotaryAddress(address(0), _stakeNotaryAddress);
        emit SetClaimNotaryAddress(address(0), _claimNotaryAddress);
    }

    fallback() external payable {}
    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                          ADDRESS MANAGEMENT 
    //////////////////////////////////////////////////////////////*/

    /** 
     * @notice Update the stakeNotaryAddress. 
     *
     * @dev Only the contract operator can call this function.
     * @dev Any unsettled commitments co-signed by the old stakeNotaryAddress 
     *      will not be able to be settled once this change is made. Therefore
     *      the caller must either ensure that these are re-signed by the new
     *      stakeNotaryAddress, or abandoned. 
     *
     * @param _newStakeNotaryAddress Address of the new stakeNotary.
     */ 
    function setStakeNotaryAddress(
        address _newStakeNotaryAddress
    ) 
        external 
        onlyOperator 
    {
        emit SetStakeNotaryAddress(stakeNotaryAddress, _newStakeNotaryAddress);
        stakeNotaryAddress = _newStakeNotaryAddress;
    }

    /** 
     * @notice Update the claimNotaryAddress. 
     *
     * @dev Only the contract operator can call this function.
     * @dev Any unsettled commitments co-signed by the old claimNotaryAddress
     *      will not be able to be settled once this change is made. Therefore
     *      the caller must either ensure that these are re-signed by the new
     *      claimNotaryAddress, or abandoned.
     *
     * @param _newClaimNotaryAddress Address of the new claimNotary.
     */
    function setClaimNotaryAddress(
        address _newClaimNotaryAddress
    )  
        external 
        onlyOperator 
    {
        emit SetClaimNotaryAddress(claimNotaryAddress, _newClaimNotaryAddress);
        claimNotaryAddress = _newClaimNotaryAddress;
    }

    /*//////////////////////////////////////////////////////////////
                              STAKE LOGIC 
    //////////////////////////////////////////////////////////////*/

    /** 
     * @notice Stake WETH for use in a payment channel. 
     *
     * @dev This opens a payment channel, if one is not yet open already,
     *      with msg.sender as the stakerAddress. Whether or not there is 
     *      already an open payment channel, this function adds stake to it.
     * @dev Cannot be called when the payment channel is in its timelocked
     *      unstake mode. 
     *
     * @param _amount Amount of WETH to stake (in wei).
     */
    function stake(
        uint256 _amount
    ) 
        external 
    {
        require(getTimelockedUnstakeTimestamp(msg.sender) == 0, "Invalid channel state: cannot stake after startTimelockedUnstake has been called.");
        stakedAmount[msg.sender] += _amount;
        WETH.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, stakeChannelNonce[msg.sender], stakedAmount[msg.sender]);
    }

    /** 
     * @notice Donate claimable WETH to the contract.
     *
     * @dev In normal operation, claimable WETH accrues on settlement or 
     *      unstaking. This function can be used to create a buffer of
     *      immediaetly claimable WETH so that claimers do not need to wait
     *      for these periodic activities. It can also be used to amend any
     *      shortfalls.
     *
     * @param _amount Amount of WETH to donate (in wei).
     */
    function addToTotalClaimableAmount(
        uint256 _amount
    ) 
        external 
    {
        totalClaimableAmount += _amount;
        WETH.safeTransferFrom(msg.sender, address(this), _amount);
        emit AddedToTotalClaimableAmount(_amount);
    }

    /** 
     * @notice Adjusts staked WETH to claimable WETH and vice versa.
     *
     * @param _stakeRefundedAmount Amount of WETH no longer claimable (in wei). 
     * @param _stakeSpentAmount Amount of WETH newly claimable (in wei).
     */
    function adjustTotalClaimableAmount(
        uint256 _stakeRefundedAmount, 
        uint256 _stakeSpentAmount
    ) 
        internal 
    {
        if (_stakeSpentAmount < _stakeRefundedAmount) {
            /* Overall, stake was refunded. */
            uint256 refundAmount = _stakeRefundedAmount - _stakeSpentAmount;
            require(totalClaimableAmount >= refundAmount, "Invalid refund: refundAmount cannot exceed totalClaimableAmount.");
            totalClaimableAmount -= refundAmount;
        } else {
            /* Overall, stake was spent. */
            totalClaimableAmount += _stakeSpentAmount - _stakeRefundedAmount;
        }
    }

    /** 
     * @notice Settles off-chain commitments on-chain. 
     *
     * @dev Any address may call this function since the StakeCommitments
     *      are secured by signatures of both the staker and the stakeNotary. 
     *      In practice, the stakeNotary will likely be the caller. 
     * @dev It is sufficient to provide only the most recent unsettled 
     *      StakeCommitment for each payment channel. But this is not a
     *      requirement, and the function will behave the same if there are
     *      past commitments for the same channel also being provided.
     *
     * @param _commitments Array of StakeCommitments to be settled.
     */
    function settleStakeCommitments(
        StakeCommitment[] memory _commitments
    ) 
        external 
    {
        /* Tracks cumulative spending and refunding. */
        uint256 totalNewStakeSpentAmount = 0;
        uint256 totalNewStakeRefundedAmount = 0;

        for (uint i=0; i< _commitments.length; i++) {
            StakeCommitment memory commitment = _commitments[i];

            /* Validate commitment data*/
            require(getTimelockedUnstakeTimestamp(commitment.stakerAddress) == 0, "Invalid channel state: cannot settle new StakeCommitments after startTimelockedUnstake has been called.");
            require(commitment.stakeSpentAmount <= stakedAmount[commitment.stakerAddress], "Invalid StakeCommitment: provided stakeSpentAmount cannot exceed stakedAmount.");
            require(commitment.stakeCommitmentNonce >= stakeCommitmentNonce[commitment.stakerAddress], "Invalid StakeCommitment: provided stakeCommitmentNonce must be no older than stakeCommitmentNonce.");
            require(commitment.stakeChannelNonce == stakeChannelNonce[commitment.stakerAddress], "Invalid StakeCommitment: provided stakeChannelNonce must match stakeChannelNonce.");

            /* 
             * If a commitment in the batch has already been settled in a previous call to settleStakeCommitments,
             * skip it instead of reverting the entire batch. This is to prevent a malicious actor from DOS-ing
             * a batched call by frontrunning it with a single commitment from the batch.
             */
            if(commitment.stakeCommitmentNonce == stakeCommitmentNonce[commitment.stakerAddress]) {
                continue;
            }

            /* Validate signatures */
            address recoveredStakerAddress = ECDSA.recover(
                getStakeCommitmentHash(commitment), 
                commitment.stakerSignature
            );
            require(recoveredStakerAddress == commitment.stakerAddress, "Invalid StakeCommitment: stakerAddress does not match the signer of stakerSignature.");

            address recoveredStakeNotaryAddress =  ECDSA.recover(
                getStakeCommitmentHash(commitment), 
                commitment.stakeNotarySignature
            );
            require(recoveredStakeNotaryAddress == stakeNotaryAddress, "Invalid StakeCommitment: stakeNotaryAddress does not match the signer of stakeNotarySignature.");

            if (commitment.stakeSpentAmount < stakeSpentAmount[commitment.stakerAddress]) {
                /* Stake was refunded to the staker. */
                totalNewStakeRefundedAmount += stakeSpentAmount[commitment.stakerAddress] - commitment.stakeSpentAmount;
            } else {
                /* Stake was spent by the staker. */ 
                totalNewStakeSpentAmount += commitment.stakeSpentAmount - stakeSpentAmount[commitment.stakerAddress];
            }

            /* Update the channel state */
            stakeCommitmentNonce[commitment.stakerAddress] = commitment.stakeCommitmentNonce;
            stakeSpentAmount[commitment.stakerAddress] = commitment.stakeSpentAmount;
        }

        /* Adjust the total claimable amount all at once */
        adjustTotalClaimableAmount(totalNewStakeRefundedAmount, totalNewStakeSpentAmount);

        /* Emit event */
        emit SettledStakeCommitments(totalNewStakeRefundedAmount, totalNewStakeSpentAmount);
    }

    /** 
     * @notice Start or challenge a timelocked unstake procedure.
     * 
     * @dev The timelocked unstake procedure is a fail-safe mode that allows
     *      a staker to unstake even in the presence of a faulty stakeNotary. 
     *      Once the function is called, the associated payment channel is
     *      settled up to the provided StakeCommitment, and no further 
     *      commitments can be settled, except through this function.
     * @dev The unstaking can be completed after expiry of a 7 day timelock,
     *      by calling the `executeTimelockedUnstake` function.
     * @dev If the stakeNotary believes that the staker is being malicious 
     *      and providing an old but unsettled StakeCommitment, they can 
     *      challenge the unstake by calling this function with a more
     *      recent StakeCommitment, which also extends the timelock. The
     *      stakeNotary can challenge repeatedly, until the matter is resolved.
     * @dev A compromised stakeNotary could withhold more recent commitments
     *      from the staker and use these to indefinitely reset the timelock.
     *      In this event, the operator can call `setStakeNotaryAddress` to 
     *      change the `stakeNotaryAddress` to an uncompromised one.
     * @dev This function does not close the payment channel, but it does
     *      put it into a timelocked state where its functionality is reduced.
     *      To close the payment channel and actually unstake, the caller needs
     *      to call `executeTimelockedUnstake`.
     *
     * @param _commitment A StakeCommitment at least as recent as the last
     *                    one settled on-chain.
     */
    function startTimelockedUnstake(
        StakeCommitment memory _commitment
    ) 
        external 
    {
        /* Validate */
        if (getTimelockedUnstakeTimestamp(_commitment.stakerAddress) == 0) {
            require(msg.sender == _commitment.stakerAddress, "Invalid caller: only stakerAddress can call startTimelockedUnstake for the first time.");
        }
        require(_commitment.stakeSpentAmount <= stakedAmount[_commitment.stakerAddress], "Invalid StakeCommitment: provided stakeSpentAmount cannot exceed stakedAmount.");
        require(_commitment.stakeCommitmentNonce >= stakeCommitmentNonce[_commitment.stakerAddress], "Invalid StakeCommitment: provided stakeCommitmentNonce must be no older than stakeCommitmentNonce.");
        require(_commitment.stakeChannelNonce == stakeChannelNonce[_commitment.stakerAddress], "Invalid StakeCommitment: provided stakeChannelNonce must match stakeChannelNonce.");
        require(msg.sender == _commitment.stakerAddress || msg.sender == stakeNotaryAddress, "Invalid caller: only stakerAddress or stakeNotaryAddress can call startTimelockedUnstake.");
        
        /* Validate signatures */
        address recoveredStakerAddress = ECDSA.recover(
            getStakeCommitmentHash(_commitment), 
            _commitment.stakerSignature
        );
        require(recoveredStakerAddress == _commitment.stakerAddress, "Invalid StakeCommitment: stakerAddress does not match the signer of stakerSignature.");

        address recoveredStakeNotaryAddress =  ECDSA.recover(
            getStakeCommitmentHash(_commitment), 
            _commitment.stakeNotarySignature
        );
        require(recoveredStakeNotaryAddress == stakeNotaryAddress, "Invalid StakeCommitment: stakeNotaryAddress does not match the signer of stakeNotarySignature.");

        /* Settle the payment channel up to the provided StakeCommitment. */
        adjustTotalClaimableAmount(stakeSpentAmount[_commitment.stakerAddress], _commitment.stakeSpentAmount);
        stakeCommitmentNonce[_commitment.stakerAddress] = _commitment.stakeCommitmentNonce;
        stakeSpentAmount[_commitment.stakerAddress] = _commitment.stakeSpentAmount;

        /* Set the timelock */ 
        timelockedUnstakeTimestamp[
            getTimelockedUnstakeTimestampKey(
                _commitment.stakerAddress, 
                _commitment.stakeSpentAmount, 
                _commitment.stakeCommitmentNonce, 
                _commitment.stakeChannelNonce
            )] = block.timestamp + 7 days;

        /* Emit event */
        emit StartedTimelockedUnstake(
            _commitment.stakerAddress, 
            _commitment.stakeSpentAmount, 
            _commitment.stakeCommitmentNonce, 
            _commitment.stakeChannelNonce, 
            block.timestamp + 7 days);
    }

    /** 
     * @notice After timelock, unstake the stakerAddress's unspent WETH. 
     *
     * @dev When successful, this function closes the payment channel.
     * @dev Requires the `startTimelockedUnstake` function to have been last 
     *      called at least 7 days prior.
     *
     * @param _stakerAddress Address of the staker.
     */
    function executeTimelockedUnstake(
        address _stakerAddress
    ) 
        external 
    {
        /* Cache for event */
        uint256 _stakeChannelNonce = stakeChannelNonce[_stakerAddress];

        /* Validate */
        require(getTimelockedUnstakeTimestamp(_stakerAddress) > 0, "Invalid timelock: must call startTimelockedUnstake first.");
        require(block.timestamp > getTimelockedUnstakeTimestamp(_stakerAddress), "Invalid timelock: timelock has not yet expired.");
        
        /* Cache for event */
        uint256 unstakeAmount = stakedAmount[_stakerAddress] - stakeSpentAmount[_stakerAddress];
        require(unstakeAmount > 0, "Nothing to unstake");

        /* Close the payment channel */
        stakeCommitmentNonce[_stakerAddress] = 0;
        stakeSpentAmount[_stakerAddress] = 0;
        stakedAmount[_stakerAddress] = 0;
        stakeChannelNonce[_stakerAddress] += 1;

        /* Send the WETH */
        WETH.safeTransfer(_stakerAddress, unstakeAmount);

        /* Emit event */
        emit Unstaked(_stakerAddress, _stakeChannelNonce, unstakeAmount);
    }

    /** 
     * @notice Instantly unstake the stakerAddress's unspent WETH. 
     *
     * @dev The caller must provide a special StakeCommitment co-signed by
     *      the stakeNotary proving that the payment channel has been settled 
     *      and the stakeNotary has authorized the staker to unstake. This 
     *      special StakeCommitment can be requested using the off-chain API 
     *      associated with the stakeNotary. If the off-chain API is not 
     *      available for any reason, use startTimelockedUnstake instead.
     * @dev The special StakeCommitment is required in order to prevent either 
     *      a compromised stakeNotary or a malicious staker from unstaking 
     *      using an old or unsettled commitment. 
     * @dev Unstaking closes the payment channel, which means zeroing out all
     *      payment channel state associated with the `stakerAddress`, except 
     *      for `stakeChannelNonce`, which is incremented. A `stakerAddress` 
     *      which has unstaked can open a new payment channel by calling the
     *      `stake` function.
     *
     * @param _commitment A special StakeCommitment used to prove that the
     *                    stakerAddress is authorized to unstake.
     */
    function unstake(
        StakeCommitment memory _commitment
    ) 
        external 
    {
        /* Validate */
        require(msg.sender == _commitment.stakerAddress, "Invalid caller: only stakerAddress can call unstake.");
        require(_commitment.stakeSpentAmount <= stakedAmount[_commitment.stakerAddress], "Invalid StakeCommitment: provided stakeSpentAmount cannot exceed stakedAmount.");
        require(_commitment.stakeCommitmentNonce >= stakeCommitmentNonce[_commitment.stakerAddress], "Invalid StakeCommitment: provided stakeCommitmentNonce must be no older than stakeCommitmentNonce.");
        require(_commitment.stakeChannelNonce == stakeChannelNonce[_commitment.stakerAddress], "Invalid StakeCommitment: provided stakeChannelNonce must match stakeChannelNonce.");
        require(keccak256(_commitment.data) == keccak256(INSTANT_UNSTAKE_COMMITMENT_DATA), "Invalid StakeCommitment: provided data must match INSTANT_UNSTAKE_COMMITMENT_DATA.");

        /* Validate signatures */
        address recoveredStakerAddress = ECDSA.recover(
            getStakeCommitmentHash(_commitment), 
            _commitment.stakerSignature
        );
        require(recoveredStakerAddress == _commitment.stakerAddress, "Invalid StakeCommitment: stakerAddress does not match the signer of stakerSignature.");

        address recoveredStakeNotaryAddress =  ECDSA.recover(
            getStakeCommitmentHash(_commitment), 
            _commitment.stakeNotarySignature
        );
        require(recoveredStakeNotaryAddress == stakeNotaryAddress, "Invalid StakeCommitment: stakeNotaryAddress does not match the signer of stakeNotarySignature.");
        
        /* Settle the payment channel up to the provided StakeCommitment. */
        adjustTotalClaimableAmount(stakeSpentAmount[_commitment.stakerAddress], _commitment.stakeSpentAmount);
        
        /* Cache for event */
        uint256 unstakeAmount = stakedAmount[_commitment.stakerAddress] - _commitment.stakeSpentAmount;
        require(unstakeAmount > 0, "Nothing to unstake");

        /* Close the payment channel */
        stakeCommitmentNonce[_commitment.stakerAddress] = 0;
        stakeSpentAmount[_commitment.stakerAddress] = 0;
        stakedAmount[_commitment.stakerAddress] = 0;
        stakeChannelNonce[_commitment.stakerAddress] += 1;

        /* Send the WETH */
        WETH.safeTransfer(_commitment.stakerAddress, unstakeAmount);

        /* Emit event */
        emit Unstaked(_commitment.stakerAddress, _commitment.stakeChannelNonce, unstakeAmount);
    }

    /*//////////////////////////////////////////////////////////////
                             CLAIM LOGIC 
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Claim any WETH owed to the provided address. 
     *
     * @dev Can be called by anyone, not only the claimer. This allows claims
     *      to be securely processed by a third party, saving claimers gas.
     * @dev The caller must request that the claimNotary provide both an amount
     *      of WETH that the claimerAddress has earned over its lifetime (the
     *      _claimsEarnedAmount), and a signature (_claimNotarySignature), 
     *      witnessing the fact that the claimNotary agrees with that amount. 
     * @dev The message that results in _claimNotarySignature is the output of 
     *      the `getClaimCommitmentHash` function, or a locally-computed 
     *      equivalent.
     *
     * @param _claimerAddress Address of the claimer.
     * @param _claimsEarnedAmount Amount of WETH claimer has earned to date. 
     * @param _claimNotarySignature Signature of claimNotary endorsing above.
     */
    function claim(
        address _claimerAddress,
        uint256 _claimsEarnedAmount,
        bytes memory _claimNotarySignature
    ) 
        external 
    {
        settleClaim(
            _claimerAddress,
            _claimsEarnedAmount,
            _claimNotarySignature,
            false
        );
    }

    /**
     * @notice Claim any WETH owed to the provided address, as ETH. 
     *
     * @param _claimerAddress Address of the claimer.
     * @param _claimsEarnedAmount Amount of WETH claimer has earned to date. 
     * @param _claimNotarySignature Signature of claimNotary endorsing above.
     */
    function claimAndUnwrap(
        address _claimerAddress,
        uint256 _claimsEarnedAmount,
        bytes memory _claimNotarySignature
    ) 
        external 
    {
        settleClaim(
            _claimerAddress,
            _claimsEarnedAmount,
            _claimNotarySignature,
            true
        );
    }

    /** 
     * @notice Settle a claim of WETH or ETH.
     *
     * @param _claimerAddress Address of the claimer.
     * @param _claimsEarnedAmount Amount of WETH claimer has earned to date.
     * @param _claimNotarySignature Signature of claimNotary endorsing above.
     */
    function settleClaim(
        address _claimerAddress, 
        uint256 _claimsEarnedAmount,
        bytes memory _claimNotarySignature,
        bool unwrap
    ) 
        internal 
    {
        /* Validate that there is something to claim at all. */
        require(_claimsEarnedAmount > claimedAmount[_claimerAddress], "Invalid claim: there is nothing for the claimer to claim.");

        /* Recover signature signer and validate */ 
        address recoveredClaimNotaryAddress = ECDSA.recover(
            getClaimCommitmentHash(_claimerAddress, _claimsEarnedAmount), 
            _claimNotarySignature
        );
        require(recoveredClaimNotaryAddress == claimNotaryAddress, "Invalid claim: claimNotaryAddress is not the signer of claimNotarySignature.");

        /* Compute and validate the amount to be claimed */
        uint256 claimAmount = _claimsEarnedAmount - claimedAmount[_claimerAddress];
        require(claimAmount <= totalClaimableAmount, "Invalid claim: provided claimAmount cannot exceed totalClaimableAmount.");

        /* Settle the claim on-chain. */ 
        claimedAmount[_claimerAddress] = _claimsEarnedAmount;
        totalClaimableAmount -= claimAmount;

        /* Transfer the ETH or WETH to the claimer. */
        if (unwrap) {
            IWETH(address(WETH)).withdraw(claimAmount);
            (bool sent,) = _claimerAddress.call{value: claimAmount}("");
            require(sent, "Claim error: Failed to send ETH.");

        } else {
            WETH.safeTransfer(_claimerAddress, claimAmount);
        }

        /* Emit event */
        emit Claimed(_claimerAddress, claimAmount);
    }
}
