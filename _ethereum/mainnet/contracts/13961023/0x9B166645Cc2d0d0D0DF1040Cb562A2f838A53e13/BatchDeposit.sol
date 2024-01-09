// SPDX-License-Identifier: MIT
/*
         .8.          8 8888         8 888888888o   8 8888888888   
        .888.         8 8888         8 8888    `88. 8 8888         
       :88888.        8 8888         8 8888     `88 8 8888         
      . `88888.       8 8888         8 8888     ,88 8 8888         
     .8. `88888.      8 8888         8 8888.   ,88' 8 888888888888 
    .8`8. `88888.     8 8888         8 888888888P'  8 8888         
   .8' `8. `88888.    8 8888         8 8888         8 8888         
  .8'   `8. `88888.   8 8888         8 8888         8 8888         
 .888888888. `88888.  8 8888         8 8888         8 8888         
.8'       `8. `88888. 8 888888888888 8 8888         8 888888888888 
*/

pragma solidity 0.8.6;

import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./BytesLib.sol";

import "./IDepositContract.sol";

/*  Alpe Deposit Contract
 *  @notice Use at your own risk, alpe will not accept any responsibility for any loss of funds caused by using this contract.
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *  @notice Deposit Functions are modified from
 *  - https://github.com/lidofinance/lido-dao/blob/master/contracts/0.4.24/Lido.sol
 */
