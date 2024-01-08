// SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Controller.sol";

/**
 * PRISM MultiBridge
 *
 * Attributes:
 * - Stores cross-chain transfers until they are processed
 * - Supports the tracking of cross-chain transfers via hash-based IDs
 * - Ensures users fund the necessary gas cost for the migrations based on a flag
 */
abstract contract MultiBridge is Controller {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Address for address payable;

    mapping (uint256 => bool) public isSupportedChain;

    struct CrossChainTransfer {
        address to;
        bool processed;
        uint88 gasPrice;
        uint256 amount;
        uint256 chain;
    }

    // Numeric flag for processed inward transfers
    uint256 internal constant PROCESSED = type(uint256).max;
    // Gas Costs
    // - Process gas cost
    uint256 private constant PROCESS_COST = 65990;
    // - Unlock gas cost
    uint256 private immutable UNLOCK_COST;

    // Holding all pending cross chain transfer info
    // - ID of cross chain transfers
    uint256 internal crossChainTransfer;
    // - Enforce funding supply from users
    bool internal forceFunding = true;
    // - Outward transfer data
    mapping(uint256 => CrossChainTransfer) public outwardTransfers;
    // - Inward gas price funding, used as a flag for processed txs via `PROCESSED`
    mapping(bytes32 => uint256) public inwardTransferFunding;

    event CrossChainTransferLocked(address indexed from, uint256 i);
    event CrossChainTransferProcessed(
        address indexed to,
        uint256 amount,
        uint256 chain
    );
    event CrossChainUnlockFundsReceived(
        address indexed to,
        uint256 amount,
        uint256 chain,
        uint256 orderId
    );
    event CrossChainTransferUnlocked(
        address indexed to,
        uint256 amount,
        uint256 chain
    );

    modifier validChain(uint256 chain) {
        _validChain(chain);
        _;
    }

    modifier validFunding() {
        _validFunding();
        _;
    }

    constructor(uint256 unlockCost, uint256[] memory chainList)
        public
        Controller()
    {
        UNLOCK_COST = unlockCost;
        for (uint i = 0; i < chainList.length; i++) {
            isSupportedChain[chainList[i]] = true;
        }
    }

    function setForceFunding(bool _forceFunding) external onlyOwner() {
        forceFunding = _forceFunding;
    }

    function whiteListChain(uint256 _chainId, bool _whiteList) external onlyOwner() {
        isSupportedChain[_chainId] = _whiteList;
    }

    function process(uint256 i) external onlyOperator() {
        CrossChainTransfer memory cct = outwardTransfers[i];
        outwardTransfers[i].processed = true;
        if (forceFunding) msg.sender.sendValue(cct.gasPrice * PROCESS_COST);
        emit CrossChainTransferProcessed(cct.to, cct.amount, cct.chain);
    }

    function fundUnlock(
        uint256 satelliteChain,
        uint256 i,
        address to,
        uint256 amount
    ) external payable {
        uint256 funds = msg.value.div(UNLOCK_COST);
        require(
            funds != 0,
            "MultiBridge::fundUnlock: Incorrect amount of funds supplied"
        );
        bytes32 h = keccak256(abi.encode(satelliteChain, i, to, amount));
        require(
            inwardTransferFunding[h] != PROCESSED,
            "MultiBridge::fundUnlock: Transaction already unlocked"
        );
        require(
            inwardTransferFunding[h] == 0,
            "MultiBridge::fundUnlock: Funding already provided"
        );
        inwardTransferFunding[h] = funds;
        emit CrossChainUnlockFundsReceived(to, amount, satelliteChain, i);
    }

    function _validChain(uint256 chain) private view {
        require(
            isSupportedChain[chain],
            "MultiBridge::lock: Invalid chain specified"
        );
    }

    function _validFunding() private view {
        // Ensure sufficient funds accompany deposit to fund migration
        require(
            !forceFunding || tx.gasprice.mul(PROCESS_COST) <= msg.value,
            "MultiBridge::lock: Insufficient funds provided to fund migration"
        );
    }

    function checkTxProcessed(
        uint256 satelliteChain,
        uint256 i,
        address to,
        uint256 amount
    ) external view returns (bool) {
        return
            inwardTransferFunding[
                keccak256(abi.encode(satelliteChain, i, to, amount))
            ] == PROCESSED;
    }

    function lock(
        address to,
        uint256 amount,
        uint256 chain
    ) external payable virtual;

    function unlock(
        uint256 satelliteChain,
        uint256 i,
        address to,
        uint256 amount
    ) external virtual;

    function safe88(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint88)
    {
        require(n < 2**88, errorMessage);
        return uint88(n);
    }
}
