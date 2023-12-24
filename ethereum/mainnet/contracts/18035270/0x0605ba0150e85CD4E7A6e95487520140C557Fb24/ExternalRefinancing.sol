// SPDX-License-Identifier: BUSL-1.1

/**
 *  █████╗ ███████╗████████╗ █████╗ ██████╗ ██╗ █████╗
 * ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║██╔══██╗
 * ███████║███████╗   ██║   ███████║██████╔╝██║███████║
 * ██╔══██║╚════██║   ██║   ██╔══██║██╔══██╗██║██╔══██║
 * ██║  ██║███████║   ██║   ██║  ██║██║  ██║██║██║  ██║
 * ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
 *
 * Astaria Labs, Inc
 */

pragma solidity =0.8.17;

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
  event Transfer(address indexed from, address indexed to, uint256 indexed id);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 indexed id
  );

  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function tokenURI(uint256 id) external view returns (string memory);

  function ownerOf(uint256 id) external view returns (address owner);

  function balanceOf(address owner) external view returns (uint256 balance);

  function approve(address spender, uint256 id) external;

  function setApprovalForAll(address operator, bool approved) external;

  function transferFrom(address from, address to, uint256 id) external;

  function safeTransferFrom(address from, address to, uint256 id) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    bytes calldata data
  ) external;
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
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
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

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
      functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return
      verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
      functionStaticCall(target, data, "Address: low-level static call failed");
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
      verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
      verifyCallResultFromTarget(target, success, returndata, errorMessage);
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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
  uint256 private constant INITIALIZER_SLOT =
    uint256(
      uint256(keccak256("core.astaria.xyz.initializer.storage.location")) - 1
    );

  struct InitializerState {
    uint8 _initialized;
    bool _initializing;
  }

  /**
   * @dev Triggered when the contract has been initialized or reinitialized.
   */
  event Initialized(uint8 version);

  function _getInitializerSlot()
    private
    view
    returns (InitializerState storage state)
  {
    uint256 slot = INITIALIZER_SLOT;
    assembly {
      state.slot := slot
    }
  }

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
   * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
   */
  modifier initializer() {
    InitializerState storage s = _getInitializerSlot();
    bool isTopLevelCall = !s._initializing;
    require(
      (isTopLevelCall && s._initialized < 1) ||
        (!Address.isContract(address(this)) && s._initialized == 1),
      "Initializable: contract is already initialized"
    );
    s._initialized = 1;
    if (isTopLevelCall) {
      s._initializing = true;
    }
    _;
    if (isTopLevelCall) {
      s._initializing = false;
      emit Initialized(1);
    }
  }

  /**
   * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
   * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
   * used to initialize parent contracts.
   *
   * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
   * initialization step. This is essential to configure modules that are added through upgrades and that require
   * initialization.
   *
   * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
   * a contract, executing them in the right order is up to the developer or operator.
   */
  modifier reinitializer(uint8 version) {
    InitializerState storage s = _getInitializerSlot();
    require(
      !s._initializing && s._initialized < version,
      "Initializable: contract is already initialized"
    );
    s._initialized = version;
    s._initializing = true;
    _;
    s._initializing = false;
    emit Initialized(version);
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
   * {initializer} and {reinitializer} modifiers, directly or indirectly.
   */
  modifier onlyInitializing() {
    InitializerState storage s = _getInitializerSlot();
    require(s._initializing, "Initializable: contract is not initializing");
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
   * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
   * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
   * through proxies.
   */
  function _disableInitializers() internal virtual {
    InitializerState storage s = _getInitializerSlot();
    require(!s._initializing, "Initializable: contract is initializing");
    if (s._initialized < type(uint8).max) {
      s._initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 is Initializable, IERC721 {
  /* //////////////////////////////////////////////////////////////
      METADATA STORAGE/LOGIC
    ////////////////////////////////////////////////////////////// */

  uint256 private constant ERC721_SLOT =
    uint256(keccak256("xyz.astaria.ERC721.storage.location")) - 1;
  struct ERC721Storage {
    string name;
    string symbol;
    mapping(uint256 => address) _ownerOf;
    mapping(address => uint256) _balanceOf;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    return _loadERC721Slot().getApproved[tokenId];
  }

  function isApprovedForAll(
    address owner,
    address operator
  ) public view returns (bool) {
    return _loadERC721Slot().isApprovedForAll[owner][operator];
  }

  function tokenURI(uint256 id) external view virtual returns (string memory);

  /* //////////////////////////////////////////////////////////////
      ERC721 BALANCE/OWNER STORAGE
    ////////////////////////////////////////////////////////////// */

  function _loadERC721Slot() internal pure returns (ERC721Storage storage s) {
    uint256 slot = ERC721_SLOT;

    assembly {
      s.slot := slot
    }
  }

  function ownerOf(uint256 id) public view virtual returns (address owner) {
    require(
      (owner = _loadERC721Slot()._ownerOf[id]) != address(0),
      "NOT_MINTED"
    );
  }

  function balanceOf(address owner) public view virtual returns (uint256) {
    require(owner != address(0), "ZERO_ADDRESS");

    return _loadERC721Slot()._balanceOf[owner];
  }

  /* //////////////////////////////////////////////////////////////
    INITIALIZATION LOGIC
    ////////////////////////////////////////////////////////////// */

  function __initERC721(string memory _name, string memory _symbol) internal {
    ERC721Storage storage s = _loadERC721Slot();
    s.name = _name;
    s.symbol = _symbol;
  }

  /* //////////////////////////////////////////////////////////////
    ERC721 LOGIC
    ////////////////////////////////////////////////////////////// */

  function name() public view returns (string memory) {
    return _loadERC721Slot().name;
  }

  function symbol() public view returns (string memory) {
    return _loadERC721Slot().symbol;
  }

  function approve(address spender, uint256 id) external virtual {
    ERC721Storage storage s = _loadERC721Slot();
    address owner = s._ownerOf[id];
    require(
      msg.sender == owner || s.isApprovedForAll[owner][msg.sender],
      "NOT_AUTHORIZED"
    );

    s.getApproved[id] = spender;

    emit Approval(owner, spender, id);
  }

  function setApprovalForAll(address operator, bool approved) external virtual {
    _loadERC721Slot().isApprovedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public virtual override(IERC721) {
    ERC721Storage storage s = _loadERC721Slot();

    require(from == s._ownerOf[id], "WRONG_FROM");

    require(to != address(0), "INVALID_RECIPIENT");

    require(
      msg.sender == from ||
        s.isApprovedForAll[from][msg.sender] ||
        msg.sender == s.getApproved[id],
      "NOT_AUTHORIZED"
    );
    _transfer(from, to, id);
  }

  function _transfer(address from, address to, uint256 id) internal {
    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    ERC721Storage storage s = _loadERC721Slot();

    unchecked {
      s._balanceOf[from]--;

      s._balanceOf[to]++;
    }

    s._ownerOf[id] = to;

    delete s.getApproved[id];

    emit Transfer(from, to, id);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) external virtual {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    bytes calldata data
  ) external override(IERC721) {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  /* //////////////////////////////////////////////////////////////
    ERC165 LOGIC
    ////////////////////////////////////////////////////////////// */

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual returns (bool) {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
  }

  /* //////////////////////////////////////////////////////////////
    INTERNAL MINT/BURN LOGIC
    ////////////////////////////////////////////////////////////// */

  function _mint(address to, uint256 id) internal virtual {
    require(to != address(0), "INVALID_RECIPIENT");
    ERC721Storage storage s = _loadERC721Slot();
    require(s._ownerOf[id] == address(0), "ALREADY_MINTED");

    // Counter overflow is incredibly unrealistic.
    unchecked {
      s._balanceOf[to]++;
    }

    s._ownerOf[id] = to;

    emit Transfer(address(0), to, id);
  }

  function _burn(uint256 id) internal virtual {
    ERC721Storage storage s = _loadERC721Slot();

    address owner = s._ownerOf[id];

    require(owner != address(0), "NOT_MINTED");

    // Ownership check above ensures no underflow.
    unchecked {
      s._balanceOf[owner]--;
    }

    delete s._ownerOf[id];

    delete s.getApproved[id];

    emit Transfer(owner, address(0), id);
  }

  /* //////////////////////////////////////////////////////////////
    INTERNAL SAFE MINT LOGIC
    ////////////////////////////////////////////////////////////// */

  function _safeMint(address to, uint256 id) internal virtual {
    _mint(to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(
          msg.sender,
          address(0),
          id,
          ""
        ) ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  function _safeMint(
    address to,
    uint256 id,
    bytes memory data
  ) internal virtual {
    _mint(to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(
          msg.sender,
          address(0),
          id,
          data
        ) ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return ERC721TokenReceiver.onERC721Received.selector;
  }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// Inspired by Aave Protocol's IFlashLoanReceiver.

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `to`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address to, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

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
   * @dev Moves `amount` tokens from `from` to `to` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

interface IFlashLoanRecipient {
  /**
   * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
   *
   * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
   * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
   * Vault, or else the entire flash loan will revert.
   *
   * `userData` is the same value passed in the `IVault.flashLoan` call.
   */
  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external;
}

interface IBalancerVault {
  function flashLoan(
    IFlashLoanRecipient recipient,
    IERC20[] memory tokens,
    uint256[] memory amounts,
    bytes memory userData
  ) external;
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
  /**
   * @dev Returns the total amount of tokens stored by the contract.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
   * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
   */
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  ) external view returns (uint256);

  /**
   * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
   * Use along with {totalSupply} to enumerate all tokens.
   */
  function tokenByIndex(uint256 index) external view returns (uint256);
}

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external;
}

/**
 * @title LendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Bend Governance
 * @author Bend
 **/
interface ILendPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendPoolUpdated(address indexed newAddress, bytes encodedCallData);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendPoolConfiguratorUpdated(
    address indexed newAddress,
    bytes encodedCallData
  );
  event ReserveOracleUpdated(address indexed newAddress);
  event NftOracleUpdated(address indexed newAddress);
  event LendPoolLoanUpdated(address indexed newAddress, bytes encodedCallData);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(
    bytes32 id,
    address indexed newAddress,
    bool hasProxy,
    bytes encodedCallData
  );
  event BNFTRegistryUpdated(address indexed newAddress);
  event IncentivesControllerUpdated(address indexed newAddress);
  event UIDataProviderUpdated(address indexed newAddress);
  event BendDataProviderUpdated(address indexed newAddress);
  event WalletBalanceProviderUpdated(address indexed newAddress);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(
    bytes32 id,
    address impl,
    bytes memory encodedCallData
  ) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendPool() external view returns (address);

  function setLendPoolImpl(address pool, bytes memory encodedCallData) external;

  function getLendPoolConfigurator() external view returns (address);

  function setLendPoolConfiguratorImpl(
    address configurator,
    bytes memory encodedCallData
  ) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getReserveOracle() external view returns (address);

  function setReserveOracle(address reserveOracle) external;

  function getNFTOracle() external view returns (address);

  function setNFTOracle(address nftOracle) external;

  function getLendPoolLoan() external view returns (address);

  function setLendPoolLoanImpl(
    address loan,
    bytes memory encodedCallData
  ) external;

  function getBNFTRegistry() external view returns (address);

  function setBNFTRegistry(address factory) external;

  function getIncentivesController() external view returns (address);

  function setIncentivesController(address controller) external;

  function getUIDataProvider() external view returns (address);

  function setUIDataProvider(address provider) external;

  function getBendDataProvider() external view returns (address);

  function setBendDataProvider(address provider) external;

  function getWalletBalanceProvider() external view returns (address);

  function setWalletBalanceProvider(address provider) external;
}

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address bTokenAddress;
    address debtTokenAddress;
    //address of the interest rate strategy
    address interestRateAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct NftData {
    //stores the nft configuration
    NftConfigurationMap configuration;
    //address of the bNFT contract
    address bNftAddress;
    //the id of the nft. Represents the position in the list of the active nfts
    uint8 id;
    uint256 maxSupply;
    uint256 maxTokenId;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct NftConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 56: NFT is active
    //bit 57: NFT is frozen
    uint256 data;
  }

  /**
   * @dev Enum describing the current state of a loan
   * State change flow:
   *  Created -> Active -> Repaid
   *                    -> Auction -> Defaulted
   */
  enum LoanState {
    // We need a default that is not 'Created' - this is the zero value
    None,
    // The loan data is stored, but not initiated yet.
    Created,
    // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
    Active,
    // The loan is in auction, higest price liquidator will got chance to claim it.
    Auction,
    // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
    Repaid,
    // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
    Defaulted
  }

  struct LoanData {
    //the id of the nft loan
    uint256 loanId;
    //the current state of the loan
    LoanState state;
    //address of borrower
    address borrower;
    //address of nft asset token
    address nftAsset;
    //the id of nft token
    uint256 nftTokenId;
    //address of reserve asset token
    address reserveAsset;
    //scaled borrow amount. Expressed in ray
    uint256 scaledAmount;
    //start time of first bid time
    uint256 bidStartTimestamp;
    //bidder address of higest bid
    address bidderAddress;
    //price of higest bid
    uint256 bidPrice;
    //borrow amount of loan
    uint256 bidBorrowAmount;
    //bidder address of first bid
    address firstBidderAddress;
  }

  struct ExecuteDepositParams {
    address initiator;
    address asset;
    uint256 amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteWithdrawParams {
    address initiator;
    address asset;
    uint256 amount;
    address to;
  }

  struct ExecuteBorrowParams {
    address initiator;
    address asset;
    uint256 amount;
    address nftAsset;
    uint256 nftTokenId;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteBatchBorrowParams {
    address initiator;
    address[] assets;
    uint256[] amounts;
    address[] nftAssets;
    uint256[] nftTokenIds;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteRepayParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
  }

  struct ExecuteBatchRepayParams {
    address initiator;
    address[] nftAssets;
    uint256[] nftTokenIds;
    uint256[] amounts;
  }

  struct ExecuteAuctionParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 bidPrice;
    address onBehalfOf;
  }

  struct ExecuteRedeemParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
    uint256 bidFine;
  }

  struct ExecuteLiquidateParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
  }

  struct ExecuteLendPoolStates {
    uint256 pauseStartTime;
    uint256 pauseDurationTime;
  }
}

interface ILendPool {
  /**
   * @dev Emitted on deposit()
   * @param user The address initiating the deposit
   * @param amount The amount deposited
   * @param reserve The address of the underlying asset of the reserve
   * @param onBehalfOf The beneficiary of the deposit, receiving the bTokens
   * @param referral The referral code used
   **/
  event Deposit(
    address user,
    address indexed reserve,
    uint256 amount,
    address indexed onBehalfOf,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param user The address initiating the withdrawal, owner of bTokens
   * @param reserve The address of the underlyng asset being withdrawn
   * @param amount The amount to be withdrawn
   * @param to Address that will receive the underlying
   **/
  event Withdraw(
    address indexed user,
    address indexed reserve,
    uint256 amount,
    address indexed to
  );

  /**
   * @dev Emitted on borrow() when loan needs to be opened
   * @param user The address of the user initiating the borrow(), receiving the funds
   * @param reserve The address of the underlying asset being borrowed
   * @param amount The amount borrowed out
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the loan
   * @param referral The referral code used
   **/
  event Borrow(
    address user,
    address indexed reserve,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address indexed onBehalfOf,
    uint256 borrowRate,
    uint256 loanId,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param user The address of the user initiating the repay(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param amount The amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param borrower The beneficiary of the repayment, getting his debt reduced
   * @param loanId The loan ID of the NFT loans
   **/
  event Repay(
    address user,
    address indexed reserve,
    uint256 amount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is auctioned.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param bidPrice The price of the underlying reserve given by the bidder
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the NFT
   * @param loanId The loan ID of the NFT loans
   **/
  event Auction(
    address user,
    address indexed reserve,
    uint256 bidPrice,
    address indexed nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted on redeem()
   * @param user The address of the user initiating the redeem(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param borrowAmount The borrow amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param loanId The loan ID of the NFT loans
   **/
  event Redeem(
    address user,
    address indexed reserve,
    uint256 borrowAmount,
    uint256 fineAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is liquidated.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param repayAmount The amount of reserve repaid by the liquidator
   * @param remainAmount The amount of reserve received by the borrower
   * @param loanId The loan ID of the NFT loans
   **/
  event Liquidate(
    address user,
    address indexed reserve,
    uint256 repayAmount,
    uint256 remainAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when the pause time is updated.
   */
  event PausedTimeUpdated(uint256 startTime, uint256 durationTime);

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendPool contract. The event is therefore replicated here so it
   * gets added to the LendPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying bTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 bUSDC
   * @param reserve The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the bTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of bTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address reserve,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent bTokens owned
   * E.g. User has 100 bUSDC, calls withdraw() and receives 100 USDC, burning the 100 bUSDC
   * @param reserve The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole bToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address reserve,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral
   * - E.g. User borrows 100 USDC, receiving the 100 USDC in his wallet
   *   and lock collateral asset in contract
   * @param reserveAsset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param onBehalfOf Address of the user who will receive the loan. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function borrow(
    address reserveAsset,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function batchBorrow(
    address[] calldata assets,
    uint256[] calldata amounts,
    address[] calldata nftAssets,
    uint256[] calldata nftTokenIds,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent loan owned
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay
   * @return The final amount repaid, loan is burned or not
   **/
  function repay(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) external returns (uint256, bool);

  function batchRepay(
    address[] calldata nftAssets,
    uint256[] calldata nftTokenIds,
    uint256[] calldata amounts
  ) external returns (uint256[] memory, bool[] memory);

  /**
   * @dev Function to auction a non-healthy position collateral-wise
   * - The caller (liquidator) want to buy collateral asset of the user getting liquidated
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param bidPrice The bid price of the liquidator want to buy the underlying NFT
   * @param onBehalfOf Address of the user who will get the underlying NFT, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of NFT
   *   is a different wallet
   **/
  function auction(
    address nftAsset,
    uint256 nftTokenId,
    uint256 bidPrice,
    address onBehalfOf
  ) external;

  /**
   * @notice Redeem a NFT loan which state is in Auction
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   **/
  function redeem(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 bidFine
  ) external returns (uint256);

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The caller (liquidator) buy collateral asset of the user getting liquidated, and receives
   *   the collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidate(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) external returns (uint256);

  /**
   * @dev Validates and finalizes an bToken transfer
   * - Only callable by the overlying bToken of the `asset`
   * @param asset The address of the underlying asset of the bToken
   * @param from The user from which the bTokens are transferred
   * @param to The user receiving the bTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The bToken balance of the `from` user before the transfer
   * @param balanceToBefore The bToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external view;

  function getReserveConfiguration(
    address asset
  ) external view returns (DataTypes.ReserveConfigurationMap memory);

  function getNftConfiguration(
    address asset
  ) external view returns (DataTypes.NftConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(
    address asset
  ) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(
    address asset
  ) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(
    address asset
  ) external view returns (DataTypes.ReserveData memory);

  function getReservesList() external view returns (address[] memory);

  function getNftData(
    address asset
  ) external view returns (DataTypes.NftData memory);

  /**
   * @dev Returns the loan data of the NFT
   * @param nftAsset The address of the NFT
   * @param reserveAsset The address of the Reserve
   * @return totalCollateralInETH the total collateral in ETH of the NFT
   * @return totalCollateralInReserve the total collateral in Reserve of the NFT
   * @return availableBorrowsInETH the borrowing power in ETH of the NFT
   * @return availableBorrowsInReserve the borrowing power in Reserve of the NFT
   * @return ltv the loan to value of the user
   * @return liquidationThreshold the liquidation threshold of the NFT
   * @return liquidationBonus the liquidation bonus of the NFT
   **/
  function getNftCollateralData(
    address nftAsset,
    address reserveAsset
  )
    external
    view
    returns (
      uint256 totalCollateralInETH,
      uint256 totalCollateralInReserve,
      uint256 availableBorrowsInETH,
      uint256 availableBorrowsInReserve,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus
    );

  /**
   * @dev Returns the debt data of the NFT
   * @param nftAsset The address of the NFT
   * @param nftTokenId The token id of the NFT
   * @return loanId the loan id of the NFT
   * @return reserveAsset the address of the Reserve
   * @return totalCollateral the total power of the NFT
   * @return totalDebt the total debt of the NFT
   * @return availableBorrows the borrowing power left of the NFT
   * @return healthFactor the current health factor of the NFT
   **/
  function getNftDebtData(
    address nftAsset,
    uint256 nftTokenId
  )
    external
    view
    returns (
      uint256 loanId,
      address reserveAsset,
      uint256 totalCollateral,
      uint256 totalDebt,
      uint256 availableBorrows,
      uint256 healthFactor
    );

  /**
   * @dev Returns the auction data of the NFT
   * @param nftAsset The address of the NFT
   * @param nftTokenId The token id of the NFT
   * @return loanId the loan id of the NFT
   * @return bidderAddress the highest bidder address of the loan
   * @return bidPrice the highest bid price in Reserve of the loan
   * @return bidBorrowAmount the borrow amount in Reserve of the loan
   * @return bidFine the penalty fine of the loan
   **/
  function getNftAuctionData(
    address nftAsset,
    uint256 nftTokenId
  )
    external
    view
    returns (
      uint256 loanId,
      address bidderAddress,
      uint256 bidPrice,
      uint256 bidBorrowAmount,
      uint256 bidFine
    );

  function getNftAuctionEndTime(
    address nftAsset,
    uint256 nftTokenId
  )
    external
    view
    returns (
      uint256 loanId,
      uint256 bidStartTimestamp,
      uint256 bidEndTimestamp,
      uint256 redeemEndTimestamp
    );

  function getNftLiquidatePrice(
    address nftAsset,
    uint256 nftTokenId
  ) external view returns (uint256 liquidatePrice, uint256 paybackAmount);

  function getNftsList() external view returns (address[] memory);

  /**
   * @dev Set the _pause state of a reserve
   * - Only callable by the LendPool contract
   * @param val `true` to pause the reserve, `false` to un-pause it
   */
  function setPause(bool val) external;

  function setPausedTime(uint256 startTime, uint256 durationTime) external;

  /**
   * @dev Returns if the LendPool is paused
   */
  function paused() external view returns (bool);

  function getPausedTime() external view returns (uint256, uint256);

  function getAddressesProvider()
    external
    view
    returns (ILendPoolAddressesProvider);

  function initReserve(
    address asset,
    address bTokenAddress,
    address debtTokenAddress,
    address interestRateAddress
  ) external;

  function initNft(address asset, address bNftAddress) external;

  function setReserveInterestRateAddress(
    address asset,
    address rateAddress
  ) external;

  function setReserveConfiguration(
    address asset,
    uint256 configuration
  ) external;

  function setNftConfiguration(address asset, uint256 configuration) external;

  function setNftMaxSupplyAndTokenId(
    address asset,
    uint256 maxSupply,
    uint256 maxTokenId
  ) external;

  function setMaxNumberOfReserves(uint256 val) external;

  function setMaxNumberOfNfts(uint256 val) external;

  function getMaxNumberOfReserves() external view returns (uint256);

  function getMaxNumberOfNfts() external view returns (uint256);
}

interface IWETHGateway {
  /**
   * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (bTokens)
   * is minted.
   * @param onBehalfOf address of the user who will receive the bTokens representing the deposit
   * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
   **/
  function depositETH(address onBehalfOf, uint16 referralCode) external payable;

  /**
   * @dev withdraws the WETH _reserves of msg.sender.
   * @param amount amount of bWETH to withdraw and receive native ETH
   * @param to address of the user who will receive native ETH
   */
  function withdrawETH(uint256 amount, address to) external;

  /**
   * @dev borrow WETH, unwraps to ETH and send both the ETH and DebtTokens to msg.sender, via `approveDelegation` and onBehalf argument in `LendPool.borrow`.
   * @param amount the amount of ETH to borrow
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param onBehalfOf Address of the user who will receive the loan. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   * @param referralCode integrators are assigned a referral code and can potentially receive rewards
   */
  function borrowETH(
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function batchBorrowETH(
    uint256[] calldata amounts,
    address[] calldata nftAssets,
    uint256[] calldata nftTokenIds,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev repays a borrow on the WETH reserve, for the specified amount (or for the whole amount, if uint256(-1) is specified).
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount the amount to repay, or uint256(-1) if the user wants to repay everything
   */
  function repayETH(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) external payable returns (uint256, bool);

  function batchRepayETH(
    address[] calldata nftAssets,
    uint256[] calldata nftTokenIds,
    uint256[] calldata amounts
  ) external payable returns (uint256[] memory, bool[] memory);

  /**
   * @dev auction a borrow on the WETH reserve
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param onBehalfOf Address of the user who will receive the underlying NFT used as collateral.
   * Should be the address of the borrower itself calling the function if he wants to borrow against his own collateral.
   */
  function auctionETH(
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf
  ) external payable;

  /**
   * @dev redeems a borrow on the WETH reserve
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   */
  function redeemETH(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 bidFine
  ) external payable returns (uint256);

  /**
   * @dev liquidates a borrow on the WETH reserve
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   */
  function liquidateETH(
    address nftAsset,
    uint256 nftTokenId
  ) external payable returns (uint256);
}

interface IPunkGateway {
  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral
   * - E.g. User borrows 100 USDC, receiving the 100 USDC in his wallet
   *   and lock collateral asset in contract
   * @param reserveAsset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param punkIndex The index of the CryptoPunk used as collteral
   * @param onBehalfOf Address of the user who will receive the loan. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function borrow(
    address reserveAsset,
    uint256 amount,
    uint256 punkIndex,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function batchBorrow(
    address[] calldata reserveAssets,
    uint256[] calldata amounts,
    uint256[] calldata punkIndexs,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific punk, burning the equivalent loan owned
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param punkIndex The index of the CryptoPunk used as collteral
   * @param amount The amount to repay
   * @return The final amount repaid, loan is burned or not
   **/
  function repay(
    uint256 punkIndex,
    uint256 amount
  ) external returns (uint256, bool);

  function batchRepay(
    uint256[] calldata punkIndexs,
    uint256[] calldata amounts
  ) external returns (uint256[] memory, bool[] memory);

  /**
   * @notice auction a unhealth punk loan with ERC20 reserve
   * @param punkIndex The index of the CryptoPunk used as collteral
   * @param bidPrice The bid price
   **/
  function auction(
    uint256 punkIndex,
    uint256 bidPrice,
    address onBehalfOf
  ) external;

  /**
   * @notice redeem a unhealth punk loan with ERC20 reserve
   * @param punkIndex The index of the CryptoPunk used as collteral
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   **/
  function redeem(
    uint256 punkIndex,
    uint256 amount,
    uint256 bidFine
  ) external returns (uint256);

  /**
   * @notice liquidate a unhealth punk loan with ERC20 reserve
   * @param punkIndex The index of the CryptoPunk used as collteral
   **/
  function liquidate(
    uint256 punkIndex,
    uint256 amount
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral
   * - E.g. User borrows 100 ETH, receiving the 100 ETH in his wallet
   *   and lock collateral asset in contract
   * @param amount The amount to be borrowed
   * @param punkIndex The index of the CryptoPunk to deposit
   * @param onBehalfOf Address of the user who will receive the loan. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function borrowETH(
    uint256 amount,
    uint256 punkIndex,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function batchBorrowETH(
    uint256[] calldata amounts,
    uint256[] calldata punkIndexs,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific punk with native ETH
   * - E.g. User repays 100 ETH, burning loan and receives collateral asset
   * @param punkIndex The index of the CryptoPunk to repay
   * @param amount The amount to repay
   * @return The final amount repaid, loan is burned or not
   **/
  function repayETH(
    uint256 punkIndex,
    uint256 amount
  ) external payable returns (uint256, bool);

  function batchRepayETH(
    uint256[] calldata punkIndexs,
    uint256[] calldata amounts
  ) external payable returns (uint256[] memory, bool[] memory);

  /**
   * @notice auction a unhealth punk loan with native ETH
   * @param punkIndex The index of the CryptoPunk to repay
   * @param onBehalfOf Address of the user who will receive the CryptoPunk. Should be the address of the user itself
   * calling the function if he wants to get collateral
   **/
  function auctionETH(uint256 punkIndex, address onBehalfOf) external payable;

  /**
   * @notice liquidate a unhealth punk loan with native ETH
   * @param punkIndex The index of the CryptoPunk to repay
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   **/
  function redeemETH(
    uint256 punkIndex,
    uint256 amount,
    uint256 bidFine
  ) external payable returns (uint256);

  /**
   * @notice liquidate a unhealth punk loan with native ETH
   * @param punkIndex The index of the CryptoPunk to repay
   **/
  function liquidateETH(uint256 punkIndex) external payable returns (uint256);
}

interface IBendProtocolDataProvider {
  struct NftTokenData {
    string nftSymbol;
    address nftAddress;
    string bNftSymbol;
    address bNftAddress;
  }

  function getAllNftsTokenDatas() external view returns (NftTokenData[] memory);
}

/**
 *  █████╗ ███████╗████████╗ █████╗ ██████╗ ██╗ █████╗
 * ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║██╔══██╗
 * ███████║███████╗   ██║   ███████║██████╔╝██║███████║
 * ██╔══██║╚════██║   ██║   ██╔══██║██╔══██╗██║██╔══██║
 * ██║  ██║███████║   ██║   ██║  ██║██║  ██║██║██║  ██║
 * ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
 *
 * Astaria Labs, Inc
 */

/**
 *  █████╗ ███████╗████████╗ █████╗ ██████╗ ██╗ █████╗
 * ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║██╔══██╗
 * ███████║███████╗   ██║   ███████║██████╔╝██║███████║
 * ██╔══██║╚════██║   ██║   ██╔══██║██╔══██╗██║██╔══██║
 * ██║  ██║███████║   ██║   ██║  ██║██║  ██║██║██║  ██║
 * ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
 *
 * Astaria Labs, Inc
 */

interface ITransferProxy {
  function tokenTransferFrom(
    address token,
    address from,
    address to,
    uint256 amount
  ) external;

  function tokenTransferFromWithErrorReceiver(
    address token,
    address from,
    address to,
    uint256 amount
  ) external;
}

// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

interface IERC20Metadata is IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the decimals places of the token.
   */
  function decimals() external view returns (uint8);
}

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
  event Deposit(
    address indexed sender,
    address indexed owner,
    uint256 assets,
    uint256 shares
  );

  event Withdraw(
    address indexed sender,
    address indexed receiver,
    address indexed owner,
    uint256 assets,
    uint256 shares
  );

  /**
   * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
   *
   * - MUST be an ERC-20 token contract.
   * - MUST NOT revert.
   */
  function asset() external view returns (address assetTokenAddress);

  /**
   * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
   *
   * - SHOULD include any compounding that occurs from yield.
   * - MUST be inclusive of any fees that are charged against assets in the Vault.
   * - MUST NOT revert.
   */
  function totalAssets() external view returns (uint256 totalManagedAssets);

  /**
   * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
   * scenario where all the conditions are met.
   *
   * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
   * - MUST NOT show any variations depending on the caller.
   * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - MUST NOT revert.
   *
   * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
   * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
   * from.
   */
  function convertToShares(
    uint256 assets
  ) external view returns (uint256 shares);

  /**
   * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
   * scenario where all the conditions are met.
   *
   * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
   * - MUST NOT show any variations depending on the caller.
   * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - MUST NOT revert.
   *
   * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
   * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
   * from.
   */
  function convertToAssets(
    uint256 shares
  ) external view returns (uint256 assets);

  /**
   * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
   * through a deposit call.
   *
   * - MUST return a limited value if receiver is subject to some deposit limit.
   * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
   * - MUST NOT revert.
   */
  function maxDeposit(
    address receiver
  ) external view returns (uint256 maxAssets);

  /**
   * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
   * current on-chain conditions.
   *
   * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
   *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
   *   in the same transaction.
   * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
   *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
   * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
   * - MUST NOT revert.
   *
   * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
   * share price or some other type of condition, meaning the depositor will lose assets by depositing.
   */
  function previewDeposit(
    uint256 assets
  ) external view returns (uint256 shares);

  /**
   * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
   *
   * - MUST emit the Deposit event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
   *   deposit execution, and are accounted for during deposit.
   * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
   *   approving enough underlying tokens to the Vault contract, etc).
   *
   * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
   */
  function deposit(
    uint256 assets,
    address receiver
  ) external returns (uint256 shares);

  /**
   * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
   * - MUST return a limited value if receiver is subject to some mint limit.
   * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
   * - MUST NOT revert.
   */
  function maxMint(address receiver) external view returns (uint256 maxShares);

  /**
   * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
   * current on-chain conditions.
   *
   * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
   *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
   *   same transaction.
   * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
   *   would be accepted, regardless if the user has enough tokens approved, etc.
   * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
   * - MUST NOT revert.
   *
   * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
   * share price or some other type of condition, meaning the depositor will lose assets by minting.
   */
  function previewMint(uint256 shares) external view returns (uint256 assets);

  /**
   * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
   *
   * - MUST emit the Deposit event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
   *   execution, and are accounted for during mint.
   * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
   *   approving enough underlying tokens to the Vault contract, etc).
   *
   * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
   */
  function mint(
    uint256 shares,
    address receiver
  ) external returns (uint256 assets);

  /**
   * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
   * Vault, through a withdraw call.
   *
   * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
   * - MUST NOT revert.
   */
  function maxWithdraw(address owner) external view returns (uint256 maxAssets);

  /**
   * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
   * given current on-chain conditions.
   *
   * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
   *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
   *   called
   *   in the same transaction.
   * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
   *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
   * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
   * - MUST NOT revert.
   *
   * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
   * share price or some other type of condition, meaning the depositor will lose assets by depositing.
   */
  function previewWithdraw(
    uint256 assets
  ) external view returns (uint256 shares);

  /**
   * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
   *
   * - MUST emit the Withdraw event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
   *   withdraw execution, and are accounted for during withdraw.
   * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
   *   not having enough shares, etc).
   *
   * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
   * Those methods should be performed separately.
   */
  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) external returns (uint256 shares);

  /**
   * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
   * through a redeem call.
   *
   * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
   * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
   * - MUST NOT revert.
   */
  function maxRedeem(address owner) external view returns (uint256 maxShares);

  /**
   * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
   * given current on-chain conditions.
   *
   * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
   *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
   *   same transaction.
   * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
   *   redemption would be accepted, regardless if the user has enough shares, etc.
   * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
   * - MUST NOT revert.
   *
   * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
   * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
   */
  function previewRedeem(uint256 shares) external view returns (uint256 assets);

  /**
   * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
   *
   * - MUST emit the Withdraw event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
   *   redeem execution, and are accounted for during redeem.
   * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
   *   not having enough shares, etc).
   *
   * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
   * Those methods should be performed separately.
   */
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) external returns (uint256 assets);
}

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event Transfer(address indexed from, address indexed to, uint256 amount);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 amount
  );

  /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

  string public name;

  string public symbol;

  uint8 public immutable decimals;

  /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

  uint256 public totalSupply;

  mapping(address => uint256) public balanceOf;

  mapping(address => mapping(address => uint256)) public allowance;

  /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

  uint256 internal immutable INITIAL_CHAIN_ID;

  bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

  mapping(address => uint256) public nonces;

  /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(string memory _name, string memory _symbol, uint8 _decimals) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;

    INITIAL_CHAIN_ID = block.chainid;
    INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
  }

  /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

  function approve(
    address spender,
    uint256 amount
  ) public virtual returns (bool) {
    allowance[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  function transfer(address to, uint256 amount) public virtual returns (bool) {
    balanceOf[msg.sender] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(msg.sender, to, amount);

    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual returns (bool) {
    uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

    if (allowed != type(uint256).max)
      allowance[from][msg.sender] = allowed - amount;

    balanceOf[from] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(from, to, amount);

    return true;
  }

  /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual {
    require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

    // Unchecked because the only math done is incrementing
    // the owner's nonce which cannot realistically overflow.
    unchecked {
      address recoveredAddress = ecrecover(
        keccak256(
          abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR(),
            keccak256(
              abi.encode(
                keccak256(
                  "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline
              )
            )
          )
        ),
        v,
        r,
        s
      );

      require(
        recoveredAddress != address(0) && recoveredAddress == owner,
        "INVALID_SIGNER"
      );

      allowance[recoveredAddress][spender] = value;
    }

    emit Approval(owner, spender, value);
  }

  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    return
      block.chainid == INITIAL_CHAIN_ID
        ? INITIAL_DOMAIN_SEPARATOR
        : computeDomainSeparator();
  }

  function computeDomainSeparator() internal view virtual returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
          ),
          keccak256(bytes(name)),
          keccak256("1"),
          block.chainid,
          address(this)
        )
      );
  }

  /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

  function _mint(address to, uint256 amount) internal virtual {
    totalSupply += amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(address(0), to, amount);
  }

  function _burn(address from, uint256 amount) internal virtual {
    balanceOf[from] -= amount;

    // Cannot underflow because a user's balance
    // will never be larger than the total supply.
    unchecked {
      totalSupply -= amount;
    }

    emit Transfer(from, address(0), amount);
  }
}

/**
 *  █████╗ ███████╗████████╗ █████╗ ██████╗ ██╗ █████╗
 * ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║██╔══██╗
 * ███████║███████╗   ██║   ███████║██████╔╝██║███████║
 * ██╔══██║╚════██║   ██║   ██╔══██║██╔══██╗██║██╔══██║
 * ██║  ██║███████║   ██║   ██║  ██║██║  ██║██║██║  ██║
 * ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
 *
 * Astaria Labs, Inc
 */

/**
 *  █████╗ ███████╗████████╗ █████╗ ██████╗ ██╗ █████╗
 * ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║██╔══██╗
 * ███████║███████╗   ██║   ███████║██████╔╝██║███████║
 * ██╔══██║╚════██║   ██║   ██╔══██║██╔══██╗██║██╔══██║
 * ██║  ██║███████║   ██║   ██║  ██║██║  ██║██║██║  ██║
 * ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
 *
 * Astaria Labs, Inc
 */

interface ILienToken is IERC721 {
  enum FileType {
    NotSupported,
    CollateralToken,
    AstariaRouter,
    BuyoutFee,
    BuyoutFeeDurationCap,
    MinInterestBPS,
    MinDurationIncrease,
    MinLoanDuration
  }

  struct File {
    FileType what;
    bytes data;
  }

  event FileUpdated(FileType what, bytes data);

  struct LienStorage {
    IAstariaRouter ASTARIA_ROUTER;
    ICollateralToken COLLATERAL_TOKEN;
    mapping(uint256 => bytes32) collateralStateHash;
    mapping(uint256 => AuctionData) collateralLiquidator;
  }
  struct AuctionData {
    uint256 amountOwed;
    address liquidator;
  }

  struct Details {
    uint256 maxAmount;
    uint256 rate; //rate per second
    uint256 duration;
    uint256 maxPotentialDebt;
    uint256 liquidationInitialAsk;
  }

  struct Lien {
    uint8 collateralType;
    address token; //20
    address payable vault; //20
    uint256 collateralId; //32 //contractAddress + tokenId
    Details details; //32 * 5
  }

  struct Point {
    uint256 amount; //11
    uint40 last; //5
    uint40 end; //5
  }

  struct Stack {
    Lien lien;
    Point point;
  }

  struct LienActionEncumber {
    address borrower;
    uint256 amount;
    address receiver;
    ILienToken.Lien lien;
    address feeTo;
    uint256 fee;
  }

  function calculateSlope(
    Stack calldata stack
  ) external pure returns (uint256 slope);

  function handleLiquidation(
    uint256 auctionWindow,
    Stack calldata stack,
    address liquidator
  ) external;

  function getOwed(Stack calldata stack) external view returns (uint256);

  function getOwed(
    Stack calldata stack,
    uint256 timestamp
  ) external view returns (uint256);

  function getInterest(Stack calldata stack) external returns (uint256);

  function getCollateralState(
    uint256 collateralId
  ) external view returns (bytes32);

  function createLien(
    LienActionEncumber calldata params
  ) external returns (uint256 lienId, Stack memory stack, uint256 owingAtEnd);

  function makePayment(Stack memory stack) external;

  function getAuctionLiquidator(
    uint256 collateralId
  ) external view returns (address liquidator);

  function getAuctionData(
    uint256 collateralId
  ) external view returns (AuctionData memory);

  function file(File calldata file) external;

  event NewLien(uint256 indexed collateralId, Stack stack);
  event Payment(uint256 indexed lienId, uint256 amount);

  error InvalidFileData();
  error UnsupportedFile();
  error InvalidTokenId(uint256 tokenId);
  error InvalidLoanState();
  error InvalidSender();
  enum InvalidLienStates {
    INVALID_LIEN_ID,
    INVALID_HASH,
    INVALID_LIQUIDATION_INITIAL_ASK,
    PUBLIC_VAULT_RECIPIENT,
    COLLATERAL_NOT_LIQUIDATED,
    COLLATERAL_LIQUIDATED,
    AMOUNT_ZERO,
    MIN_DURATION_NOT_MET
  }

  error InvalidLienState(InvalidLienStates);
}

enum OrderType {
  // 0: no partial fills, anyone can execute
  FULL_OPEN,
  // 1: partial fills supported, anyone can execute
  PARTIAL_OPEN,
  // 2: no partial fills, only offerer or zone can execute
  FULL_RESTRICTED,
  // 3: partial fills supported, only offerer or zone can execute
  PARTIAL_RESTRICTED,
  // 4: contract order type
  CONTRACT
}

enum BasicOrderType {
  // 0: no partial fills, anyone can execute
  ETH_TO_ERC721_FULL_OPEN,
  // 1: partial fills supported, anyone can execute
  ETH_TO_ERC721_PARTIAL_OPEN,
  // 2: no partial fills, only offerer or zone can execute
  ETH_TO_ERC721_FULL_RESTRICTED,
  // 3: partial fills supported, only offerer or zone can execute
  ETH_TO_ERC721_PARTIAL_RESTRICTED,
  // 4: no partial fills, anyone can execute
  ETH_TO_ERC1155_FULL_OPEN,
  // 5: partial fills supported, anyone can execute
  ETH_TO_ERC1155_PARTIAL_OPEN,
  // 6: no partial fills, only offerer or zone can execute
  ETH_TO_ERC1155_FULL_RESTRICTED,
  // 7: partial fills supported, only offerer or zone can execute
  ETH_TO_ERC1155_PARTIAL_RESTRICTED,
  // 8: no partial fills, anyone can execute
  ERC20_TO_ERC721_FULL_OPEN,
  // 9: partial fills supported, anyone can execute
  ERC20_TO_ERC721_PARTIAL_OPEN,
  // 10: no partial fills, only offerer or zone can execute
  ERC20_TO_ERC721_FULL_RESTRICTED,
  // 11: partial fills supported, only offerer or zone can execute
  ERC20_TO_ERC721_PARTIAL_RESTRICTED,
  // 12: no partial fills, anyone can execute
  ERC20_TO_ERC1155_FULL_OPEN,
  // 13: partial fills supported, anyone can execute
  ERC20_TO_ERC1155_PARTIAL_OPEN,
  // 14: no partial fills, only offerer or zone can execute
  ERC20_TO_ERC1155_FULL_RESTRICTED,
  // 15: partial fills supported, only offerer or zone can execute
  ERC20_TO_ERC1155_PARTIAL_RESTRICTED,
  // 16: no partial fills, anyone can execute
  ERC721_TO_ERC20_FULL_OPEN,
  // 17: partial fills supported, anyone can execute
  ERC721_TO_ERC20_PARTIAL_OPEN,
  // 18: no partial fills, only offerer or zone can execute
  ERC721_TO_ERC20_FULL_RESTRICTED,
  // 19: partial fills supported, only offerer or zone can execute
  ERC721_TO_ERC20_PARTIAL_RESTRICTED,
  // 20: no partial fills, anyone can execute
  ERC1155_TO_ERC20_FULL_OPEN,
  // 21: partial fills supported, anyone can execute
  ERC1155_TO_ERC20_PARTIAL_OPEN,
  // 22: no partial fills, only offerer or zone can execute
  ERC1155_TO_ERC20_FULL_RESTRICTED,
  // 23: partial fills supported, only offerer or zone can execute
  ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

enum BasicOrderRouteType {
  // 0: provide Ether (or other native token) to receive offered ERC721 item.
  ETH_TO_ERC721,
  // 1: provide Ether (or other native token) to receive offered ERC1155 item.
  ETH_TO_ERC1155,
  // 2: provide ERC20 item to receive offered ERC721 item.
  ERC20_TO_ERC721,
  // 3: provide ERC20 item to receive offered ERC1155 item.
  ERC20_TO_ERC1155,
  // 4: provide ERC721 item to receive offered ERC20 item.
  ERC721_TO_ERC20,
  // 5: provide ERC1155 item to receive offered ERC20 item.
  ERC1155_TO_ERC20
}

enum ItemType {
  // 0: ETH on mainnet, MATIC on polygon, etc.
  NATIVE,
  // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
  ERC20,
  // 2: ERC721 items
  ERC721,
  // 3: ERC1155 items
  ERC1155,
  // 4: ERC721 items where a number of tokenIds are supported
  ERC721_WITH_CRITERIA,
  // 5: ERC1155 items where a number of ids are supported
  ERC1155_WITH_CRITERIA
}

enum Side {
  // 0: Items that can be spent
  OFFER,
  // 1: Items that must be received
  CONSIDERATION
}

type CalldataPointer is uint256;

type ReturndataPointer is uint256;

type MemoryPointer is uint256;

using CalldataPointerLib for CalldataPointer global;
using MemoryPointerLib for MemoryPointer global;
using ReturndataPointerLib for ReturndataPointer global;

using CalldataReaders for CalldataPointer global;
using ReturndataReaders for ReturndataPointer global;
using MemoryReaders for MemoryPointer global;
using MemoryWriters for MemoryPointer global;

CalldataPointer constant CalldataStart = CalldataPointer.wrap(0x04);
MemoryPointer constant FreeMemoryPPtr = MemoryPointer.wrap(0x40);
uint256 constant IdentityPrecompileAddress = 0x4;
uint256 constant OffsetOrLengthMask = 0xffffffff;
uint256 constant _OneWord = 0x20;
uint256 constant _FreeMemoryPointerSlot = 0x40;

/// @dev Allocates `size` bytes in memory by increasing the free memory pointer
///    and returns the memory pointer to the first byte of the allocated region.
// (Free functions cannot have visibility.)
// solhint-disable-next-line func-visibility
function malloc(uint256 size) pure returns (MemoryPointer mPtr) {
  assembly {
    mPtr := mload(_FreeMemoryPointerSlot)
    mstore(_FreeMemoryPointerSlot, add(mPtr, size))
  }
}

// (Free functions cannot have visibility.)
// solhint-disable-next-line func-visibility
function getFreeMemoryPointer() pure returns (MemoryPointer mPtr) {
  mPtr = FreeMemoryPPtr.readMemoryPointer();
}

// (Free functions cannot have visibility.)
// solhint-disable-next-line func-visibility
function setFreeMemoryPointer(MemoryPointer mPtr) pure {
  FreeMemoryPPtr.write(mPtr);
}

library CalldataPointerLib {
  function lt(
    CalldataPointer a,
    CalldataPointer b
  ) internal pure returns (bool c) {
    assembly {
      c := lt(a, b)
    }
  }

  function gt(
    CalldataPointer a,
    CalldataPointer b
  ) internal pure returns (bool c) {
    assembly {
      c := gt(a, b)
    }
  }

  function eq(
    CalldataPointer a,
    CalldataPointer b
  ) internal pure returns (bool c) {
    assembly {
      c := eq(a, b)
    }
  }

  function isNull(CalldataPointer a) internal pure returns (bool b) {
    assembly {
      b := iszero(a)
    }
  }

  /// @dev Resolves an offset stored at `cdPtr + headOffset` to a calldata.
  ///      pointer `cdPtr` must point to some parent object with a dynamic
  ///      type's head stored at `cdPtr + headOffset`.
  function pptr(
    CalldataPointer cdPtr,
    uint256 headOffset
  ) internal pure returns (CalldataPointer cdPtrChild) {
    cdPtrChild = cdPtr.offset(
      cdPtr.offset(headOffset).readUint256() & OffsetOrLengthMask
    );
  }

  /// @dev Resolves an offset stored at `cdPtr` to a calldata pointer.
  ///      `cdPtr` must point to some parent object with a dynamic type as its
  ///      first member, e.g. `struct { bytes data; }`
  function pptr(
    CalldataPointer cdPtr
  ) internal pure returns (CalldataPointer cdPtrChild) {
    cdPtrChild = cdPtr.offset(cdPtr.readUint256() & OffsetOrLengthMask);
  }

  /// @dev Returns the calldata pointer one word after `cdPtr`.
  function next(
    CalldataPointer cdPtr
  ) internal pure returns (CalldataPointer cdPtrNext) {
    assembly {
      cdPtrNext := add(cdPtr, _OneWord)
    }
  }

  /// @dev Returns the calldata pointer `_offset` bytes after `cdPtr`.
  function offset(
    CalldataPointer cdPtr,
    uint256 _offset
  ) internal pure returns (CalldataPointer cdPtrNext) {
    assembly {
      cdPtrNext := add(cdPtr, _offset)
    }
  }

  /// @dev Copies `size` bytes from calldata starting at `src` to memory at
  ///      `dst`.
  function copy(
    CalldataPointer src,
    MemoryPointer dst,
    uint256 size
  ) internal pure {
    assembly {
      calldatacopy(dst, src, size)
    }
  }
}

library ReturndataPointerLib {
  function lt(
    ReturndataPointer a,
    ReturndataPointer b
  ) internal pure returns (bool c) {
    assembly {
      c := lt(a, b)
    }
  }

  function gt(
    ReturndataPointer a,
    ReturndataPointer b
  ) internal pure returns (bool c) {
    assembly {
      c := gt(a, b)
    }
  }

  function eq(
    ReturndataPointer a,
    ReturndataPointer b
  ) internal pure returns (bool c) {
    assembly {
      c := eq(a, b)
    }
  }

  function isNull(ReturndataPointer a) internal pure returns (bool b) {
    assembly {
      b := iszero(a)
    }
  }

  /// @dev Resolves an offset stored at `rdPtr + headOffset` to a returndata
  ///      pointer. `rdPtr` must point to some parent object with a dynamic
  ///      type's head stored at `rdPtr + headOffset`.
  function pptr(
    ReturndataPointer rdPtr,
    uint256 headOffset
  ) internal pure returns (ReturndataPointer rdPtrChild) {
    rdPtrChild = rdPtr.offset(
      rdPtr.offset(headOffset).readUint256() & OffsetOrLengthMask
    );
  }

  /// @dev Resolves an offset stored at `rdPtr` to a returndata pointer.
  ///    `rdPtr` must point to some parent object with a dynamic type as its
  ///    first member, e.g. `struct { bytes data; }`
  function pptr(
    ReturndataPointer rdPtr
  ) internal pure returns (ReturndataPointer rdPtrChild) {
    rdPtrChild = rdPtr.offset(rdPtr.readUint256() & OffsetOrLengthMask);
  }

  /// @dev Returns the returndata pointer one word after `cdPtr`.
  function next(
    ReturndataPointer rdPtr
  ) internal pure returns (ReturndataPointer rdPtrNext) {
    assembly {
      rdPtrNext := add(rdPtr, _OneWord)
    }
  }

  /// @dev Returns the returndata pointer `_offset` bytes after `cdPtr`.
  function offset(
    ReturndataPointer rdPtr,
    uint256 _offset
  ) internal pure returns (ReturndataPointer rdPtrNext) {
    assembly {
      rdPtrNext := add(rdPtr, _offset)
    }
  }

  /// @dev Copies `size` bytes from returndata starting at `src` to memory at
  /// `dst`.
  function copy(
    ReturndataPointer src,
    MemoryPointer dst,
    uint256 size
  ) internal pure {
    assembly {
      returndatacopy(dst, src, size)
    }
  }
}

library MemoryPointerLib {
  function copy(
    MemoryPointer src,
    MemoryPointer dst,
    uint256 size
  ) internal view {
    assembly {
      let success := staticcall(
        gas(),
        IdentityPrecompileAddress,
        src,
        size,
        dst,
        size
      )
      if or(iszero(returndatasize()), iszero(success)) {
        revert(0, 0)
      }
    }
  }

  function lt(MemoryPointer a, MemoryPointer b) internal pure returns (bool c) {
    assembly {
      c := lt(a, b)
    }
  }

  function gt(MemoryPointer a, MemoryPointer b) internal pure returns (bool c) {
    assembly {
      c := gt(a, b)
    }
  }

  function eq(MemoryPointer a, MemoryPointer b) internal pure returns (bool c) {
    assembly {
      c := eq(a, b)
    }
  }

  function isNull(MemoryPointer a) internal pure returns (bool b) {
    assembly {
      b := iszero(a)
    }
  }

  function hash(
    MemoryPointer ptr,
    uint256 length
  ) internal pure returns (bytes32 _hash) {
    assembly {
      _hash := keccak256(ptr, length)
    }
  }

  /// @dev Returns the memory pointer one word after `mPtr`.
  function next(
    MemoryPointer mPtr
  ) internal pure returns (MemoryPointer mPtrNext) {
    assembly {
      mPtrNext := add(mPtr, _OneWord)
    }
  }

  /// @dev Returns the memory pointer `_offset` bytes after `mPtr`.
  function offset(
    MemoryPointer mPtr,
    uint256 _offset
  ) internal pure returns (MemoryPointer mPtrNext) {
    assembly {
      mPtrNext := add(mPtr, _offset)
    }
  }

  /// @dev Resolves a pointer at `mPtr + headOffset` to a memory
  ///    pointer. `mPtr` must point to some parent object with a dynamic
  ///    type's pointer stored at `mPtr + headOffset`.
  function pptr(
    MemoryPointer mPtr,
    uint256 headOffset
  ) internal pure returns (MemoryPointer mPtrChild) {
    mPtrChild = mPtr.offset(headOffset).readMemoryPointer();
  }

  /// @dev Resolves a pointer stored at `mPtr` to a memory pointer.
  ///    `mPtr` must point to some parent object with a dynamic type as its
  ///    first member, e.g. `struct { bytes data; }`
  function pptr(
    MemoryPointer mPtr
  ) internal pure returns (MemoryPointer mPtrChild) {
    mPtrChild = mPtr.readMemoryPointer();
  }
}

library CalldataReaders {
  /// @dev Reads the value at `cdPtr` and applies a mask to return only the
  ///    last 4 bytes.
  function readMaskedUint256(
    CalldataPointer cdPtr
  ) internal pure returns (uint256 value) {
    value = cdPtr.readUint256() & OffsetOrLengthMask;
  }

  /// @dev Reads the bool at `cdPtr` in calldata.
  function readBool(CalldataPointer cdPtr) internal pure returns (bool value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the address at `cdPtr` in calldata.
  function readAddress(
    CalldataPointer cdPtr
  ) internal pure returns (address value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes1 at `cdPtr` in calldata.
  function readBytes1(
    CalldataPointer cdPtr
  ) internal pure returns (bytes1 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes2 at `cdPtr` in calldata.
  function readBytes2(
    CalldataPointer cdPtr
  ) internal pure returns (bytes2 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes3 at `cdPtr` in calldata.
  function readBytes3(
    CalldataPointer cdPtr
  ) internal pure returns (bytes3 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes4 at `cdPtr` in calldata.
  function readBytes4(
    CalldataPointer cdPtr
  ) internal pure returns (bytes4 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes5 at `cdPtr` in calldata.
  function readBytes5(
    CalldataPointer cdPtr
  ) internal pure returns (bytes5 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes6 at `cdPtr` in calldata.
  function readBytes6(
    CalldataPointer cdPtr
  ) internal pure returns (bytes6 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes7 at `cdPtr` in calldata.
  function readBytes7(
    CalldataPointer cdPtr
  ) internal pure returns (bytes7 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes8 at `cdPtr` in calldata.
  function readBytes8(
    CalldataPointer cdPtr
  ) internal pure returns (bytes8 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes9 at `cdPtr` in calldata.
  function readBytes9(
    CalldataPointer cdPtr
  ) internal pure returns (bytes9 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes10 at `cdPtr` in calldata.
  function readBytes10(
    CalldataPointer cdPtr
  ) internal pure returns (bytes10 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes11 at `cdPtr` in calldata.
  function readBytes11(
    CalldataPointer cdPtr
  ) internal pure returns (bytes11 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes12 at `cdPtr` in calldata.
  function readBytes12(
    CalldataPointer cdPtr
  ) internal pure returns (bytes12 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes13 at `cdPtr` in calldata.
  function readBytes13(
    CalldataPointer cdPtr
  ) internal pure returns (bytes13 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes14 at `cdPtr` in calldata.
  function readBytes14(
    CalldataPointer cdPtr
  ) internal pure returns (bytes14 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes15 at `cdPtr` in calldata.
  function readBytes15(
    CalldataPointer cdPtr
  ) internal pure returns (bytes15 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes16 at `cdPtr` in calldata.
  function readBytes16(
    CalldataPointer cdPtr
  ) internal pure returns (bytes16 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes17 at `cdPtr` in calldata.
  function readBytes17(
    CalldataPointer cdPtr
  ) internal pure returns (bytes17 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes18 at `cdPtr` in calldata.
  function readBytes18(
    CalldataPointer cdPtr
  ) internal pure returns (bytes18 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes19 at `cdPtr` in calldata.
  function readBytes19(
    CalldataPointer cdPtr
  ) internal pure returns (bytes19 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes20 at `cdPtr` in calldata.
  function readBytes20(
    CalldataPointer cdPtr
  ) internal pure returns (bytes20 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes21 at `cdPtr` in calldata.
  function readBytes21(
    CalldataPointer cdPtr
  ) internal pure returns (bytes21 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes22 at `cdPtr` in calldata.
  function readBytes22(
    CalldataPointer cdPtr
  ) internal pure returns (bytes22 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes23 at `cdPtr` in calldata.
  function readBytes23(
    CalldataPointer cdPtr
  ) internal pure returns (bytes23 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes24 at `cdPtr` in calldata.
  function readBytes24(
    CalldataPointer cdPtr
  ) internal pure returns (bytes24 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes25 at `cdPtr` in calldata.
  function readBytes25(
    CalldataPointer cdPtr
  ) internal pure returns (bytes25 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes26 at `cdPtr` in calldata.
  function readBytes26(
    CalldataPointer cdPtr
  ) internal pure returns (bytes26 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes27 at `cdPtr` in calldata.
  function readBytes27(
    CalldataPointer cdPtr
  ) internal pure returns (bytes27 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes28 at `cdPtr` in calldata.
  function readBytes28(
    CalldataPointer cdPtr
  ) internal pure returns (bytes28 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes29 at `cdPtr` in calldata.
  function readBytes29(
    CalldataPointer cdPtr
  ) internal pure returns (bytes29 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes30 at `cdPtr` in calldata.
  function readBytes30(
    CalldataPointer cdPtr
  ) internal pure returns (bytes30 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes31 at `cdPtr` in calldata.
  function readBytes31(
    CalldataPointer cdPtr
  ) internal pure returns (bytes31 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the bytes32 at `cdPtr` in calldata.
  function readBytes32(
    CalldataPointer cdPtr
  ) internal pure returns (bytes32 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint8 at `cdPtr` in calldata.
  function readUint8(
    CalldataPointer cdPtr
  ) internal pure returns (uint8 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint16 at `cdPtr` in calldata.
  function readUint16(
    CalldataPointer cdPtr
  ) internal pure returns (uint16 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint24 at `cdPtr` in calldata.
  function readUint24(
    CalldataPointer cdPtr
  ) internal pure returns (uint24 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint32 at `cdPtr` in calldata.
  function readUint32(
    CalldataPointer cdPtr
  ) internal pure returns (uint32 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint40 at `cdPtr` in calldata.
  function readUint40(
    CalldataPointer cdPtr
  ) internal pure returns (uint40 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint48 at `cdPtr` in calldata.
  function readUint48(
    CalldataPointer cdPtr
  ) internal pure returns (uint48 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint56 at `cdPtr` in calldata.
  function readUint56(
    CalldataPointer cdPtr
  ) internal pure returns (uint56 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint64 at `cdPtr` in calldata.
  function readUint64(
    CalldataPointer cdPtr
  ) internal pure returns (uint64 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint72 at `cdPtr` in calldata.
  function readUint72(
    CalldataPointer cdPtr
  ) internal pure returns (uint72 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint80 at `cdPtr` in calldata.
  function readUint80(
    CalldataPointer cdPtr
  ) internal pure returns (uint80 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint88 at `cdPtr` in calldata.
  function readUint88(
    CalldataPointer cdPtr
  ) internal pure returns (uint88 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint96 at `cdPtr` in calldata.
  function readUint96(
    CalldataPointer cdPtr
  ) internal pure returns (uint96 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint104 at `cdPtr` in calldata.
  function readUint104(
    CalldataPointer cdPtr
  ) internal pure returns (uint104 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint112 at `cdPtr` in calldata.
  function readUint112(
    CalldataPointer cdPtr
  ) internal pure returns (uint112 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint120 at `cdPtr` in calldata.
  function readUint120(
    CalldataPointer cdPtr
  ) internal pure returns (uint120 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint128 at `cdPtr` in calldata.
  function readUint128(
    CalldataPointer cdPtr
  ) internal pure returns (uint128 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint136 at `cdPtr` in calldata.
  function readUint136(
    CalldataPointer cdPtr
  ) internal pure returns (uint136 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint144 at `cdPtr` in calldata.
  function readUint144(
    CalldataPointer cdPtr
  ) internal pure returns (uint144 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint152 at `cdPtr` in calldata.
  function readUint152(
    CalldataPointer cdPtr
  ) internal pure returns (uint152 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint160 at `cdPtr` in calldata.
  function readUint160(
    CalldataPointer cdPtr
  ) internal pure returns (uint160 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint168 at `cdPtr` in calldata.
  function readUint168(
    CalldataPointer cdPtr
  ) internal pure returns (uint168 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint176 at `cdPtr` in calldata.
  function readUint176(
    CalldataPointer cdPtr
  ) internal pure returns (uint176 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint184 at `cdPtr` in calldata.
  function readUint184(
    CalldataPointer cdPtr
  ) internal pure returns (uint184 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint192 at `cdPtr` in calldata.
  function readUint192(
    CalldataPointer cdPtr
  ) internal pure returns (uint192 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint200 at `cdPtr` in calldata.
  function readUint200(
    CalldataPointer cdPtr
  ) internal pure returns (uint200 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint208 at `cdPtr` in calldata.
  function readUint208(
    CalldataPointer cdPtr
  ) internal pure returns (uint208 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint216 at `cdPtr` in calldata.
  function readUint216(
    CalldataPointer cdPtr
  ) internal pure returns (uint216 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint224 at `cdPtr` in calldata.
  function readUint224(
    CalldataPointer cdPtr
  ) internal pure returns (uint224 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint232 at `cdPtr` in calldata.
  function readUint232(
    CalldataPointer cdPtr
  ) internal pure returns (uint232 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint240 at `cdPtr` in calldata.
  function readUint240(
    CalldataPointer cdPtr
  ) internal pure returns (uint240 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint248 at `cdPtr` in calldata.
  function readUint248(
    CalldataPointer cdPtr
  ) internal pure returns (uint248 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the uint256 at `cdPtr` in calldata.
  function readUint256(
    CalldataPointer cdPtr
  ) internal pure returns (uint256 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int8 at `cdPtr` in calldata.
  function readInt8(CalldataPointer cdPtr) internal pure returns (int8 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int16 at `cdPtr` in calldata.
  function readInt16(
    CalldataPointer cdPtr
  ) internal pure returns (int16 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int24 at `cdPtr` in calldata.
  function readInt24(
    CalldataPointer cdPtr
  ) internal pure returns (int24 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int32 at `cdPtr` in calldata.
  function readInt32(
    CalldataPointer cdPtr
  ) internal pure returns (int32 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int40 at `cdPtr` in calldata.
  function readInt40(
    CalldataPointer cdPtr
  ) internal pure returns (int40 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int48 at `cdPtr` in calldata.
  function readInt48(
    CalldataPointer cdPtr
  ) internal pure returns (int48 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int56 at `cdPtr` in calldata.
  function readInt56(
    CalldataPointer cdPtr
  ) internal pure returns (int56 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int64 at `cdPtr` in calldata.
  function readInt64(
    CalldataPointer cdPtr
  ) internal pure returns (int64 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int72 at `cdPtr` in calldata.
  function readInt72(
    CalldataPointer cdPtr
  ) internal pure returns (int72 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int80 at `cdPtr` in calldata.
  function readInt80(
    CalldataPointer cdPtr
  ) internal pure returns (int80 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int88 at `cdPtr` in calldata.
  function readInt88(
    CalldataPointer cdPtr
  ) internal pure returns (int88 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int96 at `cdPtr` in calldata.
  function readInt96(
    CalldataPointer cdPtr
  ) internal pure returns (int96 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int104 at `cdPtr` in calldata.
  function readInt104(
    CalldataPointer cdPtr
  ) internal pure returns (int104 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int112 at `cdPtr` in calldata.
  function readInt112(
    CalldataPointer cdPtr
  ) internal pure returns (int112 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int120 at `cdPtr` in calldata.
  function readInt120(
    CalldataPointer cdPtr
  ) internal pure returns (int120 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int128 at `cdPtr` in calldata.
  function readInt128(
    CalldataPointer cdPtr
  ) internal pure returns (int128 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int136 at `cdPtr` in calldata.
  function readInt136(
    CalldataPointer cdPtr
  ) internal pure returns (int136 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int144 at `cdPtr` in calldata.
  function readInt144(
    CalldataPointer cdPtr
  ) internal pure returns (int144 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int152 at `cdPtr` in calldata.
  function readInt152(
    CalldataPointer cdPtr
  ) internal pure returns (int152 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int160 at `cdPtr` in calldata.
  function readInt160(
    CalldataPointer cdPtr
  ) internal pure returns (int160 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int168 at `cdPtr` in calldata.
  function readInt168(
    CalldataPointer cdPtr
  ) internal pure returns (int168 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int176 at `cdPtr` in calldata.
  function readInt176(
    CalldataPointer cdPtr
  ) internal pure returns (int176 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int184 at `cdPtr` in calldata.
  function readInt184(
    CalldataPointer cdPtr
  ) internal pure returns (int184 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int192 at `cdPtr` in calldata.
  function readInt192(
    CalldataPointer cdPtr
  ) internal pure returns (int192 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int200 at `cdPtr` in calldata.
  function readInt200(
    CalldataPointer cdPtr
  ) internal pure returns (int200 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int208 at `cdPtr` in calldata.
  function readInt208(
    CalldataPointer cdPtr
  ) internal pure returns (int208 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int216 at `cdPtr` in calldata.
  function readInt216(
    CalldataPointer cdPtr
  ) internal pure returns (int216 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int224 at `cdPtr` in calldata.
  function readInt224(
    CalldataPointer cdPtr
  ) internal pure returns (int224 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int232 at `cdPtr` in calldata.
  function readInt232(
    CalldataPointer cdPtr
  ) internal pure returns (int232 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int240 at `cdPtr` in calldata.
  function readInt240(
    CalldataPointer cdPtr
  ) internal pure returns (int240 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int248 at `cdPtr` in calldata.
  function readInt248(
    CalldataPointer cdPtr
  ) internal pure returns (int248 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }

  /// @dev Reads the int256 at `cdPtr` in calldata.
  function readInt256(
    CalldataPointer cdPtr
  ) internal pure returns (int256 value) {
    assembly {
      value := calldataload(cdPtr)
    }
  }
}

library ReturndataReaders {
  /// @dev Reads value at `rdPtr` & applies a mask to return only last 4 bytes
  function readMaskedUint256(
    ReturndataPointer rdPtr
  ) internal pure returns (uint256 value) {
    value = rdPtr.readUint256() & OffsetOrLengthMask;
  }

  /// @dev Reads the bool at `rdPtr` in returndata.
  function readBool(
    ReturndataPointer rdPtr
  ) internal pure returns (bool value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the address at `rdPtr` in returndata.
  function readAddress(
    ReturndataPointer rdPtr
  ) internal pure returns (address value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes1 at `rdPtr` in returndata.
  function readBytes1(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes1 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes2 at `rdPtr` in returndata.
  function readBytes2(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes2 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes3 at `rdPtr` in returndata.
  function readBytes3(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes3 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes4 at `rdPtr` in returndata.
  function readBytes4(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes4 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes5 at `rdPtr` in returndata.
  function readBytes5(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes5 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes6 at `rdPtr` in returndata.
  function readBytes6(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes6 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes7 at `rdPtr` in returndata.
  function readBytes7(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes7 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes8 at `rdPtr` in returndata.
  function readBytes8(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes8 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes9 at `rdPtr` in returndata.
  function readBytes9(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes9 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes10 at `rdPtr` in returndata.
  function readBytes10(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes10 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes11 at `rdPtr` in returndata.
  function readBytes11(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes11 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes12 at `rdPtr` in returndata.
  function readBytes12(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes12 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes13 at `rdPtr` in returndata.
  function readBytes13(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes13 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes14 at `rdPtr` in returndata.
  function readBytes14(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes14 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes15 at `rdPtr` in returndata.
  function readBytes15(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes15 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes16 at `rdPtr` in returndata.
  function readBytes16(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes16 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes17 at `rdPtr` in returndata.
  function readBytes17(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes17 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes18 at `rdPtr` in returndata.
  function readBytes18(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes18 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes19 at `rdPtr` in returndata.
  function readBytes19(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes19 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes20 at `rdPtr` in returndata.
  function readBytes20(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes20 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes21 at `rdPtr` in returndata.
  function readBytes21(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes21 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes22 at `rdPtr` in returndata.
  function readBytes22(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes22 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes23 at `rdPtr` in returndata.
  function readBytes23(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes23 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes24 at `rdPtr` in returndata.
  function readBytes24(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes24 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes25 at `rdPtr` in returndata.
  function readBytes25(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes25 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes26 at `rdPtr` in returndata.
  function readBytes26(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes26 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes27 at `rdPtr` in returndata.
  function readBytes27(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes27 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes28 at `rdPtr` in returndata.
  function readBytes28(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes28 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes29 at `rdPtr` in returndata.
  function readBytes29(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes29 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes30 at `rdPtr` in returndata.
  function readBytes30(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes30 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes31 at `rdPtr` in returndata.
  function readBytes31(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes31 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the bytes32 at `rdPtr` in returndata.
  function readBytes32(
    ReturndataPointer rdPtr
  ) internal pure returns (bytes32 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint8 at `rdPtr` in returndata.
  function readUint8(
    ReturndataPointer rdPtr
  ) internal pure returns (uint8 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint16 at `rdPtr` in returndata.
  function readUint16(
    ReturndataPointer rdPtr
  ) internal pure returns (uint16 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint24 at `rdPtr` in returndata.
  function readUint24(
    ReturndataPointer rdPtr
  ) internal pure returns (uint24 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint32 at `rdPtr` in returndata.
  function readUint32(
    ReturndataPointer rdPtr
  ) internal pure returns (uint32 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint40 at `rdPtr` in returndata.
  function readUint40(
    ReturndataPointer rdPtr
  ) internal pure returns (uint40 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint48 at `rdPtr` in returndata.
  function readUint48(
    ReturndataPointer rdPtr
  ) internal pure returns (uint48 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint56 at `rdPtr` in returndata.
  function readUint56(
    ReturndataPointer rdPtr
  ) internal pure returns (uint56 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint64 at `rdPtr` in returndata.
  function readUint64(
    ReturndataPointer rdPtr
  ) internal pure returns (uint64 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint72 at `rdPtr` in returndata.
  function readUint72(
    ReturndataPointer rdPtr
  ) internal pure returns (uint72 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint80 at `rdPtr` in returndata.
  function readUint80(
    ReturndataPointer rdPtr
  ) internal pure returns (uint80 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint88 at `rdPtr` in returndata.
  function readUint88(
    ReturndataPointer rdPtr
  ) internal pure returns (uint88 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint96 at `rdPtr` in returndata.
  function readUint96(
    ReturndataPointer rdPtr
  ) internal pure returns (uint96 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint104 at `rdPtr` in returndata.
  function readUint104(
    ReturndataPointer rdPtr
  ) internal pure returns (uint104 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint112 at `rdPtr` in returndata.
  function readUint112(
    ReturndataPointer rdPtr
  ) internal pure returns (uint112 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint120 at `rdPtr` in returndata.
  function readUint120(
    ReturndataPointer rdPtr
  ) internal pure returns (uint120 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint128 at `rdPtr` in returndata.
  function readUint128(
    ReturndataPointer rdPtr
  ) internal pure returns (uint128 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint136 at `rdPtr` in returndata.
  function readUint136(
    ReturndataPointer rdPtr
  ) internal pure returns (uint136 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint144 at `rdPtr` in returndata.
  function readUint144(
    ReturndataPointer rdPtr
  ) internal pure returns (uint144 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint152 at `rdPtr` in returndata.
  function readUint152(
    ReturndataPointer rdPtr
  ) internal pure returns (uint152 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint160 at `rdPtr` in returndata.
  function readUint160(
    ReturndataPointer rdPtr
  ) internal pure returns (uint160 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint168 at `rdPtr` in returndata.
  function readUint168(
    ReturndataPointer rdPtr
  ) internal pure returns (uint168 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint176 at `rdPtr` in returndata.
  function readUint176(
    ReturndataPointer rdPtr
  ) internal pure returns (uint176 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint184 at `rdPtr` in returndata.
  function readUint184(
    ReturndataPointer rdPtr
  ) internal pure returns (uint184 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint192 at `rdPtr` in returndata.
  function readUint192(
    ReturndataPointer rdPtr
  ) internal pure returns (uint192 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint200 at `rdPtr` in returndata.
  function readUint200(
    ReturndataPointer rdPtr
  ) internal pure returns (uint200 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint208 at `rdPtr` in returndata.
  function readUint208(
    ReturndataPointer rdPtr
  ) internal pure returns (uint208 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint216 at `rdPtr` in returndata.
  function readUint216(
    ReturndataPointer rdPtr
  ) internal pure returns (uint216 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint224 at `rdPtr` in returndata.
  function readUint224(
    ReturndataPointer rdPtr
  ) internal pure returns (uint224 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint232 at `rdPtr` in returndata.
  function readUint232(
    ReturndataPointer rdPtr
  ) internal pure returns (uint232 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint240 at `rdPtr` in returndata.
  function readUint240(
    ReturndataPointer rdPtr
  ) internal pure returns (uint240 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint248 at `rdPtr` in returndata.
  function readUint248(
    ReturndataPointer rdPtr
  ) internal pure returns (uint248 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the uint256 at `rdPtr` in returndata.
  function readUint256(
    ReturndataPointer rdPtr
  ) internal pure returns (uint256 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int8 at `rdPtr` in returndata.
  function readInt8(
    ReturndataPointer rdPtr
  ) internal pure returns (int8 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int16 at `rdPtr` in returndata.
  function readInt16(
    ReturndataPointer rdPtr
  ) internal pure returns (int16 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int24 at `rdPtr` in returndata.
  function readInt24(
    ReturndataPointer rdPtr
  ) internal pure returns (int24 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int32 at `rdPtr` in returndata.
  function readInt32(
    ReturndataPointer rdPtr
  ) internal pure returns (int32 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int40 at `rdPtr` in returndata.
  function readInt40(
    ReturndataPointer rdPtr
  ) internal pure returns (int40 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int48 at `rdPtr` in returndata.
  function readInt48(
    ReturndataPointer rdPtr
  ) internal pure returns (int48 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int56 at `rdPtr` in returndata.
  function readInt56(
    ReturndataPointer rdPtr
  ) internal pure returns (int56 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int64 at `rdPtr` in returndata.
  function readInt64(
    ReturndataPointer rdPtr
  ) internal pure returns (int64 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int72 at `rdPtr` in returndata.
  function readInt72(
    ReturndataPointer rdPtr
  ) internal pure returns (int72 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int80 at `rdPtr` in returndata.
  function readInt80(
    ReturndataPointer rdPtr
  ) internal pure returns (int80 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int88 at `rdPtr` in returndata.
  function readInt88(
    ReturndataPointer rdPtr
  ) internal pure returns (int88 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int96 at `rdPtr` in returndata.
  function readInt96(
    ReturndataPointer rdPtr
  ) internal pure returns (int96 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int104 at `rdPtr` in returndata.
  function readInt104(
    ReturndataPointer rdPtr
  ) internal pure returns (int104 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int112 at `rdPtr` in returndata.
  function readInt112(
    ReturndataPointer rdPtr
  ) internal pure returns (int112 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int120 at `rdPtr` in returndata.
  function readInt120(
    ReturndataPointer rdPtr
  ) internal pure returns (int120 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int128 at `rdPtr` in returndata.
  function readInt128(
    ReturndataPointer rdPtr
  ) internal pure returns (int128 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int136 at `rdPtr` in returndata.
  function readInt136(
    ReturndataPointer rdPtr
  ) internal pure returns (int136 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int144 at `rdPtr` in returndata.
  function readInt144(
    ReturndataPointer rdPtr
  ) internal pure returns (int144 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int152 at `rdPtr` in returndata.
  function readInt152(
    ReturndataPointer rdPtr
  ) internal pure returns (int152 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int160 at `rdPtr` in returndata.
  function readInt160(
    ReturndataPointer rdPtr
  ) internal pure returns (int160 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int168 at `rdPtr` in returndata.
  function readInt168(
    ReturndataPointer rdPtr
  ) internal pure returns (int168 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int176 at `rdPtr` in returndata.
  function readInt176(
    ReturndataPointer rdPtr
  ) internal pure returns (int176 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int184 at `rdPtr` in returndata.
  function readInt184(
    ReturndataPointer rdPtr
  ) internal pure returns (int184 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int192 at `rdPtr` in returndata.
  function readInt192(
    ReturndataPointer rdPtr
  ) internal pure returns (int192 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int200 at `rdPtr` in returndata.
  function readInt200(
    ReturndataPointer rdPtr
  ) internal pure returns (int200 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int208 at `rdPtr` in returndata.
  function readInt208(
    ReturndataPointer rdPtr
  ) internal pure returns (int208 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int216 at `rdPtr` in returndata.
  function readInt216(
    ReturndataPointer rdPtr
  ) internal pure returns (int216 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int224 at `rdPtr` in returndata.
  function readInt224(
    ReturndataPointer rdPtr
  ) internal pure returns (int224 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int232 at `rdPtr` in returndata.
  function readInt232(
    ReturndataPointer rdPtr
  ) internal pure returns (int232 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int240 at `rdPtr` in returndata.
  function readInt240(
    ReturndataPointer rdPtr
  ) internal pure returns (int240 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int248 at `rdPtr` in returndata.
  function readInt248(
    ReturndataPointer rdPtr
  ) internal pure returns (int248 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }

  /// @dev Reads the int256 at `rdPtr` in returndata.
  function readInt256(
    ReturndataPointer rdPtr
  ) internal pure returns (int256 value) {
    assembly {
      returndatacopy(0, rdPtr, _OneWord)
      value := mload(0)
    }
  }
}

library MemoryReaders {
  /// @dev Reads the memory pointer at `mPtr` in memory.
  function readMemoryPointer(
    MemoryPointer mPtr
  ) internal pure returns (MemoryPointer value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads value at `mPtr` & applies a mask to return only last 4 bytes
  function readMaskedUint256(
    MemoryPointer mPtr
  ) internal pure returns (uint256 value) {
    value = mPtr.readUint256() & OffsetOrLengthMask;
  }

  /// @dev Reads the bool at `mPtr` in memory.
  function readBool(MemoryPointer mPtr) internal pure returns (bool value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the address at `mPtr` in memory.
  function readAddress(
    MemoryPointer mPtr
  ) internal pure returns (address value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes1 at `mPtr` in memory.
  function readBytes1(MemoryPointer mPtr) internal pure returns (bytes1 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes2 at `mPtr` in memory.
  function readBytes2(MemoryPointer mPtr) internal pure returns (bytes2 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes3 at `mPtr` in memory.
  function readBytes3(MemoryPointer mPtr) internal pure returns (bytes3 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes4 at `mPtr` in memory.
  function readBytes4(MemoryPointer mPtr) internal pure returns (bytes4 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes5 at `mPtr` in memory.
  function readBytes5(MemoryPointer mPtr) internal pure returns (bytes5 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes6 at `mPtr` in memory.
  function readBytes6(MemoryPointer mPtr) internal pure returns (bytes6 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes7 at `mPtr` in memory.
  function readBytes7(MemoryPointer mPtr) internal pure returns (bytes7 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes8 at `mPtr` in memory.
  function readBytes8(MemoryPointer mPtr) internal pure returns (bytes8 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes9 at `mPtr` in memory.
  function readBytes9(MemoryPointer mPtr) internal pure returns (bytes9 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes10 at `mPtr` in memory.
  function readBytes10(
    MemoryPointer mPtr
  ) internal pure returns (bytes10 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes11 at `mPtr` in memory.
  function readBytes11(
    MemoryPointer mPtr
  ) internal pure returns (bytes11 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes12 at `mPtr` in memory.
  function readBytes12(
    MemoryPointer mPtr
  ) internal pure returns (bytes12 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes13 at `mPtr` in memory.
  function readBytes13(
    MemoryPointer mPtr
  ) internal pure returns (bytes13 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes14 at `mPtr` in memory.
  function readBytes14(
    MemoryPointer mPtr
  ) internal pure returns (bytes14 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes15 at `mPtr` in memory.
  function readBytes15(
    MemoryPointer mPtr
  ) internal pure returns (bytes15 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes16 at `mPtr` in memory.
  function readBytes16(
    MemoryPointer mPtr
  ) internal pure returns (bytes16 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes17 at `mPtr` in memory.
  function readBytes17(
    MemoryPointer mPtr
  ) internal pure returns (bytes17 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes18 at `mPtr` in memory.
  function readBytes18(
    MemoryPointer mPtr
  ) internal pure returns (bytes18 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes19 at `mPtr` in memory.
  function readBytes19(
    MemoryPointer mPtr
  ) internal pure returns (bytes19 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes20 at `mPtr` in memory.
  function readBytes20(
    MemoryPointer mPtr
  ) internal pure returns (bytes20 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes21 at `mPtr` in memory.
  function readBytes21(
    MemoryPointer mPtr
  ) internal pure returns (bytes21 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes22 at `mPtr` in memory.
  function readBytes22(
    MemoryPointer mPtr
  ) internal pure returns (bytes22 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes23 at `mPtr` in memory.
  function readBytes23(
    MemoryPointer mPtr
  ) internal pure returns (bytes23 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes24 at `mPtr` in memory.
  function readBytes24(
    MemoryPointer mPtr
  ) internal pure returns (bytes24 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes25 at `mPtr` in memory.
  function readBytes25(
    MemoryPointer mPtr
  ) internal pure returns (bytes25 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes26 at `mPtr` in memory.
  function readBytes26(
    MemoryPointer mPtr
  ) internal pure returns (bytes26 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes27 at `mPtr` in memory.
  function readBytes27(
    MemoryPointer mPtr
  ) internal pure returns (bytes27 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes28 at `mPtr` in memory.
  function readBytes28(
    MemoryPointer mPtr
  ) internal pure returns (bytes28 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes29 at `mPtr` in memory.
  function readBytes29(
    MemoryPointer mPtr
  ) internal pure returns (bytes29 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes30 at `mPtr` in memory.
  function readBytes30(
    MemoryPointer mPtr
  ) internal pure returns (bytes30 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes31 at `mPtr` in memory.
  function readBytes31(
    MemoryPointer mPtr
  ) internal pure returns (bytes31 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the bytes32 at `mPtr` in memory.
  function readBytes32(
    MemoryPointer mPtr
  ) internal pure returns (bytes32 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint8 at `mPtr` in memory.
  function readUint8(MemoryPointer mPtr) internal pure returns (uint8 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint16 at `mPtr` in memory.
  function readUint16(MemoryPointer mPtr) internal pure returns (uint16 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint24 at `mPtr` in memory.
  function readUint24(MemoryPointer mPtr) internal pure returns (uint24 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint32 at `mPtr` in memory.
  function readUint32(MemoryPointer mPtr) internal pure returns (uint32 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint40 at `mPtr` in memory.
  function readUint40(MemoryPointer mPtr) internal pure returns (uint40 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint48 at `mPtr` in memory.
  function readUint48(MemoryPointer mPtr) internal pure returns (uint48 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint56 at `mPtr` in memory.
  function readUint56(MemoryPointer mPtr) internal pure returns (uint56 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint64 at `mPtr` in memory.
  function readUint64(MemoryPointer mPtr) internal pure returns (uint64 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint72 at `mPtr` in memory.
  function readUint72(MemoryPointer mPtr) internal pure returns (uint72 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint80 at `mPtr` in memory.
  function readUint80(MemoryPointer mPtr) internal pure returns (uint80 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint88 at `mPtr` in memory.
  function readUint88(MemoryPointer mPtr) internal pure returns (uint88 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint96 at `mPtr` in memory.
  function readUint96(MemoryPointer mPtr) internal pure returns (uint96 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint104 at `mPtr` in memory.
  function readUint104(
    MemoryPointer mPtr
  ) internal pure returns (uint104 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint112 at `mPtr` in memory.
  function readUint112(
    MemoryPointer mPtr
  ) internal pure returns (uint112 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint120 at `mPtr` in memory.
  function readUint120(
    MemoryPointer mPtr
  ) internal pure returns (uint120 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint128 at `mPtr` in memory.
  function readUint128(
    MemoryPointer mPtr
  ) internal pure returns (uint128 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint136 at `mPtr` in memory.
  function readUint136(
    MemoryPointer mPtr
  ) internal pure returns (uint136 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint144 at `mPtr` in memory.
  function readUint144(
    MemoryPointer mPtr
  ) internal pure returns (uint144 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint152 at `mPtr` in memory.
  function readUint152(
    MemoryPointer mPtr
  ) internal pure returns (uint152 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint160 at `mPtr` in memory.
  function readUint160(
    MemoryPointer mPtr
  ) internal pure returns (uint160 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint168 at `mPtr` in memory.
  function readUint168(
    MemoryPointer mPtr
  ) internal pure returns (uint168 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint176 at `mPtr` in memory.
  function readUint176(
    MemoryPointer mPtr
  ) internal pure returns (uint176 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint184 at `mPtr` in memory.
  function readUint184(
    MemoryPointer mPtr
  ) internal pure returns (uint184 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint192 at `mPtr` in memory.
  function readUint192(
    MemoryPointer mPtr
  ) internal pure returns (uint192 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint200 at `mPtr` in memory.
  function readUint200(
    MemoryPointer mPtr
  ) internal pure returns (uint200 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint208 at `mPtr` in memory.
  function readUint208(
    MemoryPointer mPtr
  ) internal pure returns (uint208 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint216 at `mPtr` in memory.
  function readUint216(
    MemoryPointer mPtr
  ) internal pure returns (uint216 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint224 at `mPtr` in memory.
  function readUint224(
    MemoryPointer mPtr
  ) internal pure returns (uint224 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint232 at `mPtr` in memory.
  function readUint232(
    MemoryPointer mPtr
  ) internal pure returns (uint232 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint240 at `mPtr` in memory.
  function readUint240(
    MemoryPointer mPtr
  ) internal pure returns (uint240 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint248 at `mPtr` in memory.
  function readUint248(
    MemoryPointer mPtr
  ) internal pure returns (uint248 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the uint256 at `mPtr` in memory.
  function readUint256(
    MemoryPointer mPtr
  ) internal pure returns (uint256 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int8 at `mPtr` in memory.
  function readInt8(MemoryPointer mPtr) internal pure returns (int8 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int16 at `mPtr` in memory.
  function readInt16(MemoryPointer mPtr) internal pure returns (int16 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int24 at `mPtr` in memory.
  function readInt24(MemoryPointer mPtr) internal pure returns (int24 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int32 at `mPtr` in memory.
  function readInt32(MemoryPointer mPtr) internal pure returns (int32 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int40 at `mPtr` in memory.
  function readInt40(MemoryPointer mPtr) internal pure returns (int40 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int48 at `mPtr` in memory.
  function readInt48(MemoryPointer mPtr) internal pure returns (int48 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int56 at `mPtr` in memory.
  function readInt56(MemoryPointer mPtr) internal pure returns (int56 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int64 at `mPtr` in memory.
  function readInt64(MemoryPointer mPtr) internal pure returns (int64 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int72 at `mPtr` in memory.
  function readInt72(MemoryPointer mPtr) internal pure returns (int72 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int80 at `mPtr` in memory.
  function readInt80(MemoryPointer mPtr) internal pure returns (int80 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int88 at `mPtr` in memory.
  function readInt88(MemoryPointer mPtr) internal pure returns (int88 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int96 at `mPtr` in memory.
  function readInt96(MemoryPointer mPtr) internal pure returns (int96 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int104 at `mPtr` in memory.
  function readInt104(MemoryPointer mPtr) internal pure returns (int104 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int112 at `mPtr` in memory.
  function readInt112(MemoryPointer mPtr) internal pure returns (int112 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int120 at `mPtr` in memory.
  function readInt120(MemoryPointer mPtr) internal pure returns (int120 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int128 at `mPtr` in memory.
  function readInt128(MemoryPointer mPtr) internal pure returns (int128 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int136 at `mPtr` in memory.
  function readInt136(MemoryPointer mPtr) internal pure returns (int136 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int144 at `mPtr` in memory.
  function readInt144(MemoryPointer mPtr) internal pure returns (int144 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int152 at `mPtr` in memory.
  function readInt152(MemoryPointer mPtr) internal pure returns (int152 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int160 at `mPtr` in memory.
  function readInt160(MemoryPointer mPtr) internal pure returns (int160 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int168 at `mPtr` in memory.
  function readInt168(MemoryPointer mPtr) internal pure returns (int168 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int176 at `mPtr` in memory.
  function readInt176(MemoryPointer mPtr) internal pure returns (int176 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int184 at `mPtr` in memory.
  function readInt184(MemoryPointer mPtr) internal pure returns (int184 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int192 at `mPtr` in memory.
  function readInt192(MemoryPointer mPtr) internal pure returns (int192 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int200 at `mPtr` in memory.
  function readInt200(MemoryPointer mPtr) internal pure returns (int200 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int208 at `mPtr` in memory.
  function readInt208(MemoryPointer mPtr) internal pure returns (int208 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int216 at `mPtr` in memory.
  function readInt216(MemoryPointer mPtr) internal pure returns (int216 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int224 at `mPtr` in memory.
  function readInt224(MemoryPointer mPtr) internal pure returns (int224 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int232 at `mPtr` in memory.
  function readInt232(MemoryPointer mPtr) internal pure returns (int232 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int240 at `mPtr` in memory.
  function readInt240(MemoryPointer mPtr) internal pure returns (int240 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int248 at `mPtr` in memory.
  function readInt248(MemoryPointer mPtr) internal pure returns (int248 value) {
    assembly {
      value := mload(mPtr)
    }
  }

  /// @dev Reads the int256 at `mPtr` in memory.
  function readInt256(MemoryPointer mPtr) internal pure returns (int256 value) {
    assembly {
      value := mload(mPtr)
    }
  }
}

library MemoryWriters {
  /// @dev Writes `valuePtr` to memory at `mPtr`.
  function write(MemoryPointer mPtr, MemoryPointer valuePtr) internal pure {
    assembly {
      mstore(mPtr, valuePtr)
    }
  }

  /// @dev Writes a boolean `value` to `mPtr` in memory.
  function write(MemoryPointer mPtr, bool value) internal pure {
    assembly {
      mstore(mPtr, value)
    }
  }

  /// @dev Writes an address `value` to `mPtr` in memory.
  function write(MemoryPointer mPtr, address value) internal pure {
    assembly {
      mstore(mPtr, value)
    }
  }

  /// @dev Writes a bytes32 `value` to `mPtr` in memory.
  /// Separate name to disambiguate literal write parameters.
  function writeBytes32(MemoryPointer mPtr, bytes32 value) internal pure {
    assembly {
      mstore(mPtr, value)
    }
  }

  /// @dev Writes a uint256 `value` to `mPtr` in memory.
  function write(MemoryPointer mPtr, uint256 value) internal pure {
    assembly {
      mstore(mPtr, value)
    }
  }

  /// @dev Writes an int256 `value` to `mPtr` in memory.
  /// Separate name to disambiguate literal write parameters.
  function writeInt(MemoryPointer mPtr, int256 value) internal pure {
    assembly {
      mstore(mPtr, value)
    }
  }
}

/**
 * @dev An order contains eleven components: an offerer, a zone (or account that
 *      can cancel the order or restrict who can fulfill the order depending on
 *      the type), the order type (specifying partial fill support as well as
 *      restricted order status), the start and end time, a hash that will be
 *      provided to the zone when validating restricted orders, a salt, a key
 *      corresponding to a given conduit, a counter, and an arbitrary number of
 *      offer items that can be spent along with consideration items that must
 *      be received by their respective recipient.
 */
struct OrderComponents {
  address offerer;
  address zone;
  OfferItem[] offer;
  ConsiderationItem[] consideration;
  OrderType orderType;
  uint256 startTime;
  uint256 endTime;
  bytes32 zoneHash;
  uint256 salt;
  bytes32 conduitKey;
  uint256 counter;
}

/**
 * @dev An offer item has five components: an item type (ETH or other native
 *      tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
 *      ERC1155), a token address, a dual-purpose "identifierOrCriteria"
 *      component that will either represent a tokenId or a merkle root
 *      depending on the item type, and a start and end amount that support
 *      increasing or decreasing amounts over the duration of the respective
 *      order.
 */
struct OfferItem {
  ItemType itemType;
  address token;
  uint256 identifierOrCriteria;
  uint256 startAmount;
  uint256 endAmount;
}

/**
 * @dev A consideration item has the same five components as an offer item and
 *      an additional sixth component designating the required recipient of the
 *      item.
 */
struct ConsiderationItem {
  ItemType itemType;
  address token;
  uint256 identifierOrCriteria;
  uint256 startAmount;
  uint256 endAmount;
  address payable recipient;
}

/**
 * @dev A spent item is translated from a utilized offer item and has four
 *      components: an item type (ETH or other native tokens, ERC20, ERC721, and
 *      ERC1155), a token address, a tokenId, and an amount.
 */
struct SpentItem {
  ItemType itemType;
  address token;
  uint256 identifier;
  uint256 amount;
}

/**
 * @dev A received item is translated from a utilized consideration item and has
 *      the same four components as a spent item, as well as an additional fifth
 *      component designating the required recipient of the item.
 */
struct ReceivedItem {
  ItemType itemType;
  address token;
  uint256 identifier;
  uint256 amount;
  address payable recipient;
}

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 *      matching, a group of six functions may be called that only requires a
 *      subset of the usual order arguments. Note the use of a "basicOrderType"
 *      enum; this represents both the usual order type as well as the "route"
 *      of the basic order (a simple derivation function for the basic order
 *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
struct BasicOrderParameters {
  // calldata offset
  address considerationToken; // 0x24
  uint256 considerationIdentifier; // 0x44
  uint256 considerationAmount; // 0x64
  address payable offerer; // 0x84
  address zone; // 0xa4
  address offerToken; // 0xc4
  uint256 offerIdentifier; // 0xe4
  uint256 offerAmount; // 0x104
  BasicOrderType basicOrderType; // 0x124
  uint256 startTime; // 0x144
  uint256 endTime; // 0x164
  bytes32 zoneHash; // 0x184
  uint256 salt; // 0x1a4
  bytes32 offererConduitKey; // 0x1c4
  bytes32 fulfillerConduitKey; // 0x1e4
  uint256 totalOriginalAdditionalRecipients; // 0x204
  AdditionalRecipient[] additionalRecipients; // 0x224
  bytes signature; // 0x244
  // Total length, excluding dynamic array data: 0x264 (580)
}

/**
 * @dev Basic orders can supply any number of additional recipients, with the
 *      implied assumption that they are supplied from the offered ETH (or other
 *      native token) or ERC20 token for the order.
 */
struct AdditionalRecipient {
  uint256 amount;
  address payable recipient;
}

/**
 * @dev The full set of order components, with the exception of the counter,
 *      must be supplied when fulfilling more sophisticated orders or groups of
 *      orders. The total number of original consideration items must also be
 *      supplied, as the caller may specify additional consideration items.
 */
struct OrderParameters {
  address offerer; // 0x00
  address zone; // 0x20
  OfferItem[] offer; // 0x40
  ConsiderationItem[] consideration; // 0x60
  OrderType orderType; // 0x80
  uint256 startTime; // 0xa0
  uint256 endTime; // 0xc0
  bytes32 zoneHash; // 0xe0
  uint256 salt; // 0x100
  bytes32 conduitKey; // 0x120
  uint256 totalOriginalConsiderationItems; // 0x140
  // offer.length                          // 0x160
}

/**
 * @dev Orders require a signature in addition to the other order parameters.
 */
struct Order {
  OrderParameters parameters;
  bytes signature;
}

/**
 * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
 *      and a denominator (the total size of the order) in addition to the
 *      signature and other order parameters. It also supports an optional field
 *      for supplying extra data; this data will be provided to the zone if the
 *      order type is restricted and the zone is not the caller, or will be
 *      provided to the offerer as context for contract order types.
 */
struct AdvancedOrder {
  OrderParameters parameters;
  uint120 numerator;
  uint120 denominator;
  bytes signature;
  bytes extraData;
}

/**
 * @dev Orders can be validated (either explicitly via `validate`, or as a
 *      consequence of a full or partial fill), specifically cancelled (they can
 *      also be cancelled in bulk via incrementing a per-zone counter), and
 *      partially or fully filled (with the fraction filled represented by a
 *      numerator and denominator).
 */
struct OrderStatus {
  bool isValidated;
  bool isCancelled;
  uint120 numerator;
  uint120 denominator;
}

/**
 * @dev A criteria resolver specifies an order, side (offer vs. consideration),
 *      and item index. It then provides a chosen identifier (i.e. tokenId)
 *      alongside a merkle proof demonstrating the identifier meets the required
 *      criteria.
 */
struct CriteriaResolver {
  uint256 orderIndex;
  Side side;
  uint256 index;
  uint256 identifier;
  bytes32[] criteriaProof;
}

/**
 * @dev A fulfillment is applied to a group of orders. It decrements a series of
 *      offer and consideration items, then generates a single execution
 *      element. A given fulfillment can be applied to as many offer and
 *      consideration items as desired, but must contain at least one offer and
 *      at least one consideration that match. The fulfillment must also remain
 *      consistent on all key parameters across all offer items (same offerer,
 *      token, type, tokenId, and conduit preference) as well as across all
 *      consideration items (token, type, tokenId, and recipient).
 */
struct Fulfillment {
  FulfillmentComponent[] offerComponents;
  FulfillmentComponent[] considerationComponents;
}

/**
 * @dev Each fulfillment component contains one index referencing a specific
 *      order and another referencing a specific offer or consideration item.
 */
struct FulfillmentComponent {
  uint256 orderIndex;
  uint256 itemIndex;
}

/**
 * @dev An execution is triggered once all consideration items have been zeroed
 *      out. It sends the item in question from the offerer to the item's
 *      recipient, optionally sourcing approvals from either this contract
 *      directly or from the offerer's chosen conduit if one is specified. An
 *      execution is not provided as an argument, but rather is derived via
 *      orders, criteria resolvers, and fulfillments (where the total number of
 *      executions will be less than or equal to the total number of indicated
 *      fulfillments) and returned as part of `matchOrders`.
 */
struct Execution {
  ReceivedItem item;
  address offerer;
  bytes32 conduitKey;
}

/**
 * @dev Restricted orders are validated post-execution by calling validateOrder
 *      on the zone. This struct provides context about the order fulfillment
 *      and any supplied extraData, as well as all order hashes fulfilled in a
 *      call to a match or fulfillAvailable method.
 */
struct ZoneParameters {
  bytes32 orderHash;
  address fulfiller;
  address offerer;
  SpentItem[] offer;
  ReceivedItem[] consideration;
  bytes extraData;
  bytes32[] orderHashes;
  uint256 startTime;
  uint256 endTime;
  bytes32 zoneHash;
}

/**
 * @dev Zones and contract offerers can communicate which schemas they implement
 *      along with any associated metadata related to each schema.
 */
struct Schema {
  uint256 id;
  bytes metadata;
}

using StructPointers for OrderComponents global;
using StructPointers for OfferItem global;
using StructPointers for ConsiderationItem global;
using StructPointers for SpentItem global;
using StructPointers for ReceivedItem global;
using StructPointers for BasicOrderParameters global;
using StructPointers for AdditionalRecipient global;
using StructPointers for OrderParameters global;
using StructPointers for Order global;
using StructPointers for AdvancedOrder global;
using StructPointers for OrderStatus global;
using StructPointers for CriteriaResolver global;
using StructPointers for Fulfillment global;
using StructPointers for FulfillmentComponent global;
using StructPointers for Execution global;
using StructPointers for ZoneParameters global;

/**
 * @dev This library provides a set of functions for converting structs to
 *      pointers.
 */
library StructPointers {
  /**
   * @dev Get a MemoryPointer from OrderComponents.
   *
   * @param obj The OrderComponents object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    OrderComponents memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from OrderComponents.
   *
   * @param obj The OrderComponents object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    OrderComponents calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from OfferItem.
   *
   * @param obj The OfferItem object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    OfferItem memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from OfferItem.
   *
   * @param obj The OfferItem object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    OfferItem calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from ConsiderationItem.
   *
   * @param obj The ConsiderationItem object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    ConsiderationItem memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from ConsiderationItem.
   *
   * @param obj The ConsiderationItem object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    ConsiderationItem calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from SpentItem.
   *
   * @param obj The SpentItem object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    SpentItem memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from SpentItem.
   *
   * @param obj The SpentItem object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    SpentItem calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from ReceivedItem.
   *
   * @param obj The ReceivedItem object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    ReceivedItem memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from ReceivedItem.
   *
   * @param obj The ReceivedItem object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    ReceivedItem calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from BasicOrderParameters.
   *
   * @param obj The BasicOrderParameters object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    BasicOrderParameters memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from BasicOrderParameters.
   *
   * @param obj The BasicOrderParameters object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    BasicOrderParameters calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from AdditionalRecipient.
   *
   * @param obj The AdditionalRecipient object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    AdditionalRecipient memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from AdditionalRecipient.
   *
   * @param obj The AdditionalRecipient object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    AdditionalRecipient calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from OrderParameters.
   *
   * @param obj The OrderParameters object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    OrderParameters memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from OrderParameters.
   *
   * @param obj The OrderParameters object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    OrderParameters calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from Order.
   *
   * @param obj The Order object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    Order memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from Order.
   *
   * @param obj The Order object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    Order calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from AdvancedOrder.
   *
   * @param obj The AdvancedOrder object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    AdvancedOrder memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from AdvancedOrder.
   *
   * @param obj The AdvancedOrder object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    AdvancedOrder calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from OrderStatus.
   *
   * @param obj The OrderStatus object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    OrderStatus memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from OrderStatus.
   *
   * @param obj The OrderStatus object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    OrderStatus calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from CriteriaResolver.
   *
   * @param obj The CriteriaResolver object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    CriteriaResolver memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from CriteriaResolver.
   *
   * @param obj The CriteriaResolver object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    CriteriaResolver calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from Fulfillment.
   *
   * @param obj The Fulfillment object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    Fulfillment memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from Fulfillment.
   *
   * @param obj The Fulfillment object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    Fulfillment calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from FulfillmentComponent.
   *
   * @param obj The FulfillmentComponent object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    FulfillmentComponent memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from FulfillmentComponent.
   *
   * @param obj The FulfillmentComponent object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    FulfillmentComponent calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from Execution.
   *
   * @param obj The Execution object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    Execution memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from Execution.
   *
   * @param obj The Execution object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    Execution calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a MemoryPointer from ZoneParameters.
   *
   * @param obj The ZoneParameters object.
   *
   * @return ptr The MemoryPointer.
   */
  function toMemoryPointer(
    ZoneParameters memory obj
  ) internal pure returns (MemoryPointer ptr) {
    assembly {
      ptr := obj
    }
  }

  /**
   * @dev Get a CalldataPointer from ZoneParameters.
   *
   * @param obj The ZoneParameters object.
   *
   * @return ptr The CalldataPointer.
   */
  function toCalldataPointer(
    ZoneParameters calldata obj
  ) internal pure returns (CalldataPointer ptr) {
    assembly {
      ptr := obj
    }
  }
}

/**
 * @title ConsiderationInterface
 * @author 0age
 * @custom:version 1.5
 * @notice Consideration is a generalized native token/ERC20/ERC721/ERC1155
 *         marketplace. It minimizes external calls to the greatest extent
 *         possible and provides lightweight methods for common routes as well
 *         as more flexible methods for composing advanced orders.
 *
 * @dev ConsiderationInterface contains all external function interfaces for
 *      Consideration.
 */
interface ConsiderationInterface {
  /**
   * @notice Fulfill an order offering an ERC721 token by supplying Ether (or
   *         the native token for the given chain) as consideration for the
   *         order. An arbitrary number of "additional recipients" may also be
   *         supplied which will each receive native tokens from the fulfiller
   *         as consideration.
   *
   * @param parameters Additional information on the fulfilled order. Note
   *                   that the offerer must first approve this contract (or
   *                   their preferred conduit if indicated by the order) for
   *                   their offered ERC721 token to be transferred.
   *
   * @return fulfilled A boolean indicating whether the order has been
   *                   successfully fulfilled.
   */
  function fulfillBasicOrder(
    BasicOrderParameters calldata parameters
  ) external payable returns (bool fulfilled);

  /**
   * @notice Fulfill an order with an arbitrary number of items for offer and
   *         consideration. Note that this function does not support
   *         criteria-based orders or partial filling of orders (though
   *         filling the remainder of a partially-filled order is supported).
   *
   * @param order               The order to fulfill. Note that both the
   *                            offerer and the fulfiller must first approve
   *                            this contract (or the corresponding conduit if
   *                            indicated) to transfer any relevant tokens on
   *                            their behalf and that contracts must implement
   *                            `onERC1155Received` to receive ERC1155 tokens
   *                            as consideration.
   * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
   *                            any, to source the fulfiller's token approvals
   *                            from. The zero hash signifies that no conduit
   *                            should be used, with direct approvals set on
   *                            Consideration.
   *
   * @return fulfilled A boolean indicating whether the order has been
   *                   successfully fulfilled.
   */
  function fulfillOrder(
    Order calldata order,
    bytes32 fulfillerConduitKey
  ) external payable returns (bool fulfilled);

  /**
   * @notice Fill an order, fully or partially, with an arbitrary number of
   *         items for offer and consideration alongside criteria resolvers
   *         containing specific token identifiers and associated proofs.
   *
   * @param advancedOrder       The order to fulfill along with the fraction
   *                            of the order to attempt to fill. Note that
   *                            both the offerer and the fulfiller must first
   *                            approve this contract (or their preferred
   *                            conduit if indicated by the order) to transfer
   *                            any relevant tokens on their behalf and that
   *                            contracts must implement `onERC1155Received`
   *                            to receive ERC1155 tokens as consideration.
   *                            Also note that all offer and consideration
   *                            components must have no remainder after
   *                            multiplication of the respective amount with
   *                            the supplied fraction for the partial fill to
   *                            be considered valid.
   * @param criteriaResolvers   An array where each element contains a
   *                            reference to a specific offer or
   *                            consideration, a token identifier, and a proof
   *                            that the supplied token identifier is
   *                            contained in the merkle root held by the item
   *                            in question's criteria element. Note that an
   *                            empty criteria indicates that any
   *                            (transferable) token identifier on the token
   *                            in question is valid and that no associated
   *                            proof needs to be supplied.
   * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
   *                            any, to source the fulfiller's token approvals
   *                            from. The zero hash signifies that no conduit
   *                            should be used, with direct approvals set on
   *                            Consideration.
   * @param recipient           The intended recipient for all received items,
   *                            with `address(0)` indicating that the caller
   *                            should receive the items.
   *
   * @return fulfilled A boolean indicating whether the order has been
   *                   successfully fulfilled.
   */
  function fulfillAdvancedOrder(
    AdvancedOrder calldata advancedOrder,
    CriteriaResolver[] calldata criteriaResolvers,
    bytes32 fulfillerConduitKey,
    address recipient
  ) external payable returns (bool fulfilled);

  /**
   * @notice Attempt to fill a group of orders, each with an arbitrary number
   *         of items for offer and consideration. Any order that is not
   *         currently active, has already been fully filled, or has been
   *         cancelled will be omitted. Remaining offer and consideration
   *         items will then be aggregated where possible as indicated by the
   *         supplied offer and consideration component arrays and aggregated
   *         items will be transferred to the fulfiller or to each intended
   *         recipient, respectively. Note that a failing item transfer or an
   *         issue with order formatting will cause the entire batch to fail.
   *         Note that this function does not support criteria-based orders or
   *         partial filling of orders (though filling the remainder of a
   *         partially-filled order is supported).
   *
   * @param orders                    The orders to fulfill. Note that both
   *                                  the offerer and the fulfiller must first
   *                                  approve this contract (or the
   *                                  corresponding conduit if indicated) to
   *                                  transfer any relevant tokens on their
   *                                  behalf and that contracts must implement
   *                                  `onERC1155Received` to receive ERC1155
   *                                  tokens as consideration.
   * @param offerFulfillments         An array of FulfillmentComponent arrays
   *                                  indicating which offer items to attempt
   *                                  to aggregate when preparing executions.
   * @param considerationFulfillments An array of FulfillmentComponent arrays
   *                                  indicating which consideration items to
   *                                  attempt to aggregate when preparing
   *                                  executions.
   * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
   *                                  if any, to source the fulfiller's token
   *                                  approvals from. The zero hash signifies
   *                                  that no conduit should be used, with
   *                                  direct approvals set on this contract.
   * @param maximumFulfilled          The maximum number of orders to fulfill.
   *
   * @return availableOrders An array of booleans indicating if each order
   *                         with an index corresponding to the index of the
   *                         returned boolean was fulfillable or not.
   * @return executions      An array of elements indicating the sequence of
   *                         transfers performed as part of matching the given
   *                         orders. Note that unspent offer item amounts or
   *                         native tokens will not be reflected as part of
   *                         this array.
   */
  function fulfillAvailableOrders(
    Order[] calldata orders,
    FulfillmentComponent[][] calldata offerFulfillments,
    FulfillmentComponent[][] calldata considerationFulfillments,
    bytes32 fulfillerConduitKey,
    uint256 maximumFulfilled
  )
    external
    payable
    returns (bool[] memory availableOrders, Execution[] memory executions);

  /**
   * @notice Attempt to fill a group of orders, fully or partially, with an
   *         arbitrary number of items for offer and consideration per order
   *         alongside criteria resolvers containing specific token
   *         identifiers and associated proofs. Any order that is not
   *         currently active, has already been fully filled, or has been
   *         cancelled will be omitted. Remaining offer and consideration
   *         items will then be aggregated where possible as indicated by the
   *         supplied offer and consideration component arrays and aggregated
   *         items will be transferred to the fulfiller or to each intended
   *         recipient, respectively. Note that a failing item transfer or an
   *         issue with order formatting will cause the entire batch to fail.
   *
   * @param advancedOrders            The orders to fulfill along with the
   *                                  fraction of those orders to attempt to
   *                                  fill. Note that both the offerer and the
   *                                  fulfiller must first approve this
   *                                  contract (or their preferred conduit if
   *                                  indicated by the order) to transfer any
   *                                  relevant tokens on their behalf and that
   *                                  contracts must implement
   *                                  `onERC1155Received` to enable receipt of
   *                                  ERC1155 tokens as consideration. Also
   *                                  note that all offer and consideration
   *                                  components must have no remainder after
   *                                  multiplication of the respective amount
   *                                  with the supplied fraction for an
   *                                  order's partial fill amount to be
   *                                  considered valid.
   * @param criteriaResolvers         An array where each element contains a
   *                                  reference to a specific offer or
   *                                  consideration, a token identifier, and a
   *                                  proof that the supplied token identifier
   *                                  is contained in the merkle root held by
   *                                  the item in question's criteria element.
   *                                  Note that an empty criteria indicates
   *                                  that any (transferable) token
   *                                  identifier on the token in question is
   *                                  valid and that no associated proof needs
   *                                  to be supplied.
   * @param offerFulfillments         An array of FulfillmentComponent arrays
   *                                  indicating which offer items to attempt
   *                                  to aggregate when preparing executions.
   * @param considerationFulfillments An array of FulfillmentComponent arrays
   *                                  indicating which consideration items to
   *                                  attempt to aggregate when preparing
   *                                  executions.
   * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
   *                                  if any, to source the fulfiller's token
   *                                  approvals from. The zero hash signifies
   *                                  that no conduit should be used, with
   *                                  direct approvals set on this contract.
   * @param recipient                 The intended recipient for all received
   *                                  items, with `address(0)` indicating that
   *                                  the caller should receive the items.
   * @param maximumFulfilled          The maximum number of orders to fulfill.
   *
   * @return availableOrders An array of booleans indicating if each order
   *                         with an index corresponding to the index of the
   *                         returned boolean was fulfillable or not.
   * @return executions      An array of elements indicating the sequence of
   *                         transfers performed as part of matching the given
   *                         orders. Note that unspent offer item amounts or
   *                         native tokens will not be reflected as part of
   *                         this array.
   */
  function fulfillAvailableAdvancedOrders(
    AdvancedOrder[] calldata advancedOrders,
    CriteriaResolver[] calldata criteriaResolvers,
    FulfillmentComponent[][] calldata offerFulfillments,
    FulfillmentComponent[][] calldata considerationFulfillments,
    bytes32 fulfillerConduitKey,
    address recipient,
    uint256 maximumFulfilled
  )
    external
    payable
    returns (bool[] memory availableOrders, Execution[] memory executions);

  /**
   * @notice Match an arbitrary number of orders, each with an arbitrary
   *         number of items for offer and consideration along with a set of
   *         fulfillments allocating offer components to consideration
   *         components. Note that this function does not support
   *         criteria-based or partial filling of orders (though filling the
   *         remainder of a partially-filled order is supported). Any unspent
   *         offer item amounts or native tokens will be transferred to the
   *         caller.
   *
   * @param orders       The orders to match. Note that both the offerer and
   *                     fulfiller on each order must first approve this
   *                     contract (or their conduit if indicated by the order)
   *                     to transfer any relevant tokens on their behalf and
   *                     each consideration recipient must implement
   *                     `onERC1155Received` to enable ERC1155 token receipt.
   * @param fulfillments An array of elements allocating offer components to
   *                     consideration components. Note that each
   *                     consideration component must be fully met for the
   *                     match operation to be valid.
   *
   * @return executions An array of elements indicating the sequence of
   *                    transfers performed as part of matching the given
   *                    orders. Note that unspent offer item amounts or
   *                    native tokens will not be reflected as part of this
   *                    array.
   */
  function matchOrders(
    Order[] calldata orders,
    Fulfillment[] calldata fulfillments
  ) external payable returns (Execution[] memory executions);

  /**
   * @notice Match an arbitrary number of full or partial orders, each with an
   *         arbitrary number of items for offer and consideration, supplying
   *         criteria resolvers containing specific token identifiers and
   *         associated proofs as well as fulfillments allocating offer
   *         components to consideration components. Any unspent offer item
   *         amounts will be transferred to the designated recipient (with the
   *         null address signifying to use the caller) and any unspent native
   *         tokens will be returned to the caller.
   *
   * @param orders            The advanced orders to match. Note that both the
   *                          offerer and fulfiller on each order must first
   *                          approve this contract (or a preferred conduit if
   *                          indicated by the order) to transfer any relevant
   *                          tokens on their behalf and each consideration
   *                          recipient must implement `onERC1155Received` in
   *                          order to receive ERC1155 tokens. Also note that
   *                          the offer and consideration components for each
   *                          order must have no remainder after multiplying
   *                          the respective amount with the supplied fraction
   *                          in order for the group of partial fills to be
   *                          considered valid.
   * @param criteriaResolvers An array where each element contains a reference
   *                          to a specific order as well as that order's
   *                          offer or consideration, a token identifier, and
   *                          a proof that the supplied token identifier is
   *                          contained in the order's merkle root. Note that
   *                          an empty root indicates that any (transferable)
   *                          token identifier is valid and that no associated
   *                          proof needs to be supplied.
   * @param fulfillments      An array of elements allocating offer components
   *                          to consideration components. Note that each
   *                          consideration component must be fully met in
   *                          order for the match operation to be valid.
   * @param recipient         The intended recipient for all unspent offer
   *                          item amounts, or the caller if the null address
   *                          is supplied.
   *
   * @return executions An array of elements indicating the sequence of
   *                    transfers performed as part of matching the given
   *                    orders. Note that unspent offer item amounts or native
   *                    tokens will not be reflected as part of this array.
   */
  function matchAdvancedOrders(
    AdvancedOrder[] calldata orders,
    CriteriaResolver[] calldata criteriaResolvers,
    Fulfillment[] calldata fulfillments,
    address recipient
  ) external payable returns (Execution[] memory executions);

  /**
   * @notice Cancel an arbitrary number of orders. Note that only the offerer
   *         or the zone of a given order may cancel it. Callers should ensure
   *         that the intended order was cancelled by calling `getOrderStatus`
   *         and confirming that `isCancelled` returns `true`.
   *
   * @param orders The orders to cancel.
   *
   * @return cancelled A boolean indicating whether the supplied orders have
   *                   been successfully cancelled.
   */
  function cancel(
    OrderComponents[] calldata orders
  ) external returns (bool cancelled);

  /**
   * @notice Validate an arbitrary number of orders, thereby registering their
   *         signatures as valid and allowing the fulfiller to skip signature
   *         verification on fulfillment. Note that validated orders may still
   *         be unfulfillable due to invalid item amounts or other factors;
   *         callers should determine whether validated orders are fulfillable
   *         by simulating the fulfillment call prior to execution. Also note
   *         that anyone can validate a signed order, but only the offerer can
   *         validate an order without supplying a signature.
   *
   * @param orders The orders to validate.
   *
   * @return validated A boolean indicating whether the supplied orders have
   *                   been successfully validated.
   */
  function validate(Order[] calldata orders) external returns (bool validated);

  /**
   * @notice Cancel all orders from a given offerer with a given zone in bulk
   *         by incrementing a counter. Note that only the offerer may
   *         increment the counter.
   *
   * @return newCounter The new counter.
   */
  function incrementCounter() external returns (uint256 newCounter);

  /**
   * @notice Fulfill an order offering an ERC721 token by supplying Ether (or
   *         the native token for the given chain) as consideration for the
   *         order. An arbitrary number of "additional recipients" may also be
   *         supplied which will each receive native tokens from the fulfiller
   *         as consideration. Note that this function costs less gas than
   *         `fulfillBasicOrder` due to the zero bytes in the function
   *         selector (0x00000000) which also results in earlier function
   *         dispatch.
   *
   * @param parameters Additional information on the fulfilled order. Note
   *                   that the offerer must first approve this contract (or
   *                   their preferred conduit if indicated by the order) for
   *                   their offered ERC721 token to be transferred.
   *
   * @return fulfilled A boolean indicating whether the order has been
   *                   successfully fulfilled.
   */
  function fulfillBasicOrder_efficient_6GL6yc(
    BasicOrderParameters calldata parameters
  ) external payable returns (bool fulfilled);

  /**
   * @notice Retrieve the order hash for a given order.
   *
   * @param order The components of the order.
   *
   * @return orderHash The order hash.
   */
  function getOrderHash(
    OrderComponents calldata order
  ) external view returns (bytes32 orderHash);

  /**
   * @notice Retrieve the status of a given order by hash, including whether
   *         the order has been cancelled or validated and the fraction of the
   *         order that has been filled.
   *
   * @param orderHash The order hash in question.
   *
   * @return isValidated A boolean indicating whether the order in question
   *                     has been validated (i.e. previously approved or
   *                     partially filled).
   * @return isCancelled A boolean indicating whether the order in question
   *                     has been cancelled.
   * @return totalFilled The total portion of the order that has been filled
   *                     (i.e. the "numerator").
   * @return totalSize   The total size of the order that is either filled or
   *                     unfilled (i.e. the "denominator").
   */
  function getOrderStatus(
    bytes32 orderHash
  )
    external
    view
    returns (
      bool isValidated,
      bool isCancelled,
      uint256 totalFilled,
      uint256 totalSize
    );

  /**
   * @notice Retrieve the current counter for a given offerer.
   *
   * @param offerer The offerer in question.
   *
   * @return counter The current counter.
   */
  function getCounter(address offerer) external view returns (uint256 counter);

  /**
   * @notice Retrieve configuration information for this contract.
   *
   * @return version           The contract version.
   * @return domainSeparator   The domain separator for this contract.
   * @return conduitController The conduit Controller set for this contract.
   */
  function information()
    external
    view
    returns (
      string memory version,
      bytes32 domainSeparator,
      address conduitController
    );

  function getContractOffererNonce(
    address contractOfferer
  ) external view returns (uint256 nonce);

  /**
   * @notice Retrieve the name of this contract.
   *
   * @return contractName The name of this contract.
   */
  function name() external view returns (string memory contractName);
}

/**
 * @title ConduitControllerInterface
 * @author 0age
 * @notice ConduitControllerInterface contains all external function interfaces,
 *         structs, events, and errors for the conduit controller.
 */
interface ConduitControllerInterface {
  /**
   * @dev Track the conduit key, current owner, new potential owner, and open
   *      channels for each deployed conduit.
   */
  struct ConduitProperties {
    bytes32 key;
    address owner;
    address potentialOwner;
    address[] channels;
    mapping(address => uint256) channelIndexesPlusOne;
  }

  /**
   * @dev Emit an event whenever a new conduit is created.
   *
   * @param conduit    The newly created conduit.
   * @param conduitKey The conduit key used to create the new conduit.
   */
  event NewConduit(address conduit, bytes32 conduitKey);

  /**
   * @dev Emit an event whenever conduit ownership is transferred.
   *
   * @param conduit       The conduit for which ownership has been
   *                      transferred.
   * @param previousOwner The previous owner of the conduit.
   * @param newOwner      The new owner of the conduit.
   */
  event OwnershipTransferred(
    address indexed conduit,
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Emit an event whenever a conduit owner registers a new potential
   *      owner for that conduit.
   *
   * @param newPotentialOwner The new potential owner of the conduit.
   */
  event PotentialOwnerUpdated(address indexed newPotentialOwner);

  /**
   * @dev Revert with an error when attempting to create a new conduit using a
   *      conduit key where the first twenty bytes of the key do not match the
   *      address of the caller.
   */
  error InvalidCreator();

  /**
   * @dev Revert with an error when attempting to create a new conduit when no
   *      initial owner address is supplied.
   */
  error InvalidInitialOwner();

  /**
   * @dev Revert with an error when attempting to set a new potential owner
   *      that is already set.
   */
  error NewPotentialOwnerAlreadySet(address conduit, address newPotentialOwner);

  /**
   * @dev Revert with an error when attempting to cancel ownership transfer
   *      when no new potential owner is currently set.
   */
  error NoPotentialOwnerCurrentlySet(address conduit);

  /**
   * @dev Revert with an error when attempting to interact with a conduit that
   *      does not yet exist.
   */
  error NoConduit();

  /**
   * @dev Revert with an error when attempting to create a conduit that
   *      already exists.
   */
  error ConduitAlreadyExists(address conduit);

  /**
   * @dev Revert with an error when attempting to update channels or transfer
   *      ownership of a conduit when the caller is not the owner of the
   *      conduit in question.
   */
  error CallerIsNotOwner(address conduit);

  /**
   * @dev Revert with an error when attempting to register a new potential
   *      owner and supplying the null address.
   */
  error NewPotentialOwnerIsZeroAddress(address conduit);

  /**
   * @dev Revert with an error when attempting to claim ownership of a conduit
   *      with a caller that is not the current potential owner for the
   *      conduit in question.
   */
  error CallerIsNotNewPotentialOwner(address conduit);

  /**
   * @dev Revert with an error when attempting to retrieve a channel using an
   *      index that is out of range.
   */
  error ChannelOutOfRange(address conduit);

  /**
   * @notice Deploy a new conduit using a supplied conduit key and assigning
   *         an initial owner for the deployed conduit. Note that the first
   *         twenty bytes of the supplied conduit key must match the caller
   *         and that a new conduit cannot be created if one has already been
   *         deployed using the same conduit key.
   *
   * @param conduitKey   The conduit key used to deploy the conduit. Note that
   *                     the first twenty bytes of the conduit key must match
   *                     the caller of this contract.
   * @param initialOwner The initial owner to set for the new conduit.
   *
   * @return conduit The address of the newly deployed conduit.
   */
  function createConduit(
    bytes32 conduitKey,
    address initialOwner
  ) external returns (address conduit);

  /**
   * @notice Open or close a channel on a given conduit, thereby allowing the
   *         specified account to execute transfers against that conduit.
   *         Extreme care must be taken when updating channels, as malicious
   *         or vulnerable channels can transfer any ERC20, ERC721 and ERC1155
   *         tokens where the token holder has granted the conduit approval.
   *         Only the owner of the conduit in question may call this function.
   *
   * @param conduit The conduit for which to open or close the channel.
   * @param channel The channel to open or close on the conduit.
   * @param isOpen  A boolean indicating whether to open or close the channel.
   */
  function updateChannel(
    address conduit,
    address channel,
    bool isOpen
  ) external;

  /**
   * @notice Initiate conduit ownership transfer by assigning a new potential
   *         owner for the given conduit. Once set, the new potential owner
   *         may call `acceptOwnership` to claim ownership of the conduit.
   *         Only the owner of the conduit in question may call this function.
   *
   * @param conduit The conduit for which to initiate ownership transfer.
   * @param newPotentialOwner The new potential owner of the conduit.
   */
  function transferOwnership(
    address conduit,
    address newPotentialOwner
  ) external;

  /**
   * @notice Clear the currently set potential owner, if any, from a conduit.
   *         Only the owner of the conduit in question may call this function.
   *
   * @param conduit The conduit for which to cancel ownership transfer.
   */
  function cancelOwnershipTransfer(address conduit) external;

  /**
   * @notice Accept ownership of a supplied conduit. Only accounts that the
   *         current owner has set as the new potential owner may call this
   *         function.
   *
   * @param conduit The conduit for which to accept ownership.
   */
  function acceptOwnership(address conduit) external;

  /**
   * @notice Retrieve the current owner of a deployed conduit.
   *
   * @param conduit The conduit for which to retrieve the associated owner.
   *
   * @return owner The owner of the supplied conduit.
   */
  function ownerOf(address conduit) external view returns (address owner);

  /**
   * @notice Retrieve the conduit key for a deployed conduit via reverse
   *         lookup.
   *
   * @param conduit The conduit for which to retrieve the associated conduit
   *                key.
   *
   * @return conduitKey The conduit key used to deploy the supplied conduit.
   */
  function getKey(address conduit) external view returns (bytes32 conduitKey);

  /**
   * @notice Derive the conduit associated with a given conduit key and
   *         determine whether that conduit exists (i.e. whether it has been
   *         deployed).
   *
   * @param conduitKey The conduit key used to derive the conduit.
   *
   * @return conduit The derived address of the conduit.
   * @return exists  A boolean indicating whether the derived conduit has been
   *                 deployed or not.
   */
  function getConduit(
    bytes32 conduitKey
  ) external view returns (address conduit, bool exists);

  /**
   * @notice Retrieve the potential owner, if any, for a given conduit. The
   *         current owner may set a new potential owner via
   *         `transferOwnership` and that owner may then accept ownership of
   *         the conduit in question via `acceptOwnership`.
   *
   * @param conduit The conduit for which to retrieve the potential owner.
   *
   * @return potentialOwner The potential owner, if any, for the conduit.
   */
  function getPotentialOwner(
    address conduit
  ) external view returns (address potentialOwner);

  /**
   * @notice Retrieve the status (either open or closed) of a given channel on
   *         a conduit.
   *
   * @param conduit The conduit for which to retrieve the channel status.
   * @param channel The channel for which to retrieve the status.
   *
   * @return isOpen The status of the channel on the given conduit.
   */
  function getChannelStatus(
    address conduit,
    address channel
  ) external view returns (bool isOpen);

  /**
   * @notice Retrieve the total number of open channels for a given conduit.
   *
   * @param conduit The conduit for which to retrieve the total channel count.
   *
   * @return totalChannels The total number of open channels for the conduit.
   */
  function getTotalChannels(
    address conduit
  ) external view returns (uint256 totalChannels);

  /**
   * @notice Retrieve an open channel at a specific index for a given conduit.
   *         Note that the index of a channel can change as a result of other
   *         channels being closed on the conduit.
   *
   * @param conduit      The conduit for which to retrieve the open channel.
   * @param channelIndex The index of the channel in question.
   *
   * @return channel The open channel, if any, at the specified channel index.
   */
  function getChannel(
    address conduit,
    uint256 channelIndex
  ) external view returns (address channel);

  /**
   * @notice Retrieve all open channels for a given conduit. Note that calling
   *         this function for a conduit with many channels will revert with
   *         an out-of-gas error.
   *
   * @param conduit The conduit for which to retrieve open channels.
   *
   * @return channels An array of open channels on the given conduit.
   */
  function getChannels(
    address conduit
  ) external view returns (address[] memory channels);

  /**
   * @dev Retrieve the conduit creation code and runtime code hashes.
   */
  function getConduitCodeHashes()
    external
    view
    returns (bytes32 creationCodeHash, bytes32 runtimeCodeHash);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
  /**
   * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
   */
  event TransferSingle(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );

  /**
   * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
   * transfers.
   */
  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  /**
   * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
   * `approved`.
   */
  event ApprovalForAll(
    address indexed account,
    address indexed operator,
    bool approved
  );

  /**
   * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
   *
   * If an {URI} event was emitted for `id`, the standard
   * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
   * returned by {IERC1155MetadataURI-uri}.
   */
  event URI(string value, uint256 indexed id);

  /**
   * @dev Returns the amount of tokens of token type `id` owned by `account`.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function balanceOf(
    address account,
    uint256 id
  ) external view returns (uint256);

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
   *
   * Requirements:
   *
   * - `accounts` and `ids` must have the same length.
   */
  function balanceOfBatch(
    address[] calldata accounts,
    uint256[] calldata ids
  ) external view returns (uint256[] memory);

  /**
   * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
   *
   * Emits an {ApprovalForAll} event.
   *
   * Requirements:
   *
   * - `operator` cannot be the caller.
   */
  function setApprovalForAll(address operator, bool approved) external;

  /**
   * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
   *
   * See {setApprovalForAll}.
   */
  function isApprovedForAll(
    address account,
    address operator
  ) external view returns (bool);

  /**
   * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
   * - `from` must have a balance of tokens of type `id` of at least `amount`.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
   *
   * Emits a {TransferBatch} event.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;
}

interface ICollateralToken is IERC721 {
  event ListedOnSeaport(uint256 collateralId, Order listingOrder);
  event FileUpdated(FileType what, bytes data);
  event Deposit721(
    address indexed tokenContract,
    uint256 indexed tokenId,
    uint256 indexed collateralId,
    address depositedFor
  );
  event ReleaseTo(
    address indexed underlyingAsset,
    uint256 assetId,
    address indexed to
  );

  struct Asset {
    address tokenContract;
    uint256 tokenId;
    bytes32 auctionHash;
  }

  struct CollateralStorage {
    ILienToken LIEN_TOKEN;
    IAstariaRouter ASTARIA_ROUTER;
    ConsiderationInterface SEAPORT;
    ConduitControllerInterface CONDUIT_CONTROLLER;
    address CONDUIT;
    bytes32 CONDUIT_KEY;
    //mapping of the collateralToken ID and its underlying asset
    mapping(uint256 => Asset) idToUnderlying;
  }

  struct ListUnderlyingForSaleParams {
    ILienToken.Stack stack;
    uint256 listPrice;
    uint56 maxDuration;
  }

  enum FileType {
    NotSupported,
    AstariaRouter,
    Seaport,
    CloseChannel
  }

  struct File {
    FileType what;
    bytes data;
  }

  function fileBatch(File[] calldata files) external;

  function file(File calldata incoming) external;

  function getConduit() external view returns (address);

  function getConduitKey() external view returns (bytes32);

  struct AuctionVaultParams {
    address settlementToken;
    uint256 collateralId;
    uint256 maxDuration;
    uint256 startingPrice;
    uint256 endingPrice;
  }

  function auctionVault(
    AuctionVaultParams calldata params
  ) external returns (OrderParameters memory);

  function SEAPORT() external view returns (ConsiderationInterface);

  function depositERC721(
    address tokenContract,
    uint256 tokenId,
    address from
  ) external;

  function CONDUIT_CONTROLLER()
    external
    view
    returns (ConduitControllerInterface);

  function getUnderlying(
    uint256 collateralId
  ) external view returns (address, uint256);

  function release(uint256 collateralId) external;

  function liquidatorNFTClaim(
    ILienToken.Stack memory stack,
    OrderParameters memory params
  ) external;

  error UnsupportedFile();
  error InvalidCollateral();
  error InvalidSender();
  error InvalidOrder();
  error InvalidCollateralState(InvalidCollateralStates);
  error ProtocolPaused();
  error ListPriceTooLow();
  error InvalidConduitKey();
  error InvalidZoneHash();
  error InvalidTarget();
  error InvalidPaymentToken();
  error InvalidPaymentAmount();

  enum InvalidCollateralStates {
    AUCTION_ACTIVE,
    ID_MISMATCH,
    INVALID_AUCTION_PARAMS,
    ACTIVE_LIENS,
    ESCROW_ACTIVE,
    NO_AUCTION
  }
}

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

interface IPausable {
  function paused() external view returns (bool);
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is IPausable {
  uint256 private constant PAUSE_SLOT =
    uint256(keccak256("xyz.astaria.AstariaRouter.Pausable.storage.location")) -
      1;
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  struct PauseStorage {
    bool _paused;
  }

  function _loadPauseSlot() internal pure returns (PauseStorage storage s) {
    uint256 slot = PAUSE_SLOT;

    assembly {
      s.slot := slot
    }
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view virtual returns (bool) {
    return _loadPauseSlot()._paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    require(!paused(), "Pausable: paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    require(paused(), "Pausable: not paused");
    _;
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function _pause() internal virtual whenNotPaused {
    _loadPauseSlot()._paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function _unpause() internal virtual whenPaused {
    _loadPauseSlot()._paused = false;
    emit Unpaused(msg.sender);
  }
}

/**
 *  █████╗ ███████╗████████╗ █████╗ ██████╗ ██╗ █████╗
 * ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║██╔══██╗
 * ███████║███████╗   ██║   ███████║██████╔╝██║███████║
 * ██╔══██║╚════██║   ██║   ██╔══██║██╔══██╗██║██╔══██║
 * ██║  ██║███████║   ██║   ██║  ██║██║  ██║██║██║  ██║
 * ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
 *
 * Astaria Labs, Inc
 */

interface IBeacon {
  /**
   * @dev Must return an address that can be used as a delegate call target.
   *
   * {BeaconProxy} will check that this address is a contract.
   */
  function getImpl(uint8) external view returns (address);
}

// import "./IERC4626RouterBase.sol";

interface IAstariaRouter is IPausable, IBeacon {
  enum FileType {
    FeeTo,
    LiquidationFee,
    ProtocolFee,
    MaxStrategistFee,
    MinEpochLength,
    MaxEpochLength,
    MinInterestRate,
    MaxInterestRate,
    MinLoanDuration,
    AuctionWindow,
    StrategyValidator,
    Implementation,
    CollateralToken,
    LienToken,
    TransferProxy
  }

  struct File {
    FileType what;
    bytes data;
  }

  event FileUpdated(FileType what, bytes data);

  struct RouterStorage {
    //slot 1
    uint32 auctionWindow;
    uint32 liquidationFeeNumerator;
    uint32 liquidationFeeDenominator;
    uint32 maxEpochLength;
    uint32 minEpochLength;
    uint32 protocolFeeNumerator;
    uint32 protocolFeeDenominator;
    uint32 minLoanDuration;
    //slot 2
    ICollateralToken COLLATERAL_TOKEN; //20
    ILienToken LIEN_TOKEN; //20
    ITransferProxy TRANSFER_PROXY; //20
    address feeTo; //20
    address BEACON_PROXY_IMPLEMENTATION; //20
    uint256 maxInterestRate; //6
    //slot 3 +
    address guardian; //20
    address newGuardian; //20
    mapping(uint8 => address) strategyValidators;
    mapping(uint8 => address) implementations;
    //A strategist can have many deployed vaults
    mapping(address => bool) vaults;
    uint256 maxStrategistFee; //4
    address WETH;
  }

  enum ImplementationType {
    PrivateVault,
    PublicVault,
    WithdrawProxy
  }

  enum LienRequestType {
    DEACTIVATED,
    UNIQUE,
    COLLECTION,
    UNIV3_LIQUIDITY
  }

  struct StrategyDetailsParam {
    uint8 version;
    uint256 deadline;
    address payable vault;
  }

  struct MerkleData {
    bytes32 root;
    bytes32[] proof;
  }

  struct NewLienRequest {
    StrategyDetailsParam strategy;
    bytes nlrDetails;
    bytes32 root;
    bytes32[] proof;
    uint256 amount;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct Commitment {
    address tokenContract;
    uint256 tokenId;
    NewLienRequest lienRequest;
  }

  function STRATEGY_TYPEHASH() external view returns (bytes32);

  function validateCommitment(
    IAstariaRouter.Commitment calldata commitment
  ) external returns (ILienToken.Lien memory lien);

  function getStrategyValidator(
    Commitment calldata
  ) external view returns (address);

  function newPublicVault(
    uint256 epochLength,
    address delegate,
    address underlying,
    uint256 vaultFee,
    bool allowListEnabled,
    address[] calldata allowList,
    uint256 depositCap
  ) external returns (address);

  function newVault(
    address delegate,
    address underlying
  ) external returns (address);

  function feeTo() external returns (address);

  function WETH() external returns (address);

  function commitToLien(
    Commitment memory commitments
  ) external returns (uint256, ILienToken.Stack memory);

  function LIEN_TOKEN() external view returns (ILienToken);

  function TRANSFER_PROXY() external view returns (ITransferProxy);

  function BEACON_PROXY_IMPLEMENTATION() external view returns (address);

  function COLLATERAL_TOKEN() external view returns (ICollateralToken);

  function getAuctionWindow() external view returns (uint256);

  function getProtocolFee(uint256) external view returns (uint256);

  function getLiquidatorFee(uint256) external view returns (uint256);

  function liquidate(
    ILienToken.Stack calldata stack
  ) external returns (OrderParameters memory);

  function canLiquidate(ILienToken.Stack calldata) external view returns (bool);

  function isValidVault(address vault) external view returns (bool);

  function fileBatch(File[] calldata files) external;

  function file(File calldata incoming) external;

  function setNewGuardian(address _guardian) external;

  function fileGuardian(File[] calldata file) external;

  function getImpl(uint8 implType) external view returns (address impl);

  event Liquidation(uint256 lienId, address liquidator);
  event NewVault(
    address strategist,
    address delegate,
    address vault,
    uint8 vaultType
  );

  error InvalidFileData();
  error InvalidEpochLength(uint256);
  error InvalidRefinanceRate(uint256);
  error InvalidRefinanceDuration(uint256);
  error InvalidVaultFee();
  error InvalidVaultState(VaultState);
  error InvalidSenderForCollateral(address, uint256);
  error InvalidLienState(LienState);
  error InvalidCollateralState(CollateralStates);
  error InvalidCommitmentState(CommitmentState);
  error InvalidStrategy(uint16);
  error InvalidVault(address);
  error InvalidUnderlying(address);
  error InvalidSender();
  error StrategyExpired();
  error UnsupportedFile();

  enum LienState {
    HEALTHY,
    AUCTION
  }

  enum CollateralStates {
    AUCTION,
    NO_DEPOSIT,
    NO_LIENS
  }

  enum CommitmentState {
    INVALID,
    INVALID_RATE,
    INVALID_AMOUNT,
    COLLATERAL_NO_DEPOSIT
  }

  enum VaultState {
    UNINITIALIZED,
    SHUTDOWN,
    CORRUPTED
  }
}

contract ExternalRefinancing is IFlashLoanRecipient {
  IAstariaRouter ASTARIA_ROUTER;
  address public BEND_ADDRESSES_PROVIDER;
  address public BEND_DATA_PROVIDER;
  address payable public BEND_PUNK_GATEWAY;
  address payable public BEND_WETH_GATEWAY;

  address public BALANCER_VAULT;
  address public WETH;

  address public COLLATERAL_TOKEN;
  event BendRefinance(uint256 lienId);

  constructor(
    address router,
    address bendAddressesProvider,
    address bendDataProvider,
    address payable bendPunkGateway,
    address balancerVault,
    address weth,
    address payable bendWethGateway,
    address collateralToken
  ) {
    ASTARIA_ROUTER = IAstariaRouter(router);
    BEND_ADDRESSES_PROVIDER = bendAddressesProvider;
    BEND_DATA_PROVIDER = bendDataProvider;
    BEND_PUNK_GATEWAY = bendPunkGateway;
    BALANCER_VAULT = balancerVault;
    WETH = weth;
    BEND_WETH_GATEWAY = bendWethGateway;
    COLLATERAL_TOKEN = collateralToken;
  }

  struct BendLoanData {
    address bnftAddress;
    uint256 tokenId; // or have an array of tokenIds for each unique bNft collection?
  }

  function getBendUserLoanData(
    address borrower
  ) public view returns (BendLoanData[] memory) {
    IBendProtocolDataProvider.NftTokenData[]
      memory data = IBendProtocolDataProvider(BEND_DATA_PROVIDER)
        .getAllNftsTokenDatas();

    uint256 totalOwnedNFTs = 0;
    for (uint256 i = 0; i < data.length; i++) {
      address bnftAddress = data[i].bNftAddress;
      totalOwnedNFTs += ERC721(bnftAddress).balanceOf(borrower);
    }

    BendLoanData[] memory tempBalancesArray = new BendLoanData[](
      totalOwnedNFTs
    );
    uint256 count = 0;

    for (uint256 i = 0; i < data.length; i++) {
      address bnftAddress = data[i].bNftAddress;
      uint256 numBnfts = ERC721(bnftAddress).balanceOf(borrower);

      for (uint256 j = 0; j < numBnfts; j++) {
        uint256 tokenId = IERC721Enumerable(bnftAddress).tokenOfOwnerByIndex(
          borrower,
          j
        );
        tempBalancesArray[count] = BendLoanData(bnftAddress, tokenId);
        count++;
      }
    }

    BendLoanData[] memory balancesArray = new BendLoanData[](count);
    for (uint256 i = 0; i < count; i++) {
      balancesArray[i] = tempBalancesArray[i];
    }

    return balancesArray;
  }

  function _decodeData(
    bytes memory data
  )
    internal
    pure
    returns (
      address borrower,
      address tokenAddress,
      uint256 tokenId,
      uint256 debt,
      IAstariaRouter.Commitment memory commitment
    )
  {
    (borrower, tokenAddress, tokenId, debt, commitment) = _decodeCommitment(
      data
    );
  }

  function _decodeCommitment(
    bytes memory data
  )
    internal
    pure
    returns (
      address borrower,
      address tokenAddress,
      uint256 tokenId,
      uint256 debt,
      IAstariaRouter.Commitment memory commitment
    )
  {
    bytes memory encodedCommitment;
    (borrower, tokenAddress, tokenId, debt, encodedCommitment) = abi.decode(
      data,
      (address, address, uint256, uint256, bytes)
    );

    (
      address commitmentTokenContract,
      uint256 commitmentTokenId,
      bytes memory encodedStrategy,
      bytes memory nlrDetails,
      bytes32 root,
      bytes32[] memory proof,
      uint256 amount,
      uint8 v,
      bytes32 r,
      bytes32 s
    ) = abi.decode(
        encodedCommitment,
        (
          address,
          uint256,
          bytes,
          bytes,
          bytes32,
          bytes32[],
          uint256,
          uint8,
          bytes32,
          bytes32
        )
      );

    IAstariaRouter.NewLienRequest memory lienRequest = _constructLienRequest(
      encodedStrategy,
      nlrDetails,
      root,
      proof,
      amount,
      v,
      r,
      s
    );
    commitment = IAstariaRouter.Commitment(
      commitmentTokenContract,
      commitmentTokenId,
      lienRequest
    );
  }

  function _constructLienRequest(
    bytes memory encodedStrategy,
    bytes memory nlrDetails,
    bytes32 root,
    bytes32[] memory proof,
    uint256 amount,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (IAstariaRouter.NewLienRequest memory lienRequest) {
    (uint8 version, uint256 deadline, address payable vault) = abi.decode(
      encodedStrategy,
      (uint8, uint256, address)
    );

    IAstariaRouter.StrategyDetailsParam memory strategy = IAstariaRouter
      .StrategyDetailsParam(version, deadline, vault);
    lienRequest = IAstariaRouter.NewLienRequest(
      strategy,
      nlrDetails,
      root,
      proof,
      amount,
      v,
      r,
      s
    );
  }

  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external override {
    (
      address borrower,
      address tokenAddress,
      uint256 tokenId,
      uint256 debt,
      IAstariaRouter.Commitment memory commitment
    ) = _decodeData(userData);

    uint256[] memory ids = new uint256[](1);
    ids[0] = tokenId;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = debt;

    require(
      IERC20(WETH).balanceOf(address(this)) >= debt,
      "ExternalRefinancing: not enough WETH"
    );
    if (tokenAddress != address(0)) {
      address[] memory nfts = new address[](1);
      nfts[0] = tokenAddress;

      address pool = ILendPoolAddressesProvider(BEND_ADDRESSES_PROVIDER)
        .getLendPool();

      //            LendPool(pool).batchRepay(nfts, ids, amounts);
      IWETH9(WETH).withdraw(debt);
      IWETHGateway(payable(BEND_WETH_GATEWAY)).batchRepayETH{value: debt}(
        nfts,
        ids,
        amounts
      );
      require(
        ERC721(tokenAddress).ownerOf(tokenId) == borrower,
        "Loan unsuccessfully repaid"
      );
    } else {
      IPunkGateway(payable(BEND_PUNK_GATEWAY)).batchRepayETH{value: debt}(
        ids,
        amounts
      );
    }

    ERC721(tokenAddress).transferFrom(borrower, address(this), tokenId);
    ERC721(tokenAddress).setApprovalForAll(address(ASTARIA_ROUTER), true);
    (uint256 lienId, ILienToken.Stack memory stack) = ASTARIA_ROUTER
      .commitToLien(commitment);
    emit BendRefinance(lienId);
    ERC721(COLLATERAL_TOKEN).transferFrom(
      address(this),
      borrower,
      stack.lien.collateralId
    );

    require(
      ERC721(COLLATERAL_TOKEN).ownerOf(stack.lien.collateralId) == borrower,
      "CollateralToken not returned to borrower"
    );
    IWETH9(WETH).deposit{value: debt}();

    IERC20(WETH).transfer(BALANCER_VAULT, debt);
  }

  function refinance(
    address borrower,
    address tokenAddress, // use 0 address for punks
    uint256 tokenId,
    uint256 debt,
    IAstariaRouter.Commitment calldata commitment
  ) external {
    IERC20[] memory tokens = new IERC20[](1);
    tokens[0] = IERC20(WETH);
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = debt;
    IBalancerVault(BALANCER_VAULT).flashLoan(
      IFlashLoanRecipient(address(this)),
      tokens,
      amounts,
      abi.encode(
        borrower,
        tokenAddress,
        tokenId,
        debt,
        _encodeCommitment(commitment)
      )
    );
  }

  function _encodeCommitment(
    IAstariaRouter.Commitment calldata commitment
  ) internal pure returns (bytes memory) {
    return
      abi.encode(
        commitment.tokenContract,
        commitment.tokenId,
        abi.encode(
          commitment.lienRequest.strategy.version,
          commitment.lienRequest.strategy.deadline,
          commitment.lienRequest.strategy.vault
        ),
        commitment.lienRequest.nlrDetails,
        commitment.lienRequest.root,
        commitment.lienRequest.proof,
        commitment.lienRequest.amount,
        commitment.lienRequest.v,
        commitment.lienRequest.r,
        commitment.lienRequest.s
      );
  }

  receive() external payable {}

  function _isInArray(
    address[] memory array,
    address addrToCheck
  ) internal view returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == addrToCheck) {
        return true;
      }
    }
    return false;
  }
}