contract ALPEDeposit is Pausable {
    // Safety Libraries
    using SafeERC20 for IERC20;
    using Address for address;

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                          CONSTANTS
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    uint256 public constant DEPOSIT_AMOUNT = 32 ether;
    uint256 public constant PUBKEY_LENGTH = 48;
    uint256 public constant WITHDRAWAL_CREDENTIALS_LENGTH = 32;
    uint256 public constant SIGNATURE_LENGTH = 96;
    uint256 internal constant DEPOSIT_AMOUNT_UNIT = 1000000000 wei;

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                          NOTABLE ADDRESSES
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    // Goverannce address, has ability to access onlyGovernance funcitons
    address public governance;

    // The proposed new address for governance changes, will not be changed until they accept governance
    address public governanceBuffer;

    // The address of the deposit contract
    IDepositContract public depositContract;

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                          EVENTS
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    // Emitted when new governance is proposed
    event GovernanceSet(address governance);

    // Emitted when new governance is accepted and transfered.
    event GovernanceAccepted(address governance);

    // Emitted for each deposit to the Eth2 deposit contract.
    event SingleALPEDepositEvent(
        bytes indexed pubkey,
        bytes withdrawal_credentials,
        bytes signature
    );

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                          MODIFIERS
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    /** Within Timeout
     *  @notice Modifier to revert transactions that do not make it past a set timeout.
     *  @param _timeout The timeout timestamp provided with the transaction.
     *  @dev This is application level protection to prevent stale validator deposits that do not
     *  @dev get included in blocks
     */
    modifier withinTimeout(uint256 _timeout) {
        require(block.timestamp < _timeout, "After Timeout");
        _;
    }

    /** Only Governance
     *  @notice Modifier to protect functions so they can only be called by the governance address
     *  @dev Only used to pause the contract / withdraw locked fund accidentally sent to the contract.
     */
    modifier onlyGovernance() {
        require(msg.sender == governance, "!GOVERNANCE");
        _;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                          CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    /** Constructor
     * @notice Deposit contract is set within the deposit script and CAN be updated by governance if there are any problems.
     * @param _depositContract The address of the eth2 deposit contract
     * @dev Governance is set to the deployer address.
     */
    constructor(address _depositContract) {
        governance = msg.sender;
        depositContract = IDepositContract(_depositContract);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                          SETTERS
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     *  @notice Updates governance address
     *  @param _governance new governance address to control contract
     *  @dev The new governance address must accept governance for the transition to complete. See acceptGovernance().
     **/
    function setGovernance(address _governance) external onlyGovernance {
        governanceBuffer = _governance;
        emit GovernanceSet(_governance);
    }

    /** Accept Governance
     *  @notice This is to prevent the bricking of the governance address. Such that it will always be recoverable.
     *  @dev Allows the proposed governance to accept governance responsibilies. Until this function is called by new governance, old
     *  @dev governance will remain in control.
     **/
    function acceptGovernance() external {
        require(msg.sender == governanceBuffer, "Only Proposed Governance");
        governance = governanceBuffer;
        emit GovernanceAccepted(governance);
    }


    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                          RECOVER LOCKED FUNDS
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    /** Recover Ether
     *  @notice Fail safe incase a user accidentally sents ether directly to the contract.
     *  @dev Withdraws all money in contract to governance in case funds are accidentally sent to the contract.
     */
    function recoverEther() external onlyGovernance {
        payable(governance).transfer(address(this).balance);
    }

    /** Recover Funds
     *  @notice Sends any ERC20 tokens accidentily locked in the contract.
     *  @param _token Address of the token being recovered
     *  @dev Similar to recoverEther, but for ERC20 tokens. Only governance.
     */
    function recoverFunds(address _token) external onlyGovernance {
        IERC20(_token).transfer(
            governance,
            IERC20(_token).balanceOf(address(this))
        );
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                          PAUSABLE
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    /** Pause
     *  @notice Pauses ability to make deposits through alpe.
     *  @dev Halts all functions marked "whenNotPaused"
     */
    function pause() external whenNotPaused onlyGovernance {
        _pause();
    }

    /** Unpause
     *  @notice Resumes ability to make deposits through alpe.
     *  @dev Allows all functions marked "whenNotPaused"
     */
    function unpause() external whenPaused onlyGovernance {
        _unpause();
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                          CORE METHODS
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    /** Batch Stake
     *  @notice Public entry point to make a deposit to Alpe.
     *  @param _pubkeys An array of validator public keys deposits are being made for.
     *  @param _withdrawalCredentials An array of withdrawal credentials one for each validator being created.
     *  @param _signatures An array of signatures, one for each validator being created.
     *  @param _dataroots An array of data roots. These are checked against calculated from _pubkeys, _withdrawalCredentials and signatures.
     *  @param _timeout Deadstop timestamp.
     *  @dev This will fail if the provided _timeout timestamp has passed.
     *  @dev Further sanity checks are performed within this function, i.e. input array length assertions and deposit amount assertions.
     */
    function batchStake(
        bytes[] calldata _pubkeys,
        bytes[] calldata _withdrawalCredentials,
        bytes[] calldata _signatures,
        bytes[] calldata _dataroots,
        uint256 _timeout
    )
        external
        payable
        withinTimeout(_timeout) // ensure that the tx is mined within the provided timeout
    {
        // Array length check assertions
        require(
            _pubkeys.length == _signatures.length,
            "len(PUBKEYS) != len(SIGNATURES)"
        );
        require(
            _pubkeys.length == _withdrawalCredentials.length,
            "len(PUBKEYS) != len(CREDENTIALS)"
        );
        require(
            _pubkeys.length == _dataroots.length,
            "len(PUBKEYS) != len(DATAROOTS)"
        );

        uint256 count = _signatures.length;
        require(
            count > 0,
            "ALPEDeposit: You should deposit at least one validator"
        );

        // check value from msg.value
        require(
            msg.value % 1 gwei == 0,
            "ALPEDeposit: Deposit value not multiple of GWEI"
        );
        require(msg.value >= DEPOSIT_AMOUNT, "ALPEDeposit: Amount is too low");
        uint256 expectedAmount = DEPOSIT_AMOUNT * count;
        require(
            msg.value == expectedAmount,
            "ALPEDeposit: Amount is not aligned with pubkeys number"
        );

        _batchStake(_pubkeys, _withdrawalCredentials, _signatures, _dataroots);
    }

    /** Internal Batch Stake
     *  @notice Iterates over each validator and calls stake to perform a deposit.
     *  @param _pubkeys An array of validator public keys deposits are being made for.
     *  @param _withdrawalCredentials An array of withdrawal credentials one for each validator being created.
     *  @param _signatures An array of signatures, one for each validator being created.
     *  @param _dataroots An array of data roots. These are checked against calculated from _pubkeys, _withdrawalCredentials and signatures.
     */
    function _batchStake(
        bytes[] calldata _pubkeys,
        bytes[] calldata _withdrawalCredentials,
        bytes[] calldata _signatures,
        bytes[] calldata _dataroots
    ) internal {
        // call the the staking contract for each deposit provide
        for (uint256 i = 0; i < _pubkeys.length; i++) {
            _stake(
                _pubkeys[i],
                _withdrawalCredentials[i],
                _signatures[i],
                _dataroots[i]
            );
        }
    }

    /** Stake
     *  @notice Performs a deposit to the Eth2 deposit contract.
     *  @param _pubkey An array of validator public keys deposits are being made for.
     *  @param _withdrawalCredentials An array of withdrawal credentials one for each validator being created.
     *  @param _signature An array of signatures, one for each validator being created.
     *  @param _dataroot An array of data roots. These are checked against calculated from _pubkey, _withdrawalCredentials and signature.
     *  @dev On each deposit an event is emitted which triggers the alpe infrastructure to spin up a validator.
     */
    function _stake(
        bytes calldata _pubkey,
        bytes calldata _withdrawalCredentials,
        bytes calldata _signature,
        bytes calldata _dataroot
    ) internal {
        // The following computations and Merkle tree-ization will make official Deposit contract happy
        uint256 value = DEPOSIT_AMOUNT;
        uint256 depositAmount = value / DEPOSIT_AMOUNT_UNIT;
        assert(depositAmount * DEPOSIT_AMOUNT_UNIT == value); // properly rounded

        // Compute deposit data root (`DepositData` hash tree root) according to deposit_contract.sol
        bytes32 pubkeyRoot = sha256(_pad64(_pubkey));
        bytes32 signatureRoot = sha256(
            abi.encodePacked(
                sha256(BytesLib.slice(_signature, 0, 64)),
                sha256(
                    _pad64(
                        BytesLib.slice(_signature, 64, SIGNATURE_LENGTH - 64)
                    )
                )
            )
        );

        bytes32 depositDataRoot = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(pubkeyRoot, _withdrawalCredentials)),
                sha256(
                    abi.encodePacked(
                        _toLittleEndian64(depositAmount),
                        signatureRoot
                    )
                )
            )
        );

        // enforce calculated dataroot matches that provided externally -> This prevents tampering of validator public key
        require(bytes32(_dataroot) == depositDataRoot, "Dataroot mismatch");

        // Perform deposit to the depositContract
        depositContract.deposit{value: value}(
            _pubkey,
            abi.encodePacked(_withdrawalCredentials),
            _signature,
            depositDataRoot
        );

        // Notify infrastructure of deposit
        emit SingleALPEDepositEvent(
            _pubkey,
            _withdrawalCredentials,
            _signature
        );
    }

    /** Pad64
     *  @dev Padding memory array with zeroes up to 64 bytes on the right
     *  @param _b Memory array of size 32 .. 64
     */
    function _pad64(bytes memory _b) internal pure returns (bytes memory) {
        assert(_b.length >= 32 && _b.length <= 64);
        if (64 == _b.length) return _b;

        bytes memory zero32 = new bytes(32);
        assembly {
            mstore(add(zero32, 0x20), 0)
        }

        if (32 == _b.length) return BytesLib.concat(_b, zero32);
        else
            return
                BytesLib.concat(
                    _b,
                    BytesLib.slice(zero32, 0, uint256(64) - _b.length)
                );
    }

    /** To Little Endian
     *  @notice Converts a figure to liddle endian representation
     *  @param _value The value being converted
     *  @dev Required to verify deposit roots
     */
    function _toLittleEndian64(uint256 _value)
        internal
        pure
        returns (uint256 result)
    {
        result = 0;
        uint256 temp_value = _value;
        for (uint256 i = 0; i < 8; ++i) {
            result = (result << 8) | (temp_value & 0xFF);
            temp_value >>= 8;
        }

        assert(0 == temp_value); // fully converted
        result <<= (24 * 8);
    }
}
