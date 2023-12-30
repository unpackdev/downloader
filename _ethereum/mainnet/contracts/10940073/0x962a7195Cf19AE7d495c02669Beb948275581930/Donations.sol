// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts/Auditable.sol

pragma solidity ^0.6.10;


contract Auditable {
    using Address for address;

    address public auditor;
    address public auditedContract;

    // Indicates whether the audit has been completed and approved (true) or not (false)
    bool public audited;

    modifier isAudited() {
        require(audited == true, "Not audited");
        _;
    }

    // emitted when the contract has been audited and approved/opposed
    event ApprovedAudit(address _auditor, address _contract, string _message);
    event OpposedAudit(address _auditor, address _contract, string _message);

    constructor(address _auditor, address _auditedContract) public {
        auditor = _auditor;
        auditedContract = _auditedContract;
    }

    function setAuditor(address _auditor) public {
        require(msg.sender == auditor, "Only the auditor ???");
        require(audited == false, "Cannot change auditor post audit");
        // Can change the auditor if they bail, saves from having to redeploy and lose funds
        auditor = _auditor;
    }

    // The auditor is approving the contract by switching the audit bool to true. 
    // This unlocks contract functionality via the isAudited modifier
    function approveAudit() public {
        require(msg.sender == auditor, "Auditor only");

        audited = true;

        // Inform everyone and use a user friendly message
        emit ApprovedAudit(auditor, auditedContract, "Contract approved, functionality unlocked");
    }

    // The auditor is opposing the audit by switching the bool to false
    function opposeAudit() public {
        require(msg.sender == auditor, "Auditor only");
        require(audited != true, "Cannot destroy an approved contract");
        
        // The default (unset) bool is set to false but do not rely on that; set to false to be sure.
        audited = false;

        // Inform everyone and use a user friendly message
        emit OpposedAudit(auditor, auditedContract, "Contract has failed the audit");
    }
}

// File: contracts/Ownable.sol

pragma solidity ^0.6.10;

contract Ownable {

    address payable public owner;

    event TransferredOwnership(address _previous, address _next, uint256 _time);

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner only");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address payable _owner) public onlyOwner() {
        address previousOwner = owner;
        owner = _owner;
        emit TransferredOwnership(previousOwner, owner, now);
    }
}

// File: contracts/Donations.sol

pragma solidity ^0.6.10;



contract Donations is Ownable, Auditable {

    // the non-fungible token can be updated over time as newer versions are released
    address public NFT;

    event ChangedNFT(address _previous, address _next, uint256 _time);

    constructor(address _auditor, address _NFT) Ownable() Auditable(_auditor, address(this)) public {
        // Duplicated code for the setting of the NFT because we must set the NFT before anyone 
        // can donate however the setNFT function is another part of this contract that should not 
        // be available until the contract has been audited.
        address previousNFT = NFT;
        NFT = _NFT;
        emit ChangedNFT(previousNFT, NFT, now);
    }

    function donate() public payable isAudited() {
        // Accept any donation (including 0) but ...
        // if donation >= 0.1 ether then mint the non-fungible token as a collectible
        // and as a thank you
        if(msg.value >= 100000000000000000) 
        {
            // Call the mint function of the current NFT contract address
            // keep in mind that you can keep donating but you will only ever have ONE
            // NFT in total (per NFT type). This should not mint additional tokens
            NFT.call(abi.encodeWithSignature("mint(address)", msg.sender));
        }

        // Transfer the value to the owner
        owner.transfer(msg.value);
    }

    function setNFT(address _NFT) public onlyOwner() isAudited() {
        // Over time new iterations of (collectibles) NFTs shall be issued.

        // For user convenience it would be better to inform the user instead of just changing
        // the NFT. Exmaples include minimum time locks, total number of donations or a fund goal
        address previousNFT = NFT;
        NFT = _NFT;
        emit ChangedNFT(previousNFT, NFT, now);
    }

    function destroyContract() public onlyOwner() {
        // Need another function for the auditor which lets them destroy (WIP)
        require(audited == false, "Cannot destroy an audited contract");
        selfdestruct(owner);
    }

}