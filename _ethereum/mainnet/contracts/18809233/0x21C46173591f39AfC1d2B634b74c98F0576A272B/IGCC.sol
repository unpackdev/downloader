// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";

interface IGCC is IERC20 {
    /* -------------------------------------------------------------------------- */
    /*                                   errors                                  */
    /* -------------------------------------------------------------------------- */
    error CallerNotGCAContract();
    error BucketAlreadyMinted();
    error CommitPermitSignatureExpired();
    error CommitSignatureInvalid();
    error CommitAllowanceUnderflow();
    error MustIncreaseCommitAllowanceByAtLeastOne();
    error CannotReferSelf();
    /* -------------------------------------------------------------------------- */
    /*                                   structs                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @param lastUpdatedTimestamp - the last timestamp a user earned or used nominations
     * @ param amount - the amount of nominations a user has
     */
    struct Nominations {
        uint64 lastUpdatedTimestamp;
        uint192 amount;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   events                                  */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice is emitted when a user commits credits
     * @param account the account that committed credits
     * @param rewardAddress the address that earned the credits and nominations
     * @param gccAmount the amount of credits committed
     * @param usdcEffect the amount of USDC effect
     * @param impactPower - sqrt(amount gcc used in lp * amountc usdc used in lp) aka nominations granted
     * @param referralAddress the address that referred the account
     *             - zero address if no referral
     */
    event GCCCommitted(
        address indexed account,
        address indexed rewardAddress,
        uint256 gccAmount,
        uint256 usdcEffect,
        uint256 impactPower,
        address referralAddress
    );

    /**
     * @notice is emitted when a user commits USDC
     * @param account the account that commit the USDC
     * @param rewardAddress the address that earns nominations
     * @param amount the amount of USDC commit
     * @param impactPower - sqrt(amount gcc used in lp * amountc usdc used in lp) aka nominations granted
     * @param referralAddress the address that referred the account
     *             - zero address if no referral
     */
    event USDCCommitted(
        address indexed account,
        address indexed rewardAddress,
        uint256 amount,
        uint256 impactPower,
        address referralAddress
    );

    /**
     * @notice is emitted when a user approves a spender to commit credits on their behalf
     * @param account the account that approved a spender
     * @param spender the address of the spender
     * @param value -  new total allowance
     */
    event CommitGCCAllowance(address indexed account, address indexed spender, uint256 value);

    /* -------------------------------------------------------------------------- */
    /*                                   commits                                  */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice allows a user to commit credits
     * @param amount the amount of credits to commit
     * @param rewardAddress the address to commit the credits to
     *     -   Rewards Address earns:
     *     -       1.  Carbon Neutrality
     *     -       2.  Nominations
     * @param minImpactPower - the minimum amount of impact power to receive from the commitment
     * @return usdcEffect the amount of USDC used in the LP position
     * @return impactPower - sqrt(amount gcc used in lp * amountc usdc used in lp) aka nominations granted
     */
    function commitGCC(uint256 amount, address rewardAddress, uint256 minImpactPower)
        external
        returns (uint256 usdcEffect, uint256 impactPower);

    /**
     * @notice allows a user to commit credits
     * @param amount the amount of credits to commit
     * @param rewardAddress the address to commit the credits to
     *     -   Rewards Address earns:
     *     -       1.  Carbon Neutrality
     *     -       2.  Nominations
     * @param referralAddress the address that referred the account
     * @param minImpactPower - the minimum amount of impact power to receive from the commitment
     *
     * @return usdcEffect the amount of USDC used in the LP position
     * @return impactPower - sqrt(amount gcc used in lp * amountc usdc used in lp) aka nominations granted
     */
    function commitGCC(uint256 amount, address rewardAddress, address referralAddress, uint256 minImpactPower)
        external
        returns (uint256 usdcEffect, uint256 impactPower);

    /**
     * @notice the entry point for an approved entity to commit credits on behalf of a user
     * @param from the address of the user to commit credits from
     * @param rewardAddress the address of the reward address to commit credits to
     *         - Carbon Neutrality
     *         - Nominations
     * @param amount the amount of credits to commit
     * @param minImpactPower - the minimum amount of impact power to receive from the commitment
     *
     * @return usdcEffect the amount of USDC used in the LP position
     * @return impactPower - sqrt(amount gcc used in lp * amountc usdc used in lp) aka nominations granted
     */
    function commitGCCFor(address from, address rewardAddress, uint256 amount, uint256 minImpactPower)
        external
        returns (uint256, uint256);

    /**
     * @notice the entry point for an approved entity to commit credits on behalf of a user
     * @param from the address of the user to commit credits from
     * @param rewardAddress the address of the reward address to commit credits to
     *         - Carbon Neutrality
     *         - Nominations
     * @param amount the amount of credits to commit
     * @param referralAddress - the address that referred the account
     * @param usdcEffect the amount of USDC used in the LP position
     * @param minImpactPower - the minimum amount of impact power to receive from the commitment
     *
     * @param impactPower - sqrt(amount gcc used in lp * amountc usdc used in lp) aka nominations granted
     */
    function commitGCCFor(
        address from,
        address rewardAddress,
        uint256 amount,
        address referralAddress,
        uint256 minImpactPower
    ) external returns (uint256 usdcEffect, uint256 impactPower);

