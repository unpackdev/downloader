// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "./OurStorage.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);
}

/**
 * @title OurSplitter
 * @author Nick A.
 * https://github.com/ourz-network/our-contracts
 *
 * These contracts enable creators, builders, & collaborators of all kinds
 * to receive royalties for their collective work, forever.
 *
 * Thank you,
 * @author Mirror       @title Splits   https://github.com/mirror-xyz/splits
 * @author Gnosis       @title Safe     https://github.com/gnosis/safe-contracts
 * @author OpenZeppelin                 https://github.com/OpenZeppelin/openzeppelin-contracts
 * @author Zora                         https://github.com/ourzora
 */

contract OurSplitter is OurStorage {
    struct Proof {
        bytes32[] merkleProof;
    }

    uint256 public constant PERCENTAGE_SCALE = 10e5;

    /**======== Subgraph =========
     * ETHReceived - emits sender and value in receive() fallback
     * WindowIncremented - emits current claim window, and available value of ETH
     * TransferETH - emits to address, value, and success bool
     * TransferERC20 - emits token's contract address and total transferred amount
     */
    event ETHReceived(address indexed sender, uint256 value);
    event WindowIncremented(uint256 currentWindow, uint256 fundsAvailable);
    event TransferETH(address account, uint256 amount, bool success);
    event TransferERC20(address token, uint256 amount);

    // Plain ETH transfers
    receive() external payable {
        _depositedInWindow += msg.value;
        emit ETHReceived(msg.sender, msg.value);
    }

    function claimETH(
        uint256 window,
        address account,
        uint256 scaledPercentageAllocation,
        bytes32[] calldata merkleProof
    ) external {
        require(currentWindow > window, "cannot claim for a future window");
        require(
            !isClaimed(window, account),
            "Account already claimed the given window"
        );

        _setClaimed(window, account);

        require(
            _verifyProof(
                merkleProof,
                merkleRoot,
                _getNode(account, scaledPercentageAllocation)
            ),
            "Invalid proof"
        );

        _transferETHOrWETH(
            account,
            // The absolute amount that's claimable.
            scaleAmountByPercentage(
                balanceForWindow[window],
                scaledPercentageAllocation
            )
        );
    }

    /**
     * @dev Attempts transferring entire balance of an ERC20 to corresponding Recipients
     * @notice if amount of tokens are not equally divisible according to allocation
     * the remainder will be forwarded to accounts[0].
     * In most cases, the difference will be negligible:
     *      ~remainder × 10^-17,
     *      or about 0.000000000000000100 at most.
     * @notice iterating through an array to push payments goes against best practices,
     *         therefore it is advised to avoid accepting ERC-20s as payment.
     */
    function claimERC20ForAll(
        address tokenAddress,
        address[] calldata accounts,
        uint256[] calldata allocations,
        Proof[] calldata merkleProofs
    ) external {
        require(
            _verifyProof(
                merkleProofs[0].merkleProof,
                merkleRoot,
                _getNode(accounts[0], allocations[0])
            ),
            "Invalid proof for Account 0"
        );

        uint256 erc20Balance = IERC20(tokenAddress).balanceOf(address(this));

        for (uint256 i = 1; i < accounts.length; i++) {
            require(
                _verifyProof(
                    merkleProofs[i].merkleProof,
                    merkleRoot,
                    _getNode(accounts[i], allocations[i])
                ),
                "Invalid proof"
            );

            uint256 scaledAmount = scaleAmountByPercentage(
                erc20Balance,
                allocations[i]
            );
            _attemptERC20Transfer(tokenAddress, accounts[i], scaledAmount);
        }

        _attemptERC20Transfer(
            tokenAddress,
            accounts[0],
            IERC20(tokenAddress).balanceOf(address(this))
        );

        emit TransferERC20(tokenAddress, erc20Balance);
    }

    function claimETHForAllWindows(
        address account,
        uint256 percentageAllocation,
        bytes32[] calldata merkleProof
    ) external {
        // Make sure that the user has this allocation granted.
        require(
            _verifyProof(
                merkleProof,
                merkleRoot,
                _getNode(account, percentageAllocation)
            ),
            "Invalid proof"
        );

        uint256 amount = 0;
        for (uint256 i = 0; i < currentWindow; i++) {
            if (!isClaimed(i, account)) {
                _setClaimed(i, account);

                amount += scaleAmountByPercentage(
                    balanceForWindow[i],
                    percentageAllocation
                );
            }
        }

        _transferETHOrWETH(account, amount);
    }

    function incrementThenClaimAll(
        address account,
        uint256 percentageAllocation,
        bytes32[] calldata merkleProof
    ) external {
        incrementWindow();
        _claimAll(account, percentageAllocation, merkleProof);
    }

    function incrementWindow() public {
        uint256 fundsAvailable;

        if (currentWindow == 0) {
            fundsAvailable = address(this).balance;
        } else {
            // Current Balance, subtract previous balance to get the
            // funds that were added for this window.
            fundsAvailable = _depositedInWindow;
        }

        _depositedInWindow = 0;
        require(fundsAvailable > 0, "No additional funds for window");
        balanceForWindow.push(fundsAvailable);
        currentWindow += 1;
        emit WindowIncremented(currentWindow, fundsAvailable);
    }

    function isClaimed(uint256 window, address account)
        public
        view
        returns (bool)
    {
        return _claimed[_getClaimHash(window, account)];
    }

    function scaleAmountByPercentage(uint256 amount, uint256 scaledPercent)
        public
        pure
        returns (uint256 scaledAmount)
    {
        /* Example:
                BalanceForWindow = 100 ETH // Allocation = 2%
                To find out the amount we use, for example: (100 * 200) / (100 * 100)
                which returns 2 -- i.e. 2% of the 100 ETH balance.
         */
        scaledAmount = (amount * scaledPercent) / (100 * PERCENTAGE_SCALE);
    }

    /// @notice same as claimETHForAllWindows() but marked private for use in incrementThenClaimAll()
    function _claimAll(
        address account,
        uint256 percentageAllocation,
        bytes32[] calldata merkleProof
    ) private {
        // Make sure that the user has this allocation granted.
        require(
            _verifyProof(
                merkleProof,
                merkleRoot,
                _getNode(account, percentageAllocation)
            ),
            "Invalid proof"
        );

        uint256 amount = 0;
        for (uint256 i = 0; i < currentWindow; i++) {
            if (!isClaimed(i, account)) {
                _setClaimed(i, account);

                amount += scaleAmountByPercentage(
                    balanceForWindow[i],
                    percentageAllocation
                );
            }
        }

        _transferETHOrWETH(account, amount);
    }

    //======== Private Functions ========
    function _setClaimed(uint256 window, address account) private {
        _claimed[_getClaimHash(window, account)] = true;
    }

    // Will attempt to transfer ETH, but will transfer WETH instead if it fails.
    function _transferETHOrWETH(address to, uint256 value)
        private
        returns (bool didSucceed)
    {
        // Try to transfer ETH to the given recipient.
        didSucceed = _attemptETHTransfer(to, value);
        if (!didSucceed) {
            // If the transfer fails, wrap and send as WETH, so that
            // the auction is not impeded and the recipient still
            // can claim ETH via the WETH contract (similar to escrow).
            IWETH(WETH).deposit{value: value}();
            IWETH(WETH).transfer(to, value);
            // At this point, the recipient can unwrap WETH.
            didSucceed = true;
        }

        emit TransferETH(to, value, didSucceed);
    }

    function _attemptETHTransfer(address to, uint256 value)
        private
        returns (bool)
    {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send ETH to the recipient.
        // NOTE: This might allow the recipient to attempt  a limited reentrancy attack.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: value, gas: 30000}("");
        return success;
    }

    /**
     * @dev Transfers ERC20s
     * @notice Reverts entire transaction if one fails
     * @notice A rogue owner could easily bypass countermeasures. Provided as last resort,
     * in case Proxy receives ERC20.
     */
    function _attemptERC20Transfer(
        address tokenAddress,
        address splitRecipient,
        uint256 allocatedAmount
    ) private {
        bool didSucceed = IERC20(tokenAddress).transfer(
            splitRecipient,
            allocatedAmount
        );
        require(didSucceed);
    }

    function _getClaimHash(uint256 window, address account)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(window, account));
    }

    function _amountFromPercent(uint256 amount, uint32 percent)
        private
        pure
        returns (uint256)
    {
        // Solidity 0.8.0 lets us do this without SafeMath.
        return (amount * percent) / 100;
    }

    function _getNode(address account, uint256 percentageAllocation)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, percentageAllocation));
    }

    // From https://github.com/protofire/zeppelin-solidity/blob/master/contracts/MerkleProof.sol
    function _verifyProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) private pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}
