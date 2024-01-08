//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IRouterProxy.sol";
import "./IRouterDiamond.sol";
import "./IERC2612Permit.sol";

/**
 * @dev If we are paying the fee in something other than ALBT or transferring
 * native currency, we use this proxy contract instead of the bridge router.
 */
contract RouterProxy is IRouterProxy, ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public routerAddress;
    address public albtToken;
    mapping(address => uint256) public feeAmountByToken;
    uint8 private immutable _decimals;

    /**
     *  @notice Constructs a new RouterProxy contract
     *  @param routerAddress_ The address of the underlying router
     *  @param albtToken_ The address of the (w)ALBT contract
     *  @param tokenName_ The name for the ERC20 token representing the native currency
     *  @param tokenSymbol_ The symbol for the ERC20 token representing the native currency
     *  @param decimals_ The number of decimals for the ERC20 token representing the native currency
     */
    constructor(
        address routerAddress_, address albtToken_, string memory tokenName_, string memory tokenSymbol_, uint8 decimals_
    ) ERC20(tokenName_, tokenSymbol_) {
        require(routerAddress_ != address(0), "Router address must be non-zero");
        require(albtToken_ != address(0), "ALBT address must be non-zero");
        routerAddress = routerAddress_;
        albtToken = albtToken_;
        _decimals = decimals_;
    }

    /**
     *  @notice Set the fee amount for a token
     *  @param tokenAddress_ The address of the ERC20 token contract
     *  @param fee_ The fee amount when paying with this token
     */
    function setFee(address tokenAddress_, uint256 fee_) external override onlyOwner {
        emit FeeSet(tokenAddress_, feeAmountByToken[tokenAddress_], fee_);
        feeAmountByToken[tokenAddress_] = fee_;
    }

    /**
     *  @param tokenAddress_ The address of the ERC20 token contract
     *  @return The fee amount for the token
     */
    function _fee(address tokenAddress_) view internal virtual returns (uint256) {
        require(feeAmountByToken[tokenAddress_] > 0, "Unsupported token");
        return feeAmountByToken[tokenAddress_];
    }

    /**
     *  @notice Set the address for the router contract
     *  @param routerAddress_ The address of the router contract
     */
    function setRouterAddress(address routerAddress_) external override onlyOwner {
        emit RouterAddressSet(routerAddress, routerAddress_);
        routerAddress = routerAddress_;
    }

    /**
     *  @notice Set the address for the (w)ALBT contract
     *  @param albtToken_ The address of the (w)ALBT contract
     */
    function setAlbtToken(address albtToken_) external override onlyOwner {
        emit AlbtAddressSet(albtToken, albtToken_);
        albtToken = albtToken_;
    }

    /**
     *  @param tokenAddress_ The address of the token contract
     *  @return Checks if the supplied token address is representing the native currency
     */
    function _isNativeCurrency(address tokenAddress_) internal view returns(bool) {
        return tokenAddress_ == address(this);
    }

    /**
     *  @notice Gets the user's funds and approves their transfer to the router, covering the fee in (w)ALBT
     *  @param feeToken_ Token the user is paying the fee in
     *  @param transferToken_ Token the user wants to transfer
     *  @param amount_ Amount the user wants to transfer
     */
    function _setupProxyPayment(address feeToken_, address transferToken_, uint256 amount_) internal nonReentrant {
        uint256 currencyLeft = msg.value;
        bool isTransferTokenNativeCurrency = _isNativeCurrency(transferToken_);

        if (isTransferTokenNativeCurrency) {
            require(currencyLeft >= amount_, "Not enough funds sent to transfer");
            currencyLeft -= amount_;
            _mint(address(this), amount_);
        }
        else {
            IERC20(transferToken_).safeTransferFrom(msg.sender, address(this), amount_);
        }

        uint256 feeOwed = _fee(feeToken_);
        if (_isNativeCurrency(feeToken_)) {
            require(currencyLeft >= feeOwed, "Not enough funds sent to pay the fee");
            currencyLeft -= feeOwed;

            (bool success, bytes memory returndata) = owner().call{value: feeOwed}("");
            require(success, string(returndata));
        }
        else {
            IERC20(feeToken_).safeTransferFrom(msg.sender, owner(), feeOwed);
        }
        emit FeeCollected(feeToken_, feeOwed);

        uint256 albtApproveAmount = IRouterDiamond(routerAddress).serviceFee() + IRouterDiamond(routerAddress).externalFee();
        if (transferToken_ == albtToken) {
            albtApproveAmount += amount_;
        }
        else if (isTransferTokenNativeCurrency) {
            _approve(address(this), routerAddress, amount_);
        }
        else {
            IERC20(transferToken_).approve(routerAddress, amount_);
        }
        IERC20(albtToken).approve(routerAddress, albtApproveAmount);

        if (currencyLeft > 0) {
            (bool success, bytes memory returndata) = msg.sender.call{value: currencyLeft}("");
            require(success, string(returndata));
        }
    }

    /**
     *  @notice Transfers `amount` native tokens to the router contract.
                The router must be authorised to transfer both the native token and the ALBT tokens for the fees.
     *  @param feeToken_ Token used to pay the fee
     *  @param targetChain_ The target chain for the bridging operation
     *  @param nativeToken_ The token to be bridged
     *  @param amount_ The amount of tokens to bridge
     *  @param receiver_ The address of the receiver in the target chain
     */
    function lock(
        address feeToken_,
        uint8 targetChain_,
        address nativeToken_,
        uint256 amount_,
        bytes calldata receiver_
    ) public override payable {
        _setupProxyPayment(feeToken_, nativeToken_, amount_);
        IRouterDiamond(routerAddress).lock(targetChain_, nativeToken_, amount_, receiver_);
        emit ProxyLock(feeToken_, targetChain_, nativeToken_, amount_, receiver_);
    }

    /**
     *  @notice Locks the provided amount of nativeToken using an EIP-2612 permit and initiates a bridging transaction
     *  @param feeToken_ Token used to pay the fee
     *  @param targetChain_ The chain to bridge the tokens to
     *  @param nativeToken_ The native token to bridge
     *  @param amount_ The amount of nativeToken to lock and bridge
     *  @param deadline_ The deadline for the provided permit
     *  @param v_ The recovery id of the permit's ECDSA signature
     *  @param r_ The first output of the permit's ECDSA signature
     *  @param s_ The second output of the permit's ECDSA signature
     */
    function lockWithPermit(
        address feeToken_,
        uint8 targetChain_,
        address nativeToken_,
        uint256 amount_,
        bytes calldata receiver_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external override payable {
        IERC2612Permit(nativeToken_).permit(msg.sender, address(this), amount_, deadline_, v_, r_, s_);
        lock(feeToken_, targetChain_, nativeToken_, amount_, receiver_);
    }

    /**
     *  @notice Calls burn on the given wrapped token contract with `amount` wrapped tokens from `msg.sender`.
                The router must be authorised to transfer the ABLT tokens for the fees.
     *  @param feeToken_ Token used to pay the fee
     *  @param wrappedToken_ The wrapped token to burn
     *  @param amount_ The amount of wrapped tokens to be bridged
     *  @param receiver_ The address of the user in the original chain for this wrapped token
     */
    function burn(
        address feeToken_, address wrappedToken_, uint256 amount_, bytes memory receiver_
    ) public override payable {
        _setupProxyPayment(feeToken_, wrappedToken_, amount_);
        IRouterDiamond(routerAddress).burn(wrappedToken_, amount_, receiver_);
        emit ProxyBurn(feeToken_, wrappedToken_, amount_, receiver_);
    }

    /**
     *  @notice Burns `amount` of `wrappedToken` using an EIP-2612 permit and initializes a bridging transaction to the original chain
     *  @param feeToken_ Token used to pay the fee
     *  @param wrappedToken_ The address of the wrapped token to burn
     *  @param amount_ The amount of `wrappedToken` to burn
     *  @param receiver_ The receiving address in the original chain for this wrapped token
     *  @param deadline_ The deadline of the provided permit
     *  @param v_ The recovery id of the permit's ECDSA signature
     *  @param r_ The first output of the permit's ECDSA signature
     *  @param s_ The second output of the permit's ECDSA signature
     */
    function burnWithPermit(
        address feeToken_,
        address wrappedToken_,
        uint256 amount_,
        bytes calldata receiver_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external override payable {
        IERC2612Permit(wrappedToken_).permit(msg.sender, address(this), amount_, deadline_, v_, r_, s_);
        burn(feeToken_, wrappedToken_, amount_, receiver_);
    }

    /**
     *  @notice Calls burn on the given wrapped token contract with `amount` wrapped tokens from `msg.sender`.
                The router must be authorised to transfer the ABLT tokens for the fees.
     *  @param feeToken_ Token used to pay the fee
     *  @param targetChain_ The target chain for the bridging operation
     *  @param wrappedToken_ The wrapped token to burn
     *  @param amount_ The amount of wrapped tokens to be bridged
     *  @param receiver_ The address of the user in the original chain for this wrapped token
     */
    function burnAndTransfer(
        address feeToken_,
        uint8 targetChain_,
        address wrappedToken_,
        uint256 amount_,
        bytes calldata receiver_
    ) public override payable {
        _setupProxyPayment(feeToken_, wrappedToken_, amount_);
        IRouterDiamond(routerAddress).burnAndTransfer(targetChain_, wrappedToken_, amount_, receiver_);
        emit ProxyBurnAndTransfer(feeToken_, targetChain_, wrappedToken_, amount_, receiver_);
    }

    /**
     *  @notice Burns `amount` of `wrappedToken` using an EIP-2612 permit and initializes a bridging transaction to the original chain
     *  @param feeToken_ Token used to pay the fee
     *  @param targetChain_ The target chain for the bridging operation
     *  @param wrappedToken_ The address of the wrapped token to burn
     *  @param amount_ The amount of `wrappedToken` to burn
     *  @param receiver_ The receiving address in the original chain for this wrapped token
     *  @param deadline_ The deadline of the provided permit
     *  @param v_ The recovery id of the permit's ECDSA signature
     *  @param r_ The first output of the permit's ECDSA signature
     *  @param s_ The second output of the permit's ECDSA signature
     */
    function burnAndTransferWithPermit(
        address feeToken_,
        uint8 targetChain_,
        address wrappedToken_,
        uint256 amount_,
        bytes calldata receiver_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external override payable {
        IERC2612Permit(wrappedToken_).permit(msg.sender, address(this), amount_, deadline_, v_, r_, s_);
        burnAndTransfer(feeToken_, targetChain_, wrappedToken_, amount_, receiver_);
    }

    /**
    * @dev Invoked by the router when unlocking tokens
    * Overriden so unlocking automatically unwraps to native currency
    */
    function transfer(address recipient_, uint256 amount_) public override returns (bool) {
        bool success = false;

        if (msg.sender == routerAddress) {
            bytes memory returndata;

            _burn(msg.sender, amount_);
            (success, returndata) = recipient_.call{value: amount_}("");
            require(success, string(returndata));
        }

        return success;
    }

    /**
     *  @notice Get the ERC20 decimal count
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     *  @notice Send contract's tokens to the owner's address
     *  @param tokenAddress_ The token we want to claim
     *  @dev In case we want to take out the (w)ALBT
     */
    function claimTokens(address tokenAddress_) external override onlyOwner {
        uint256 amount = IERC20(tokenAddress_).balanceOf(address(this));
        IERC20(tokenAddress_).safeTransfer(owner(), amount);
        emit TokensClaimed(tokenAddress_, amount);
    }

    /**
     *  @notice Send the contract's currency to the owner's address
     *  @dev In case we want to replace the RouterProxy contract
     */
    function claimCurrency() external override onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, bytes memory returndata) = owner().call{value: amount}("");
        require(success, string(returndata));

        emit CurrencyClaimed(amount);
    }

    /**
     *  @notice Loads the bridge with native currency
     *  @dev Usable when you add a pre-existing WrappedToken contract for native currency
     */
    function bridgeAirdrop() external override payable onlyOwner {
        require(msg.value > 0, "Expected funds");
        _mint(routerAddress, msg.value);
        emit BridgeAirdrop(msg.value);
    }

}
