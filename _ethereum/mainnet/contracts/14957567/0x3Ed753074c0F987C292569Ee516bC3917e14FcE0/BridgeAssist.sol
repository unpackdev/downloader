// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract BridgeAssist {
    IERC20 public erc20;

    struct Lock {
        uint256 amount;
        string targetAddr;
    }

    address public mainBackend;
    address public feeAddress;
    mapping(address => bool) public isBackend;

    mapping(address => Lock) locks;

    event Upload(address indexed account, uint256 indexed amount, string indexed target);
    event Dispense(address indexed account, uint256 indexed amount, uint256 indexed fee);

    modifier onlyBackend() {
        require(
            isBackend[msg.sender],
            "This function is restricted to backend"
        );
        _;
    }

    modifier onlyMainBackend() {
        require(
            msg.sender == mainBackend,
            "This function is restricted to the main backend"
        );
        _;
    }

    /**
     * @param _erc20 ERC-20/BEP-20 token
     * @param _feeAddress ETH/BSC fee wallet address
     * @param _mainBackend Main backend ETH/BSC wallet address
     */
    constructor(IERC20 _erc20, address _feeAddress, address _mainBackend) {
        erc20 = _erc20;
        feeAddress = _feeAddress;
        mainBackend = _mainBackend;
        isBackend[_mainBackend] = true;
    }

    /**
     * @notice Locking tokens on the bridge to swap in the direction of ETH/BSC->Solana
     * @dev Creating lock structure and transferring the number of tokens to the bridge address
     * @param _amount Number of tokens to swap
     * @param _target Solana wallet address
     */
    function upload(uint256 _amount, string memory _target) external {
        require(_amount > 0, "Amount should be more than 0");
        require(
            locks[msg.sender].amount == 0,
            "Your current lock is not equal to 0"
        );

        erc20.transferFrom(msg.sender, address(this), _amount);
        locks[msg.sender].amount = _amount;
        locks[msg.sender].targetAddr = _target;
        emit Upload(msg.sender, _amount, _target);
    }

    /**
     * @notice Dispensing tokens from the bridge by the backend to swap in the direction of Solana->ETH/BSC
     * @param _account ETH/BSC wallet address
     * @param _amount Number of tokens to dispense
     * @param _fee Fee amount
     */
    function dispense(address _account, uint256 _amount, uint256 _fee) external onlyBackend {
        erc20.transfer(_account, _amount);
        erc20.transfer(feeAddress, _fee);
        emit Dispense(_account, _amount, _fee);
    }

    /**
     * @notice Backend function to clear user lock in the swap token process
     * @param _account ETH/BSC wallet address
     */
    function clearLock(address _account) external onlyBackend {
        locks[_account].amount = 0;
        locks[_account].targetAddr = "";
    }

    /**
     * @notice Adding new backend addresses
     * @param _backend Backend ETH/BSC wallet addresses
     */
    function addBackend(address[] calldata _backend) external onlyMainBackend {
        require(_backend.length <= 100, "Array size should be less than or equal to 100");
        for (uint256 i = 0; i < _backend.length; ++i) {
            isBackend[_backend[i]] = true;
        }
    }

    /**
     * @notice Removing backend addresses
     * @param _backend Backend ETH/BSC wallet addresses
     */
    function removeBackend(address[] calldata _backend) external onlyMainBackend {
        require(_backend.length <= 100, "Array size should be less than or equal to 100");
        for (uint256 i = 0; i < _backend.length; ++i) {
            isBackend[_backend[i]] = false;
        }
    }

    /**
     * @notice Changing fee address
     * @param _feeAddress ETH/BSC fee wallet address
     */
    function changeFeeAddress(address _feeAddress) external onlyMainBackend {
        feeAddress = _feeAddress;
    }

    /**
     * @notice Viewing the lock structure for the user
     * @dev This function is used for the verfication of uploading tokens
     * @param _account BSC wallet address
     * @return userLock Lock structure for the user
     */
    function checkUserLock(address _account)
        external
        view
        returns (Lock memory userLock)
    {
        userLock.amount = locks[_account].amount;
        userLock.targetAddr = locks[_account].targetAddr;
    }
}
