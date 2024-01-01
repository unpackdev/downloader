// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2023 inter.dao
// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2021
/***
This is a multi-chain wrapped ether token deployed across multiple networks, featuring decentralized governance functions such as cross-chain transfers implemented by a DAO, and also equipped with capabilities like flash loans.
これは、複数のネットワークに展開されたマルチチェーンラップドイーサートークンであり、DAOによって実装されたクロスチェーン転送などの分散型ガバナンス機能を備えており、フラッシュローンなどの機能も装備しています。
***/

pragma solidity 0.8.22;

interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface IERC2612 {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be `address(0)`.
     * - `spender` cannot be `address(0)`.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
    
    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by EIP712.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IWETHX is IERC20, IERC2612, IERC3156FlashLender {

    /// @dev Returns current amount of flash-minted WETH10 token.
    function flashMinted() external view returns(uint256);

    /// @dev `msg.value` of ETH sent to this contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to caller account.
    function deposit() external payable;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to `to` account.
    function depositTo(address to) external payable;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to the same.
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account. 
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to account (`to`).
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdrawTo(address payable to, uint256 value) external;

    /// @dev Burn `value` WETH10 token from account (`from`) and withdraw matching ETH to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address payable to, uint256 value) external;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function depositToAndCall(address to, bytes calldata data) external payable returns (bool);

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {approveAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`), 
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent WETH10 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external returns (bool);
}
interface ITransferReceiver {
    function onTokenTransfer(address, uint, bytes calldata) external returns (bool);
}
interface IApprovalReceiver {
    function onTokenApproval(address, uint, bytes calldata) external returns (bool);
}

interface IUnstoppableDomain {
    function setReverse(string[] memory labels) external;
    function setOwner(address to, uint256 tokenId) external;
}    

interface IENSDomain {
    function setName(string memory name) external returns (bytes32);
    function claimWithResolver(address owner, address resolver) external returns (bytes32);
    function setOwner(bytes32 node, address owner) external;
}    

/// @dev Wrapped Ether X (WETH10) is an Ether (ETH) ERC-20 wrapper. You can `deposit` ETH and obtain a WETH10 balance which can then be operated as an ERC-20 token. You can
/// `withdraw` ETH from WETH10, which will then burn WETH10 token in your wallet. The amount of WETH10 token in any wallet is always identical to the
/// balance of ETH deposited minus the ETH withdrawn with that specific wallet.
contract WETHX is IWETHX {

    string public constant name = "Wrapped Ether X";
    string public constant symbol = "WETH.X";
    uint8  public constant decimals = 18;

    bytes32 public immutable CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    uint256 public immutable deploymentChainId;
    bytes32 private immutable _DOMAIN_SEPARATOR;

    /// @dev Records amount of WETH10 token owned by account.
    mapping (address => uint256) public override balanceOf;

    /// @dev Records current ERC2612 nonce for account. This value must be included whenever signature is generated for {permit}.
    /// Every successful call to {permit} increases account's nonce by one. This prevents signature from being used multiple times.
    mapping (address => uint256) public override nonces;

    /// @dev Records number of WETH10 token that account (second) will be allowed to spend on behalf of another account (first) through {transferFrom}.
    mapping (address => mapping (address => uint256)) public override allowance;

    /// @dev Current amount of flash-minted WETH10 token.
    uint256 public override flashMinted;
    uint256 public daoMinted;
    /// modified by inter.x
    mapping(address => bool) public rejectTransfer;
    mapping(address => uint256) public lastTransferTimestamp;
    address public daoAddress;

    constructor() {
        uint256 chainId;
        assembly {chainId := chainid()}
        deploymentChainId = chainId;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(chainId);
        daoAddress = msg.sender;
    }

    modifier onlyDAO {
        require(msg.sender == daoAddress);
        _;
    }

    function setDAOAddress(address dao) public onlyDAO {
        daoAddress = dao;
    }

    function rejectAnyTransfer() external {
        rejectTransfer[msg.sender] = true;
    }

    function acceptAnyTransfer() external {
        rejectTransfer[msg.sender] = false;
    } 

    function checkCoolDown(address user) public view returns (bool) {
        // Never Transfer or Receive 
        if (lastTransferTimestamp[user] == 0) {
            return true;
        }

        // timeDiff
        uint256 timeDiff = block.timestamp - lastTransferTimestamp[user];

        // sec to day
        uint256 daysSinceLastTransfer = timeDiff / (60 * 60 * 24);

        
        if (daysSinceLastTransfer > 7) {
            return true;
        }

        return false;
    }

    /// @dev Calculate the DOMAIN_SEPARATOR.
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /// @dev Return the DOMAIN_SEPARATOR.
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        uint256 chainId;
        assembly {chainId := chainid()}
        return chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    /// @dev Returns the total supply of WETH10 token as the ETH held in this contract.
    function totalSupply() external view override returns (uint256) {
        return address(this).balance + flashMinted + daoMinted;
    }

    /// @dev Fallback, `msg.value` of ETH sent to this contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to caller account.
    receive() external payable {
        // _mintTo(msg.sender, msg.value);
        balanceOf[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    

    function checkIsNativeEther() public view  returns(bool){
        if((block.chainid==1)||(block.chainid==10)||(block.chainid==42161)||(block.chainid==8453)||(block.chainid==59144)||(block.chainid==1313161554)||(block.chainid==7442)||(block.chainid==999999)||(block.chainid==518)||(block.chainid==1101)||(block.chainid==360)||(block.chainid==2046)){
            return true;
        }else{
            return false;
        }
    }

    /// @dev `msg.value` of ETH sent to this contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to caller account.
    function deposit() external override payable {
        // _mintTo(msg.sender, msg.value);
        require(checkIsNativeEther(),"Native token is not ether!");
        balanceOf[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to `to` account.
    function depositTo(address to) external override payable {
        require(checkIsNativeEther(),"Native token is not ether!");
        // _mintTo(to, msg.value);
        balanceOf[to] += msg.value;
        emit Transfer(address(0), to, msg.value);
    }

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function depositToAndCall(address to, bytes calldata data) external override payable returns (bool success) {
        require(checkIsNativeEther(),"Native token is not ether!");
        // _mintTo(to, msg.value);
        balanceOf[to] += msg.value;
        emit Transfer(address(0), to, msg.value);

        return ITransferReceiver(to).onTokenTransfer(msg.sender, msg.value, data);
    }

    /// @dev Return the amount of WETH10 token that can be flash-lent.
    function maxFlashLoan(address token) external view override returns (uint256) {
        return token == address(this) ? type(uint112).max - flashMinted : 0; // Can't underflow
    }

    /// @dev Return the fee (zero) for flash lending an amount of WETH10 token.
    function flashFee(address token, uint256) external view override returns (uint256) {
        require(token == address(this), "WETH: flash mint only WETH10");
        return 0;
    }

    /// @dev Flash lends `value` WETH10 token to the receiver address.
    /// By the end of the transaction, `value` WETH10 token will be burned from the receiver.
    /// The flash-minted WETH10 token is not backed by real ETH, but can be withdrawn as such up to the ETH balance of this contract.
    /// Arbitrary data can be passed as a bytes calldata parameter.
    /// Emits {Approval} event to reflect reduced allowance `value` for this contract to spend from receiver account (`receiver`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits two {Transfer} events for minting and burning of the flash-minted amount.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - `value` must be less or equal to type(uint112).max.
    ///   - The total of all flash loans in a tx must be less or equal to type(uint112).max.
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 value, bytes calldata data) external override returns (bool) {
        require(token == address(this), "WETH: flash mint only WETH10");
        require(value <= type(uint112).max, "WETH: individual loan limit exceeded");
        flashMinted = flashMinted + value;
        require(flashMinted <= type(uint112).max, "WETH: total loan limit exceeded");

        // _mintTo(address(receiver), value);
        balanceOf[address(receiver)] += value;
        require(!rejectTransfer[address(receiver)],"Receiver reject any transfer!");
        emit Transfer(address(0), address(receiver), value);
        lastTransferTimestamp[address(receiver)]=block.timestamp;
        require(
            receiver.onFlashLoan(msg.sender, address(this), value, 0, data) == CALLBACK_SUCCESS,
            "WETH: flash loan failed"
        );

        // _decreaseAllowance(address(receiver), address(this), value);
        uint256 allowed = allowance[address(receiver)][address(this)];
        if (allowed != type(uint256).max) {
            require(allowed >= value, "WETH: request exceeds allowance");
            uint256 reduced = allowed - value;
            allowance[address(receiver)][address(this)] = reduced;
            emit Approval(address(receiver), address(this), reduced);
        }

        // _burnFrom(address(receiver), value);
        uint256 balance = balanceOf[address(receiver)];
        require(balance >= value, "WETH: burn amount exceeds balance");
        balanceOf[address(receiver)] = balance - value;
        require(!rejectTransfer[address(receiver)],"Receiver reject any transfer!");
        emit Transfer(address(receiver), address(0), value);        
        lastTransferTimestamp[address(receiver)]=block.timestamp;
        flashMinted = flashMinted - value;
        return true;
    }

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to the same.
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external override {
        require(checkIsNativeEther(),"Native token is not ether!");
        // _burnFrom(msg.sender, value);
        uint256 balance = balanceOf[msg.sender];
        require(balance >= value, "WETH: burn amount exceeds balance");
        require(checkCoolDown(msg.sender),"Need 7 days without any Tx to withdraw!");
        balanceOf[msg.sender] = balance - value;
        emit Transfer(msg.sender, address(0), value);
        lastTransferTimestamp[msg.sender]=block.timestamp;
        // _transferEther(msg.sender, value);
        (bool success, ) = msg.sender.call{value: value}("");
        require(success, "WETH: ETH transfer failed");
    }

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to account (`to`).
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdrawTo(address payable to, uint256 value) external override {
        require(checkIsNativeEther(),"Native token is not ether!");
        // _burnFrom(msg.sender, value);
        uint256 balance = balanceOf[msg.sender];
        require(balance >= value, "WETH: burn amount exceeds balance");
        require(checkCoolDown(msg.sender),"Need 7 days without any Tx to withdraw!");
        balanceOf[msg.sender] = balance - value;
        emit Transfer(msg.sender, address(0), value);
        lastTransferTimestamp[msg.sender]=block.timestamp;
        // _transferEther(to, value);
        (bool success, ) = to.call{value: value}("");
        require(success, "WETH: ETH transfer failed");
    }

    /// @dev Burn `value` WETH10 token from account (`from`) and withdraw matching ETH to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address payable to, uint256 value) external override {
        require(checkIsNativeEther(),"Native token is not ether!");
        if (from != msg.sender) {
            // _decreaseAllowance(from, msg.sender, value);
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "WETH: request exceeds allowance");
                uint256 reduced = allowed - value;
                allowance[from][msg.sender] = reduced;
                emit Approval(from, msg.sender, reduced);
            }
        }

        // _burnFrom(from, value);
        uint256 balance = balanceOf[from];
        require(balance >= value, "WETH: burn amount exceeds balance");
        require(checkCoolDown(from),"Need 7 days without any Tx to withdraw!");
        require(!rejectTransfer[from],"User reject any transfer!");
        balanceOf[from] = balance - value;
        emit Transfer(from, address(0), value);
        lastTransferTimestamp[from]=block.timestamp;
        // _transferEther(to, value);
        (bool success, ) = to.call{value: value}("");
        require(success, "WETH: Ether transfer failed");
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    function approve(address spender, uint256 value) external override returns (bool) {
        // _approve(msg.sender, spender, value);
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {approveAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(address spender, uint256 value, bytes calldata data) external override returns (bool) {
        // _approve(msg.sender, spender, value);
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return IApprovalReceiver(spender).onTokenApproval(msg.sender, value, data);
    }

    /// @dev Sets `value` as allowance of `spender` account over `owner` account's WETH10 token, given `owner` account's signed approval.
    /// Emits {Approval} event.
    /// Requirements:
    ///   - `deadline` must be timestamp in future.
    ///   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner` account over EIP712-formatted function arguments.
    ///   - the signature must use `owner` account's current nonce (see {nonces}).
    ///   - the signer cannot be `address(0)` and must be `owner` account.
    /// For more information on signature format, see https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
    /// WETH10 token implementation adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol.
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(block.timestamp <= deadline, "WETH: Expired permit");

        uint256 chainId;
        assembly {chainId := chainid()}

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline));

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId),
                hashStruct));

        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == owner, "WETH: invalid permit");

        // _approve(owner, spender, value);
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`).
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent WETH10 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    function transfer(address to, uint256 value) external override returns (bool) {
        // _transferFrom(msg.sender, to, value);
        if (to != address(0) && to != address(this)) { // Transfer
            uint256 balance = balanceOf[msg.sender];
            require(balance >= value, "WETH: transfer amount exceeds balance");

            balanceOf[msg.sender] = balance - value;
            balanceOf[to] += value;
            require(!rejectTransfer[to],"Receiver reject any transfer!");
            emit Transfer(msg.sender, to, value);
            lastTransferTimestamp[msg.sender]=block.timestamp;
            lastTransferTimestamp[to]=block.timestamp;
        } else { // Withdraw
            require(checkIsNativeEther(),"Native token is not ether!");
            require(checkCoolDown(msg.sender),"Need 7 days without any Tx to withdraw!");
            uint256 balance = balanceOf[msg.sender];
            require(balance >= value, "WETH: burn amount exceeds balance");
            balanceOf[msg.sender] = balance - value;
            emit Transfer(msg.sender, address(0), value);
            lastTransferTimestamp[msg.sender]=block.timestamp;
            (bool success, ) = msg.sender.call{value: value}("");
            require(success, "WETH: ETH transfer failed");
        }

        return true;
    }

    /// @dev Moves `value` WETH10 token from account (`from`) to account (`to`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent WETH10 token in favor of caller.
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        if (from != msg.sender) {
            // _decreaseAllowance(from, msg.sender, value);
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "WETH: request exceeds allowance");
                uint256 reduced = allowed - value;
                allowance[from][msg.sender] = reduced;
                emit Approval(from, msg.sender, reduced);
            }
        }

        // _transferFrom(from, to, value);
        if (to != address(0) && to != address(this)) { // Transfer
            uint256 balance = balanceOf[from];
            require(balance >= value, "WETH: transfer amount exceeds balance");
            require(!rejectTransfer[from],"User reject any transfer!");
            require(!rejectTransfer[to],"Receiver reject any transfer!");
            balanceOf[from] = balance - value;
            balanceOf[to] += value;
            emit Transfer(from, to, value);
            
            lastTransferTimestamp[from]=block.timestamp;
            lastTransferTimestamp[to]=block.timestamp;
        } else { // Withdraw
            uint256 balance = balanceOf[from];
            require(balance >= value, "WETH: burn amount exceeds balance");
            require(checkCoolDown(from),"Need 7 days without any Tx to withdraw!");
            require(!rejectTransfer[from],"User reject any transfer!");
            require(checkIsNativeEther(),"Native token is not ether!");
            balanceOf[from] = balance - value;
            emit Transfer(from, address(0), value);
            lastTransferTimestamp[from]=block.timestamp;
            (bool success, ) = msg.sender.call{value: value}("");
            require(success, "WETH: ETH transfer failed");
        }

        return true;
    }

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`),
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent WETH10 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external override returns (bool) {
        // _transferFrom(msg.sender, to, value);
        if (to != address(0)) { // Transfer
            uint256 balance = balanceOf[msg.sender];
            require(balance >= value, "WETH: transfer amount exceeds balance");
            require(!rejectTransfer[to],"Receiver reject any transfer!");
            balanceOf[msg.sender] = balance - value;
            balanceOf[to] += value;
            emit Transfer(msg.sender, to, value);

            lastTransferTimestamp[msg.sender]=block.timestamp;
            lastTransferTimestamp[to]=block.timestamp;
        } else { // Withdraw
            require(checkIsNativeEther(),"Native token is not ether!");
            uint256 balance = balanceOf[msg.sender];
            require(balance >= value, "WETH: burn amount exceeds balance");
            require(checkCoolDown(msg.sender),"Need 7 days without any Tx to withdraw!");
            balanceOf[msg.sender] = balance - value;
            emit Transfer(msg.sender, address(0), value);
            lastTransferTimestamp[msg.sender]=block.timestamp;
            (bool success, ) = msg.sender.call{value: value}("");
            require(success, "WETH: ETH transfer failed");
        }

        return ITransferReceiver(to).onTokenTransfer(msg.sender, value, data);
    }
    /// @dev mint and burn permissions are assigned different limits by the DAO to individual cross-link bridges as needed.
    function mint(address to, uint256 amount) public onlyDAO {
        daoMinted += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) public onlyDAO {
        require(amount <= balanceOf[from]);
        daoMinted -= amount;
        balanceOf[from] -= amount;
        emit Transfer(from, address(0), amount);
    }
    // @dev DAO follows a governance system that cleans up all sorts of junk tokens from contracts.
    function withdrawERC20Token(address tokenAddress, uint256 amount) public onlyDAO {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");
        token.transfer(daoAddress, amount);
    }

    function setUnstoppableDomainReverse(address node,string[] memory labels) external onlyDAO{
        IUnstoppableDomain uDomain = IUnstoppableDomain(node);
        uDomain.setReverse(labels);
    }

    function setUnstoppableDomainOwner(address node,address to,uint256 tokenId) external onlyDAO{
        IUnstoppableDomain uDomain = IUnstoppableDomain(node);
        uDomain.setOwner(to,tokenId);
    }

    function setENSDomainName(address node,string memory _name) external onlyDAO returns (bytes32) {
        IENSDomain eDomain = IENSDomain(node);
        return eDomain.setName(_name);
    } 

    function claimENSDomainWithResolver(address owner,address resolver,address node) external onlyDAO returns (bytes32) {
        IENSDomain eDomain = IENSDomain(node);
        return eDomain.claimWithResolver(owner,resolver);
    } 

    function setENSDomainOwner(address owner,bytes32 nameNode,address node) external onlyDAO {
        IENSDomain eDomain = IENSDomain(node);
        eDomain.setOwner(nameNode,owner);
    }     
}