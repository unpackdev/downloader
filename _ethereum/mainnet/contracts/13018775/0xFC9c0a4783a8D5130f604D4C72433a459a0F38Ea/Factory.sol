// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;

// ============ Contract information ============

/**
 * @title  InterestRateSwapFactory
 * @notice A deployment contract for Greenwood basis swap pools
 * @author Greenwood Labs
 */

 // ============ Imports ============

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./FactoryUtils.sol";

contract Factory {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Immutable storage ============

    address private immutable governance;

    // ============ Mutable storage ============

    mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => address))))) public getPool;
    mapping(uint256 => bool) public swapDurations;
    mapping(uint256 => bool) public protocols;
    mapping(uint256 => mapping(address => bool)) public protocolMarkets;
    mapping(uint256 => address) public protocolAdapters;
    mapping(address => uint256) public underlierDecimals;
    mapping(address => Params) public getParamsByPool;
    address[] public allPools;
    uint256 public swapDurationCount;
    uint256 public protocolCount;
    uint256 public protocolMarketCount;
    bool public isPaused;

    // ============ Structs ============

    struct Params {
        uint256 durationInSeconds;
        uint256 position;
        uint256 protocol0;
        uint256 protocol1;
        address underlier;
    }

    struct FeeParams {
        uint256 rateLimit;
        uint256 rateSensitivity;
        uint256 utilizationInflection;
        uint256 rateMultiplier;
    }

    // ============ Events ============

    event PoolCreated(        
        uint256 durationInSeconds,
        address pool,
        uint256 position,
        uint256[] protocols,
        address indexed underlier,
        uint256 poolLength
    );

    // ============ Constructor ============

    constructor(
        address _governance
    ) {
        governance = _governance;
    }

    // ============ Modifiers ============

    modifier onlyGovernance {
        // assert that the caller is governance
        require(msg.sender == governance);
        _;
    }

    // ============ External methods ============

    // ============ Get the number of created pools ============

    function allPoolsLength() external view returns (uint256) {
        
        // return the length of the allPools array
        return allPools.length;
    }

    // ============ Pause and unpause the factory ============

    function togglePause() external onlyGovernance() returns (bool){

        // toggle the value of isPaused
        isPaused = !isPaused;

        return true;
    }

    // ============ Update the supported swap durations ============

    function updateSwapDurations(
        uint256 _duration,
        bool _is_supported
    ) external onlyGovernance() returns (bool){

        // get the initial value
        bool initialValue = swapDurations[_duration];

        // update the swapDurations mapping
        swapDurations[_duration] = _is_supported;

        // check if a swapDuration is being added
        if (initialValue == false && _is_supported == true) {

            // increment the swapDurationCount
            swapDurationCount = swapDurationCount.add(1);

        }

        // check if a swapDuration is being removed
        else if (initialValue == true && _is_supported == false) {
            
            // decrement the swapDurationCount
            swapDurationCount = swapDurationCount.sub(1);

        }

        return true;

    }

    // ============ Update the supported protocols ============

    function updateProtocols(
        uint256 _protocol,
        bool _is_supported
    ) external onlyGovernance() returns (bool){

        // get the initial value
        bool initialValue = protocols[_protocol];

        // update the protocols mapping
        protocols[_protocol] = _is_supported;

        // check if a protocol is being added
        if (initialValue == false && _is_supported == true) {

            // increment the protocolCount
            protocolCount = protocolCount.add(1);

        }

        // check if a protocol is being removed
        else if (initialValue == true && _is_supported == false) {

            // decrement the protocolCount
            protocolCount = protocolCount.sub(1);

        }

        return true;

    }

    // ============ Update the supported protocol markets ============

    function updateProtocolMarkets(
        uint256 _protocol,
        address _market,
        bool _is_supported
    ) external onlyGovernance() returns (bool){

        // get the initial value
        bool initialValue = protocolMarkets[_protocol][_market];

        // update the protocolMarkets mapping
        protocolMarkets[_protocol][_market] = _is_supported;

        // check if a protocol market is being added
        if (initialValue == false && _is_supported == true) {

            // increment the protocolMarketCount
            protocolMarketCount = protocolMarketCount.add(1);

        }

        // check if a protocol market is being removed
        else if (initialValue == true && _is_supported == false) {

            // decrement the protocolMarketCount
            protocolMarketCount = protocolMarketCount.sub(1);

        }

        return true;

    }

    // ============ Update the protocol adapters mapping ============

    function updateProtocolAdapters(
        uint256 _protocol,
        address _adapter
    ) external onlyGovernance() returns(bool) {

        // update the protocolMarkets mapping
        protocolAdapters[_protocol] = _adapter;

        return true;
        
    }

    // ============ Update the underlier decimals mapping ============

    function updateUnderlierDecimals (
        address _underlier,
        uint256 _decimals
    ) external onlyGovernance() returns (bool) {

        require(_decimals <= 18, '20');

        // update the underlierDecimals mapping
        underlierDecimals[_underlier] = _decimals;

        return true;

    }


    // ============ Create a new pool ============

    function createPool(
        uint256 _duration,
        uint256 _position,
        uint256[] memory _protocols,
        address _underlier,
        uint256 _initialDeposit,
        uint256 _rateLimit,
        uint256 _rateSensitivity,
        uint256 _utilizationInflection,
        uint256 _rateMultiplier
    ) external returns (address pool) {

        // assert that the factory is not paused
        require(isPaused == false, '1');

        // assert that the duration of the swap is supported
        require(swapDurations[_duration] == true, '2');

        // assert that the position is supported
        require(_position == 0 || _position == 1, '3');

        // assert that the protocols are not the same
        require(_protocols[0] != _protocols[1], '4');

        // assert that both protocols are supported
        require(protocols[_protocols[0]] && protocols[_protocols[1]], '4');

        // assert that the specified protocols support the specified underlier
        require(protocolMarkets[_protocols[0]][_underlier] && protocolMarkets[_protocols[1]][_underlier], '5');

        // assert that the pool has not already been created
        require(getPool[_underlier][_protocols[0]][_protocols[1]][_duration][_position] == address(0), '6');

        // assert that the adapter for the specified protocol0 is defined
        require(protocolAdapters[_protocols[0]] != address(0), '7');

        // assert that the adapter for the specified protocol1 is defined
        require(protocolAdapters[_protocols[1]] != address(0), '7');

        // assert that the decimals for the underlier is defined
        require(underlierDecimals[_underlier] != 0, '8');

        FeeParams memory feeParams;
        bytes memory initCode;
        bytes32 salt;

        // scope to avoid stack too deep errors
        {
            feeParams = FeeParams(
                _rateLimit,
                _rateSensitivity,
                _utilizationInflection,
                _rateMultiplier
            );
        }

        // scope to avoid stack too deep errors
        {
            // generate byte code
            (bytes memory encodedParams, bytes memory encodedPackedParams) = _generateByteCode(
                _duration,
                _position,
                _protocols,
                _underlier,
                _initialDeposit,
                feeParams
            );

            // generate the init code
            initCode = FactoryUtils.generatePoolInitCode(encodedParams);

            // generate the salt
            salt = keccak256(encodedPackedParams);
        }

        // get the address of the pool
        assembly {
            pool := create2(0, add(initCode, 32), mload(initCode), salt)
        }

        // add the pool to the registry
        getPool[_underlier][_protocols[0]][_protocols[1]][_duration][_position] = pool;
        getParamsByPool[pool] = Params(_duration, _position, _protocols[0], _protocols[1], _underlier);
        allPools.push(pool);

        // transfer the initial deposit into the pool
        IERC20(_underlier).safeTransferFrom(
            msg.sender,
            pool,
            _initialDeposit
        );

        // emit a PoolCreated event
        emit PoolCreated(
            _duration,
            pool,
            _position,
            _protocols,
            _underlier,
            allPools.length
        );

    }

    // ============ Internal functions ============

    // ============ Generates byte code for pool creation ============

    function _generateByteCode(
        uint256 _duration,
        uint256 _position,
        uint256[] memory _protocols,
        address _underlier,
        uint256 _initialDeposit,
        FeeParams memory feeParams
    ) internal view returns (bytes memory encodedParams, bytes memory encodedPackedParams) {
        
        // create the initcode
        encodedParams = abi.encode(
                _underlier,
                underlierDecimals[_underlier],
                protocolAdapters[_protocols[0]],
                protocolAdapters[_protocols[1]],
                _protocols[0],
                _protocols[1],
                _position,
                _duration,
                _initialDeposit,
                feeParams.rateLimit,
                feeParams.rateSensitivity,
                feeParams.utilizationInflection,
                feeParams.rateMultiplier,
                msg.sender
        );

        // create the salt
        encodedPackedParams = abi.encodePacked(
                 _underlier,
                underlierDecimals[_underlier],
                protocolAdapters[_protocols[0]],
                protocolAdapters[_protocols[1]],
                _protocols[0],
                _protocols[1],
                _position,
                _duration,
                _initialDeposit,
                feeParams.rateLimit,
                feeParams.rateSensitivity,
                feeParams.utilizationInflection,
                feeParams.rateMultiplier,
                msg.sender
        );
    }   
}