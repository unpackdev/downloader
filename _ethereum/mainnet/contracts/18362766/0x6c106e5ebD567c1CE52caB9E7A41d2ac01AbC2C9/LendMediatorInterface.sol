// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IBlend.sol";
import "./IBlend.sol";

/**
 * @title MetaLend's mediator error interface
 * @author MetaLend
 * @notice defines the errors for reporting during reverts
 * @dev use this with proxy and implementation to report errors
 */
interface LendMediatorErrorInterface {
    /**
     * @notice Thrown when guarded function is called by not an owner
     * @param caller address of the invalid caller
     */
    error ErrCallerNotOwner(address caller);

    /**
     * @notice Thrown when guarded function is called by not an offerSigner or not an owner
     * @param caller address of the invalid caller
     */
    error ErrCallerNotOfferSignerOrOwner(address caller);

    /**
     * @notice Thrown when array input is invalid (such as length == 0)
     */
    error ErrInvalidArrInput();

    /**
     * @notice Thrown when input param is an invalid number (e.g. does not fit constraints)
     * @param num the invalid number
     */
    error ErrInvalidNumber(uint256 num);

    /**
     * @notice Thrown when transfer failed (e.g. Ether transfer)
     * @param to the target for transfer
     * @param amount the amount for transfer
     */
    error ErrTransferFailed(address to, uint256 amount);

    /**
     * @notice Thrown when transaction refund fails
     */
    error ErrRefundFailed();
}

/**
 * @title MetaLend's mediator event interface
 * @author MetaLend
 * @notice defines the events emitted during interaction
 * @dev use this with proxy and implementation to emit events
 */
interface LendMediatorEventInterface {
    /**
     * @notice emitted when an overdue loan is liquidated
     * @param protocol address of the lending protocol
     * @param loanId id of the loan
     */
    event OverdueLoanLiquidated(address indexed protocol, uint256 loanId);

    /**
     * @notice emitted when funds are deposited
     * @param tokenAddress the address of the ERC20 token
     * @param amount the amount
     */
    event FundsDeposited(address indexed tokenAddress, uint256 amount);

    /**
     * @notice emitted when funds are withdrawn
     * @param tokenAddress the address of the ERC20 token
     * @param amount the amount
     */
    event FundsWithdrawn(address indexed tokenAddress, uint256 amount);

    /**
     * @notice emitted when NFT tokens are withdrawn
     * @param tokenAddress the address of the ERC721 token
     * @param tokenIds the token ids
     */
    event NftsWithdrawn(address indexed tokenAddress, uint256[] tokenIds);

    /**
     * @notice emitted when royalties from loans are sent
     * @param tokenAddress the address of the ERC20 token
     * @param amount the amount
     */
    event RoyaltiesWithdrawn(address indexed tokenAddress, uint256 amount);

    /**
     * @notice emitted when mediator approves `spender` contract to transfer tokens on behalf of
     * @param tokenAddress the token contract
     * @param spender the spending contract, such as NFTFI or Arcade
     * @param newAllowance the new approving amount
     */
    event AllowanceModified(address indexed tokenAddress, address indexed spender, uint256 newAllowance);

    /**
     * @notice emitted when a loan ownership in given protocol is taken over by this mediator
     * @param protocol address of the lending protocol
     * @param loanId id of the loan
     */
    event LoanOwnershipClaimed(address indexed protocol, uint256 loanId);

    /**
     * @notice emitted when an auction on loan ownership is started in given protocol
     * @param protocol address of the lending protocol
     * @param loanId id of the loan
     */
    event LoanOwnershipAuctionStarted(address indexed protocol, uint256 loanId);
}

/**
 * @title MetaLend's mediator function interface
 * @author MetaLend
 * @notice defines the functions usable in mediator contracts
 * @dev use this with implementation contract to override functions
 */
interface LendMediatorFunctionInterface {
    /**
     * @notice function to deposit ERC20 funds
     * @dev called only by owner of this mediator
     * @param tokenAddress the address of the ERC20 token contract
     * @param amount the amount to deposit
     */
    function depositErc20(address tokenAddress, uint256 amount) external;

    /**
     * @notice liquidates NFTFI overdue loan and receives the NFT
     * @dev this contract must support IERC721Receiver, called only by owner of this mediator
     * @param nftfiAddress the address of the NFTFI protocol
     * @param loanId the id of the loan
     */
    function liquidateOverdueLoanNftfi(address nftfiAddress, uint32 loanId) external;

