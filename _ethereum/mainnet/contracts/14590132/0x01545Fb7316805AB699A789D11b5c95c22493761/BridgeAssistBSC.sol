// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract BridgeAssistBSC {
    IERC20 public erc20;

    struct Lock {
        uint256 amount;
        string targetAddr;
    }

    address public backend;
    mapping(address => Lock) locks;

    event Upload(address indexed account, uint256 indexed amount, string indexed target);
    event Dispense(address indexed account, uint256 indexed amount);

    modifier onlyBackend() {
        require(
            msg.sender == backend,
            "This function is restricted to backend"
        );
        _;
    }

    /**
     * @param _erc20 ERC-20 token
     * @param _backend Backend BSC wallet address
     */
    constructor(IERC20 _erc20, address _backend) {
        erc20 = _erc20;
        backend = _backend;
    }

    /**
     * @notice Locking tokens on the bridge to swap in the direction of BSC->Solana
     * @dev Creating lock structure and transferring the number of tokens to the bridge address
     * @param _amount Number of tokens to swap
     * @param _target Solana wallet address
     */
    function upload(uint256 _amount, string memory _target) public {
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
     * @notice Dispensing tokens from the bridge by the backend to swap in the direction of Solana->BSC
     * @param _account BSC wallet address
     * @param _amount Number of tokens to dispense
     */
    function dispense(address _account, uint256 _amount) public onlyBackend {
        erc20.transfer(_account, _amount);
        emit Dispense(_account, _amount);
    }

    /**
     * @notice Backend function to clear user lock in the swap token process
     * @param _account BSC wallet address
     */
    function clearLock(address _account) public onlyBackend {
        locks[_account].amount = 0;
        locks[_account].targetAddr = "";
    }

    /**
     * @notice Viewing the lock structure for the user
     * @dev This function is used for the verfication of uploading tokens
     * @param _account BSC wallet address
     * @return userLock Lock structure for the user
     */
    function checkUserLock(address _account)
        public
        view
        returns (Lock memory userLock)
    {
        userLock.amount = locks[_account].amount;
        userLock.targetAddr = locks[_account].targetAddr;
    }
}
