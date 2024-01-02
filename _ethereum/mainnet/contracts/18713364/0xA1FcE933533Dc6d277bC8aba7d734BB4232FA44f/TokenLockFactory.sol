// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./Clones.sol";
import "./ITokenLockFactory.sol";
import "./Address.sol";
import "./Ownable.sol";


/**
 * @title TokenLockFactory
 *  a factory of TokenLock contracts.
 *
 * This contract receives funds to make the process of creating TokenLock contracts
 * easier by distributing them the initial tokens to be managed.
 */
contract TokenLockFactory is ITokenLockFactory, Ownable {
    // -- Errors --

    error MasterCopyCannotBeZero();

    // -- State --

    address public masterCopy;
    mapping(address => uint256) public nonce;

    // -- Events --

    event MasterCopyUpdated(address indexed masterCopy);

    event TokenLockCreated(
        address indexed contractAddress,
        bytes32 indexed initHash,
        address indexed beneficiary,
        address token,
        uint256 managedAmount,
        uint256 startTime,
        uint256 endTime,
        uint256 periods,
        uint256 releaseStartTime,
        uint256 vestingCliffTime,
        bool revocable,
        bool canDelegate
    );

    /**
     * Constructor.
     * @param _masterCopy Address of the master copy to use to clone proxies
     * @param _governance Owner of the factory
     */
    constructor(address _masterCopy, address _governance) {
        _setMasterCopy(_masterCopy);
        _transferOwnership(_governance);
    }

    // -- Factory --
    /**
     * @notice Creates and fund a new token lock wallet using a minimum proxy
     * @param _token token to time lock
     * @param _owner Address of the contract owner
     * @param _beneficiary Address of the beneficiary of locked tokens
     * @param _managedAmount Amount of tokens to be managed by the lock contract
     * @param _startTime Start time of the release schedule
     * @param _endTime End time of the release schedule
     * @param _periods Number of periods between start time and end time
     * @param _releaseStartTime Override time for when the releases start
     * @param _revocable Whether the contract is revocable
     * @param _canDelegate Whether the contract should call delegate
     */
    function createTokenLock(
        address _token,
        address _owner,
        address _beneficiary,
        uint256 _managedAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _periods,
        uint256 _releaseStartTime,
        uint256 _vestingCliffTime,
        bool _revocable,
        bool _canDelegate
    ) external override returns(address contractAddress) {
        // Create contract using a minimal proxy and call initializer
        bytes memory initializer = abi.encodeWithSignature(
            "initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bool,bool)",
            _owner,
            _beneficiary,
            _token,
            _managedAmount,
            _startTime,
            _endTime,
            _periods,
            _releaseStartTime,
            _vestingCliffTime,
            _revocable,
            _canDelegate
        );

        contractAddress = _deployProxyPrivate(initializer,
        _beneficiary,
        _token,
        _managedAmount,
        _startTime,
        _endTime,
        _periods,
        _releaseStartTime,
        _vestingCliffTime,
        _revocable,
        _canDelegate);
    }

    /**
     * @notice Sets the masterCopy bytecode to use to create clones of TokenLock contracts
     * @param _masterCopy Address of contract bytecode to factory clone
     */
    function setMasterCopy(address _masterCopy) external override onlyOwner {
        _setMasterCopy(_masterCopy);
    }

    function _setMasterCopy(address _masterCopy) internal {
        if (_masterCopy == address(0))
            revert MasterCopyCannotBeZero();
        masterCopy = _masterCopy;
        emit MasterCopyUpdated(_masterCopy);
    }

    // This private function is to handle stack too deep issue
    function _deployProxyPrivate(
        bytes memory _initializer,
        address _beneficiary,
        address _token,
        uint256 _managedAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _periods,
        uint256 _releaseStartTime,
        uint256 _vestingCliffTime,
        bool _revocable,
        bool _canDelegate
    ) private returns (address contractAddress) {

        contractAddress = Clones.cloneDeterministic(masterCopy, keccak256(abi.encodePacked(msg.sender, nonce[msg.sender]++, _initializer)));

        Address.functionCall(contractAddress, _initializer);

        emit TokenLockCreated(
            contractAddress,
            keccak256(_initializer),
            _beneficiary,
            _token,
            _managedAmount,
            _startTime,
            _endTime,
            _periods,
            _releaseStartTime,
            _vestingCliffTime,
            _revocable,
            _canDelegate
        );
    }
}