    /**
     * @notice the entry point for an approved entity to commit credits on behalf of a user using EIP712 signatures
     * @param from the address of the user to commit credits from
     * @param rewardAddress the address of the reward address to commit credits to
     *         - Carbon Neutrality
     *         - Nominations
     * @param amount the amount of credits to commit
     * @param deadline the deadline for the signature
     * @param signature - the signature
     * @param minImpactPower - the minimum amount of impact power to receive from the commitment
     *
     * @return usdcEffect the amount of USDC used in the LP position
     * @return impactPower - sqrt(amount gcc used in lp * amountc usdc used in lp) aka nominations granted
     */
    function commitGCCForAuthorized(
        address from,
        address rewardAddress,
        uint256 amount,
        uint256 deadline,
        bytes calldata signature,
        uint256 minImpactPower
    ) external returns (uint256 usdcEffect, uint256 impactPower);

    /**
     * @notice the entry point for an approved entity to commit credits on behalf of a user using EIP712 signatures
     * @param from the address of the user to commit credits from
     * @param rewardAddress the address of the reward address to commit credits to
     *         - Carbon Neutrality
     *         - Nominations
     * @param amount the amount of credits to commit
     * @param deadline the deadline for the signature
     * @param signature - the signature
     * @param referralAddress - the address that referred the account
     * @param minImpactPower - the minimum amount of impact power to receive from the commitment
     *
     * @return usdcEffect the amount of USDC used in the LP position
     * @return impactPower - sqrt(amount gcc used in lp * amountc usdc used in lp) aka nominations granted
     */
    function commitGCCForAuthorized(
        address from,
        address rewardAddress,
        uint256 amount,
        uint256 deadline,
        bytes calldata signature,
        address referralAddress,
        uint256 minImpactPower
    ) external returns (uint256 usdcEffect, uint256 impactPower);

    /**
     * @notice Allows a user to commit USDC
     * @param amount the amount of USDC to commit
     * @param rewardAddress the address to commit the USDC to
     * @param referralAddress the address that referred the account
     * @param minImpactPower - the minimum amount of impact power to receive from the commitment
     *
     * @return impactPower - sqrt(amount gcc used in lp * amountc usdc used in lp) aka nominations granted
     */
    function commitUSDC(uint256 amount, address rewardAddress, address referralAddress, uint256 minImpactPower)
        external
        returns (uint256 impactPower);

    /**
     * @notice Allows a user to commit USDC
     * @param amount the amount of USDC to commit
     * @param rewardAddress the address to commit the USDC to
     * @param minImpactPower - the minimum amount of impact power to receive from the commitment
     *
     * @return impactPower - sqrt(amount gcc used in lp * amountc usdc used in lp) aka nominations granted
     */
    function commitUSDC(uint256 amount, address rewardAddress, uint256 minImpactPower)
        external
        returns (uint256 impactPower);

    /**
     * @notice Allows a user to commit USDC using permit
     * @param amount the amount of USDC to commit
     * @param rewardAddress the address to commit the USDC to
     * @param referralAddress the address that referred the account
     * @param deadline the deadline for the signature
     * @param v the v value of the signature for permit
     * @param r the r value of the signature for permit
     * @param s the s value of the signature for permit
     * @param minImpactPower - the minimum amount of impact power to receive from the commitment
     *
     * @return impactPower - sqrt(amount gcc used in lp * amountc usdc used in lp) aka nominations granted
     */
    function commitUSDCSignature(
        uint256 amount,
        address rewardAddress,
        address referralAddress,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 minImpactPower
    ) external returns (uint256 impactPower);

    /* -------------------------------------------------------------------------- */
    /*                                   minting                                  */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice allows gca contract to mint GCC to the carbon credit auction
     * @dev must callback to the carbon credit auction contract so it can organize itself
     * @dev a bucket can only be minted from once
     * @param bucketId the id of the bucket to mint from
     * @param amount the amount of GCC to mint
     */
    function mintToCarbonCreditAuction(uint256 bucketId, uint256 amount) external;

    /* -------------------------------------------------------------------------- */
    /*                                   view functions                                  */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice returns a boolean indicating if the bucket has been minted
     * @return if the bucket has been minted
     */
    function isBucketMinted(uint256 bucketId) external view returns (bool);

    /**
     * @notice direct setter to set transfer allowance and committing allowance in one transaction for a {spender}
     * @param spender the address of the spender to set the allowances for
     * @param transferAllowance the amount of transfer allowance to set
     * @param committingAllowance the amount of committing allowance to set
     */
    function setAllowances(address spender, uint256 transferAllowance, uint256 committingAllowance) external;

    /**
     * @notice approves a spender to commit credits on behalf of the caller
     * @param spender the address of the spender
     * @param amount the amount of credits to approve
     */
    function increaseCommitAllowance(address spender, uint256 amount) external;

    /**
     * @notice decreases a spender's allowance to commit credits on behalf of the caller
     * @param spender the address of the spender
     * @param amount the amount of credits to decrease the allowance by
     */
    function decreaseCommitAllowance(address spender, uint256 amount) external;

    /**
     * @notice allows a user to increase the erc20 and committing allowance of a spender in one transaction
     * @param spender the address of the spender
     * @param addedValue the amount of credits to increase the allowance by
     */
    function increaseAllowances(address spender, uint256 addedValue) external;

    /**
     * @notice allows a user to decrease the erc20 and committing allowance of a spender in one transaction
     * @param spender the address of the spender
     * @param requestedDecrease the amount of credits to decrease the allowance by
     */
    function decreaseAllowances(address spender, uint256 requestedDecrease) external;

    /**
     * @notice returns the committing allowance for a user
     * @param account the address of the account to check
     * @param spender the address of the spender to check
     * @return the committing allowance
     */
    function commitAllowance(address account, address spender) external view returns (uint256);

    /**
     * @notice returns the next nonce to be used when committing credits
     *         - only applies when the user is using EIP712 signatures similar to Permit
     * @param account the address of the account to check
     */
    function nextCommitNonce(address account) external view returns (uint256);
}
