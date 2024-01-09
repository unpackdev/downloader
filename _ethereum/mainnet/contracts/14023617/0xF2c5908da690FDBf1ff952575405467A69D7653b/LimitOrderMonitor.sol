// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.5;
pragma abicoder v2;

import "./SafeMath.sol";
import "./Initializable.sol";

import "./KeeperCompatibleInterface.sol";
import "./AggregatorV3Interface.sol";
import "./KeeperBase.sol";

import "./TransferHelper.sol";
import "./IUniswapV3Factory.sol";

import "./IOrderMonitor.sol";
import "./IOrderManager.sol";

/// @title  LimitOrderMonitor
contract LimitOrderMonitor is
    Initializable,
    IOrderMonitor,
    KeeperCompatibleInterface,
    KeeperBase {

    using SafeMath for uint256;

    uint256 private constant MAX_INT = 2**256 - 1;
    uint256 private constant MAX_BATCH_SIZE = 100;
    uint256 private constant MAX_MONITOR_SIZE = 10000;

    event BatchProcessed(uint256 batchSize, uint256 gasUsed,
        uint256 paymentPaid, bytes data);

    /// @dev when batch size have changed
    event BatchSizeChanged(address from, uint256 newValue);

    /// @dev when monitor size have changed
    event MonitorSizeChanged(address from, uint256 newValue);

    /// @dev when upkeep interval changed
    event UpkeepIntervalChanged(address from, uint256 newValue);

    /// @dev when controller has changed
    event ControllerChanged(address from, address newValue);

    /// @dev when keeper has changed
    event KeeperChanged(address from, address newValue);

    /// @dev when monitor is started
    event MonitorStarted(uint256 tokenId);

    /// @dev when monitor is stopped
    event MonitorStopped(uint256 tokenId);

    /// @dev tokenIds index per token id
    mapping (uint256 => uint256) public tokenIndexPerTokenId;

    /// @dev tokens to monitor
    uint256[] public tokenIds;

    /// @dev controller address; could be DAO
    address public controller;

    /// @dev keeper address; can do upkeep
    address public keeper;

    /// @dev order manager
    IOrderManager public orderManager;

    /// @dev univ3 factory
    IUniswapV3Factory public factory;

    /// @dev krom token
    IERC20 public KROM;

    /// @dev last upkeep block
    uint256 public lastUpkeep;

    /// @dev max batch size
    uint256 public batchSize;

    /// @dev max monitor size
    uint256 public override monitorSize;

    /// @dev interval between 2 upkeeps, in blocks
    uint256 public upkeepInterval;

    function initialize (IOrderManager _orderManager,
        IUniswapV3Factory _factory,
        IERC20 _KROM,
        address _keeper,
        uint256 _batchSize,
        uint256 _monitorSize,
        uint256 _upkeepInterval) public initializer {

        require(_batchSize <= MAX_BATCH_SIZE, "INVALID_BATCH_SIZE");
        require(_monitorSize <= MAX_MONITOR_SIZE, "INVALID_MONITOR_SIZE");
        require(_batchSize <= _monitorSize, "SIZE_MISMATCH");

        orderManager = _orderManager;
        factory = _factory;
        KROM = _KROM;

        batchSize = _batchSize;
        monitorSize = _monitorSize;
        upkeepInterval = _upkeepInterval;

        controller = msg.sender;
        keeper = _keeper;

        require(KROM.approve(address(orderManager), MAX_INT));
    }
    
    function startMonitor(uint256 _tokenId) external override {

        isAuthorizedTradeManager(); 
        require(tokenIds.length < monitorSize, "MONITOR_FULL");
        tokenIds.push(_tokenId);
        tokenIndexPerTokenId[_tokenId] = tokenIds.length;

        emit MonitorStarted(_tokenId);
    }

    function stopMonitor(uint256 _tokenId) external override {
        
        isAuthorizedTradeManager();
        _stopMonitor(_tokenId);
        emit MonitorStopped(_tokenId);
    }

    function checkUpkeep(
        bytes calldata
    )
    external override cannotExecute
    returns (
        bool upkeepNeeded,
        bytes memory performData
    ) {

        if (upkeepNeeded = (_getBlockNumber() - lastUpkeep) > upkeepInterval) {
            uint256 _tokenId;
            uint256[] memory batchTokenIds = new uint256[](batchSize);
            uint256 count;

            // iterate through all active tokens;
            for (uint256 i = 0; i < tokenIds.length; i++) {
                _tokenId = tokenIds[i];
                (upkeepNeeded,,) = orderManager.canProcess(
                    _tokenId,
                    _getGasPrice(tx.gasprice)
                );
                if (upkeepNeeded) {
                    batchTokenIds[count] = _tokenId;
                    count++;
                }
                if (count >= batchSize) {
                    break;
                }
            }

            upkeepNeeded = count > 0;
            if (upkeepNeeded) {
                performData = abi.encode(batchTokenIds, count);
            }
        }
    }

    function performUpkeep(
        bytes calldata performData
    ) external override {

        uint256 _gasUsed = gasleft();

        (uint256[] memory _tokenIds, uint256 _count) = abi.decode(
            performData, (uint256[], uint256)
        );

        uint256 serviceFeePaid;
        uint256 monitorFeePaid;
        uint256 validCount;

        {
            bool validTrade;
            uint256 _serviceFee;
            uint256 _monitorFee;
            uint256 _tokenId;

            require(_count <= _tokenIds.length);
            for (uint256 i = 0; i < _count; i++) {
                _tokenId = _tokenIds[i];
                (validTrade, _serviceFee, _monitorFee) = orderManager.canProcess(_tokenId, tx.gasprice);
                if (validTrade) {
                    validCount++;
                    _stopMonitor(_tokenId);
                    orderManager.processLimitOrder(
                        _tokenId, _serviceFee, _monitorFee
                    );
                    serviceFeePaid = serviceFeePaid.add(_serviceFee);
                    monitorFeePaid = monitorFeePaid.add(_monitorFee);
                }
            }
        }

        require(validCount > 0);

        _gasUsed = _gasUsed - gasleft();
        lastUpkeep = _getBlockNumber();

        // send the paymentPaid to the keeper
        _transferFees(monitorFeePaid, keeper);
        // send the diff to the fee address
        _transferFees(serviceFeePaid.sub(monitorFeePaid), orderManager.feeAddress());

        emit BatchProcessed(
            validCount,
            _gasUsed,
            serviceFeePaid,
            performData
        );
    }

    function setBatchSize(uint256 _batchSize) external {

        isAuthorizedController();
        require(_batchSize <= MAX_BATCH_SIZE, "INVALID_BATCH_SIZE");
        require(_batchSize <= monitorSize, "SIZE_MISMATCH");

        batchSize = _batchSize;
        emit BatchSizeChanged(msg.sender, _batchSize);
    }

    function setMonitorSize(uint256 _monitorSize) external {

        isAuthorizedController();
        require(_monitorSize <= MAX_MONITOR_SIZE, "INVALID_MONITOR_SIZE");
        require(_monitorSize >= batchSize, "SIZE_MISMATCH");

        monitorSize = _monitorSize;
        emit MonitorSizeChanged(msg.sender, _monitorSize);
    }

    function setUpkeepInterval(uint256 _upkeepInterval) external  {

        isAuthorizedController();
        upkeepInterval = _upkeepInterval;
        emit UpkeepIntervalChanged(msg.sender, _upkeepInterval);
    }

    function changeController(address _controller) external {
        
        isAuthorizedController();
        controller = _controller;
        emit ControllerChanged(msg.sender, _controller);
    }

    function changeKeeper(address _keeper) external {

        isAuthorizedController();
        keeper = _keeper;
        emit KeeperChanged(msg.sender, _keeper);
    }

    function _stopMonitor(uint256 _tokenId) internal {

        uint256 tokenIndexToRemove = tokenIndexPerTokenId[_tokenId] - 1;
        uint256 lastTokenId = tokenIds[tokenIds.length - 1];

        removeElementFromArray(tokenIndexToRemove, tokenIds);

        if (tokenIds.length == 0) {
            delete tokenIndexPerTokenId[lastTokenId];
        } else if (tokenIndexToRemove != tokenIds.length) {
            tokenIndexPerTokenId[lastTokenId] = tokenIndexToRemove + 1;
            delete tokenIndexPerTokenId[_tokenId];
        }
    }

    // TODO override for chainlink (use fast gas)
    function _getGasPrice(uint256 _txnGasPrice) internal virtual view
    returns (uint256 gasPrice) {
        gasPrice = _txnGasPrice > 0 ? _txnGasPrice : 0;
    }

    // TODO (override block numbers for L2)
    function _getBlockNumber() internal virtual view
    returns (uint256 blockNumber) {
        blockNumber = block.number;
    }

    function _transferFees(uint256 _amount, address _owner) internal virtual {
        if (_amount > 0) {
            TransferHelper.safeTransfer(address(KROM), _owner, _amount);
        }
    }

    function getTokenIdsLength() external view override returns (uint256) {
        return tokenIds.length;
    }

    function isAuthorizedController() internal view {
        require(msg.sender == controller);
    }

    function isAuthorizedTradeManager() internal view {
        require(msg.sender == address(orderManager));
    }

    /// @notice Removes index element from the given array.
    /// @param  index index to remove from the array
    /// @param  array the array itself
    function removeElementFromArray(uint256 index, uint256[] storage array) private {
        if (index == array.length - 1) {
            array.pop();
        } else {
            array[index] = array[array.length - 1];
            array.pop();
        }
    }
}