    /**
     * @notice liquidates Arcade overdue loan and receives the NFT
     * @dev this contract must support IERC721Receiver, called only by owner of this mediator
     * @param repaymentControllerAddress the address of the Arcade repayment controller
     * @param loanId the id of the loan
     */
    function liquidateOverdueLoanArcade(address repaymentControllerAddress, uint256 loanId) external;

    /**
     * @notice liquidates Blend overdue loan and receives the NFT
     * @dev this contract must support IERC721Receiver, called only by owner of this mediator or offer signer
     * @param blendAddress the address of the Blend protocol
     * @param lienPointer custom structure defined by Blend, see `IBlend.sol`
     */
    function liquidateOverdueLoanBlend(address blendAddress, LienPointer calldata lienPointer) external;

    /**
     * @notice takes ownership of lien in Blend protocol, must repay the debt
     * @dev called only by owner of this mediator or offer signer
     * @param blendAddress address of the Blend protocol
     * @param lien custom structure defined by Blend, see `IBlend.sol`
     * @param lienId id of the lien
     * @param rate Interest rate (in bips) - Formula: https://www.desmos.com/calculator/urasr71dhb
     */
    function takeOverLoanBlend(address blendAddress, Lien calldata lien, uint256 lienId, uint256 rate) external;

    /**
     * @notice starts auction on ownership for given lien
     * @dev called only by owner of this mediator or offer signer
     * @param blendAddress address of the Blend protocol
     * @param lien custom structure defined by Blend, see `IBlend.sol`
     * @param lienId id of the lien
     */
    function startAuctionBlend(address blendAddress, Lien calldata lien, uint256 lienId) external;

    /**
     * @notice deposits ETH to Blur Pool which is used to manage funds for Blend
     * @dev called only by owner of this mediator
     *  deposited ETH does not need approval for transfers between Blend services
     *  `msg.value` is the amount to deposit
     * @param blurPool address of the Blend pool
     */
    function depositBlurPool(address blurPool) external payable;

    /**
     * @notice withdraws ETH from Blur Pool
     * @dev called only by owner of this mediator
     * @param blurPool address of the Blend pool
     * @param amount the amount to withdraw
     */
    function withdrawBlurPool(address blurPool, uint256 amount) external;

    /**
     * @notice withdraws ERC721 NFTs
     * @dev called only by owner of this mediator
     * @param tokenIds the token id to withdraw
     * @param tokenAddress address of the NFT contract
     */
    function redeemErc721(uint256[] calldata tokenIds, address tokenAddress) external;

    /**
     * @notice withdraws ERC20 tokens minus fee if applicable
     * @dev called only by owner of this mediator
     * @param tokenAddress the address of the ERC20 token contract
     * @param amount the amount to withdraw
     */
    function withdrawErc20(address tokenAddress, uint256 amount) external;

    /**
     * @notice approves `approvingContract` to spend the ERC20 balance
     * @dev this approves to max uint256 value, make sure the `approvingContract` is safe
     *  called only by owner of this mediator
     * @param tokenAddress the address of the ERC20 token to approve
     * @param approvingContract the address of the account to approve for spending
     */
    function approveErc20(address tokenAddress, address approvingContract) external;

    /**
     * @notice removes ERC20 approval
     * @dev called only by owner of this mediator
     * @param tokenAddress the address of the ERC20 token to reset allowance for
     * @param approvingContract the address of the account to remove allowance from
     */
    function resetAllowance(address tokenAddress, address approvingContract) external;

    /**
     * @notice withdraws Ether to mediator owner
     * @dev called only by owner of this mediator
     * @param amount the amount to withdraw
     */
    function withdrawEther(uint256 amount) external;

    /**
     * @notice receive function to be able to get Ether
     * @dev no custom functionality at this moment
     */
    receive() external payable;
}

/**
 * @title MetaLend's mediator proxy interface
 * @author MetaLend
 * @notice defines events and errors for mediator proxy
 * @dev use this interface with mediator proxy
 */
interface LendMediatorProxyInterface {
    /**
     * @notice Thrown when input param is an invalid address (such as address(0))
     * @param addr the invalid address
     */
    error ErrInvalidAddress(address addr);

    /**
     * @notice Thrown when LendMediator creating contract is not a LendManager
     * @param addr the address of the invalid contract
     */
    error ErrCallerNotLendManager(address addr);

    /**
     * @notice emitted when a new LendManager is set (during initialization)
     * @param manager the manager address
     */
    event NewLendManager(address indexed manager);

    /**
     * @notice emitted when an owner is set (during initialization)
     * @param owner the owner addres
     */
    event NewOwner(address indexed owner);
}
