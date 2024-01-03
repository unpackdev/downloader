/**
 *Submitted for verification at polygonscan.com on 2022-12-07
 */

// SPDX-License-Identifier: MIT
// File: Donations.sol

pragma solidity ^0.8.17;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) ||
                (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Donations is Initializable {
    using SafeMath for uint;
    address public admin;
    address public VITreasury;
    uint256 public VIRoyalty;
    uint256 public minEthDonation;

    purchaseData[] allPurchases;
    rePurchaseData[] allRePurchases;

    mapping(address => purchaseData[]) userPurchases;
    mapping(address => rePurchaseData[]) userRePurchases;

    event purchaseNft(purchaseData _data);
    event Withdraw(address to, uint256 amount);

    struct purchaseData {
        uint timestamp;
        address buyer;
        address beneficiary;
        uint donation;
        uint tokenId;
        string contractHash;
        string buyerCsprWallet;
    }

    struct rePurchaseData {
        uint timestamp;
        address buyer;
        address beneficiary;
        uint donation;
        address artist;
        uint artist_spercentage;
        uint tokenId;
        string contrachHash;
        string buyerCsprWallet;
    }

    function initialize(address _treasury) public initializer {
        minEthDonation = 0.001 ether;
        admin = msg.sender;
        VITreasury = _treasury;
        VIRoyalty = 2;
    }

    // constructor(address _treasury) {
    //     admin = msg.sender;
    //     VITreasury = _treasury;
    //     VIRoyalty = 2;
    // }

    modifier onlyOwner() {
        require(msg.sender == admin, "VINFTS: NOT AUTHORIZED");
        _;
    }

    // GETTER FUNCTIONS
    function getUserPurchases(
        address _doner
    ) public view returns (purchaseData[] memory) {
        return userPurchases[_doner];
    }

    function getUserRePurchases(
        address _doner
    ) public view returns (rePurchaseData[] memory) {
        return userRePurchases[_doner];
    }

    function getAllPurchases() public view returns (purchaseData[] memory) {
        return allPurchases;
    }

    function getAllRePurchases() public view returns (rePurchaseData[] memory) {
        return allRePurchases;
    }

    // SETTER FUNCTIONS
    // function to change VINFTS treasury wallet;
    function changeTreasury(address _treasury) public onlyOwner {
        VITreasury = _treasury;
    }

    // function to change royalty sent to VITreasuty wallet;
    function changeRoyalty(uint _royalty) public onlyOwner {
        // if you want 2% percent, you should set "_royalty" to be 2;
        VIRoyalty = _royalty;
    }

    function purchaseToken(
        address _beneficiary,
        address _owner,
        uint _ownerPercentage,
        uint _tokenId,
        string memory _contractHash,
        string memory _buyerCSPRWallet
    ) public payable {
        //uint _toBeneficiary = msg.value.mul(100-VIRoyalty-_ownerPercentage).div(100); // calculate amount will be sent to beneficiary;
        uint _toTreasury = msg.value.mul(VIRoyalty).div(100);
        uint _toBeneficiary = (msg.value - _toTreasury)
            .mul(100 - _ownerPercentage)
            .div(100);
        uint _toOwner = (msg.value - _toTreasury).mul(_ownerPercentage).div(
            100
        );
        uint _transferCost = tx.gasprice.mul(2300); // calculate eth transfer cost;

        require(
            _toBeneficiary >= minEthDonation + _transferCost,
            "VINFTS: INSUFFICIENT AMOUNT FOR DONATION"
        );

        payable(_beneficiary).transfer(_toBeneficiary);
        payable(VITreasury).transfer(_toTreasury);
        payable(_owner).transfer(_toOwner);

        _savePurchaseData(
            _beneficiary,
            _tokenId,
            _contractHash,
            _buyerCSPRWallet
        );
    }

    function _savePurchaseData(
        address _beneficiary,
        uint _tokenId,
        string memory _contractHash,
        string memory _buyerCSPRWallet
    ) internal {
        purchaseData memory entry = purchaseData(
            block.timestamp,
            msg.sender,
            _beneficiary,
            msg.value,
            _tokenId,
            _contractHash,
            _buyerCSPRWallet
        );
        allPurchases.push(entry);
        userPurchases[msg.sender].push(entry);
        emit purchaseNft(entry);
    }

    function _saveRePurchaseData(
        address _beneficiary,
        address _owner,
        uint _ownerPercentage,
        uint _tokenId,
        string memory _contractHash,
        string memory _buyerCSPRWallet
    ) internal {
        rePurchaseData memory entry = rePurchaseData(
            block.timestamp,
            msg.sender,
            _beneficiary,
            msg.value,
            _owner,
            _ownerPercentage,
            _tokenId,
            _contractHash,
            _buyerCSPRWallet
        );
        allRePurchases.push(entry);
        userRePurchases[msg.sender].push(entry);
    }

    function _isApproved(
        address _erc20,
        uint _amount
    ) internal view returns (bool) {
        uint _allowed = IERC20(_erc20).allowance(msg.sender, address(this));
        return _allowed >= _amount;
    }

    function _calcAmounts(
        uint _amount,
        uint _ownerPercentage
    ) internal view returns (uint, uint, uint) {
        uint _toTreasury = _amount.mul(VIRoyalty).div(100);
        uint _toBeneficiary = (_amount - _toTreasury)
            .mul(100 - _ownerPercentage)
            .div(100);
        uint _toOwner = (_amount - _toTreasury).mul(_ownerPercentage).div(100);

        return (_toTreasury, _toBeneficiary, _toOwner);
    }

    function puchraseTokenWithERC20(
        address _ERC20Address,
        uint _tokenAmount,
        address _beneficiary,
        address _owner,
        uint _ownerPercentage,
        uint _tokenId,
        string memory _contractHash,
        string memory _buyerCSPRWallet
    ) public {
        bool isApproved = _isApproved(_ERC20Address, _tokenAmount);
        require(isApproved, "DONATIONS: NO ENOUGH TOKEN ALLOWANCE");
        (uint _toTreasury, uint _toBeneficiary, uint _toOwner) = _calcAmounts(
            _tokenAmount,
            _ownerPercentage
        );

        IERC20(_ERC20Address).transferFrom(msg.sender, VITreasury, _toTreasury);
        IERC20(_ERC20Address).transferFrom(
            msg.sender,
            _beneficiary,
            _toBeneficiary
        );
        IERC20(_ERC20Address).transferFrom(msg.sender, _owner, _toOwner);

        _savePurchaseData(
            _beneficiary,
            _tokenId,
            _contractHash,
            _buyerCSPRWallet
        );
    }

    function rePurchaseToken(
        address _beneficiary,
        address _owner,
        uint _ownerPercentage,
        uint _tokenId,
        string memory _contractHash,
        string memory _buyerCSPRWallet
    ) public payable {
        //uint _toBeneficiary = msg.value.mul(100-VIRoyalty-_ownerPercentage).div(100); // calculate amount will be sent to beneficiary;
        (uint _toTreasury, uint _toBeneficiary, uint _toOwner) = _calcAmounts(
            msg.value,
            _ownerPercentage
        );
        uint _transferCost = tx.gasprice.mul(2300); // calculate eth transfer cost;

        require(
            _toBeneficiary >= minEthDonation + _transferCost,
            "VINFTS: INSUFFICIENT AMOUNT FOR DONATION"
        );

        payable(_beneficiary).transfer(_toBeneficiary);
        payable(VITreasury).transfer(_toTreasury);
        payable(_owner).transfer(_toOwner);

        _saveRePurchaseData(
            _beneficiary,
            _owner,
            _ownerPercentage,
            _tokenId,
            _contractHash,
            _buyerCSPRWallet
        );
    }

    /**
     * @notice withdraw tokens from the contract by admin wallet only
     * @param to wallet address
     */
    function emergencyWithdraw(address payable to) external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "zero amount");
        to.transfer(amount);
        emit Withdraw(to, amount);
    }

    receive() external payable {}
}
