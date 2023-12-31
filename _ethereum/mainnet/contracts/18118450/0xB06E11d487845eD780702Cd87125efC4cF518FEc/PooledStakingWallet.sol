// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./OwnableUpgradeable.sol";
import "./IDepositContract.sol";

contract PooledStakingWallet is OwnableUpgradeable {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice the ETH2 deposit contract
    IDepositContract public immutable depositContract =
        IDepositContract(address(0x00000000219ab540356cBB839Cbe05303d7705Fa));

    address public manager;
    address public commissionReceiver;
    uint256 public commissionPct;

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/
    event Initialize(address _commissionAddr, uint256 _commissionPct);
    event UpdateManager(address _Manager);
    event UpdateCommissionPct(uint256 _commissionPct);
    event UpdateCommissionAddr(address _commissionAddr);

    /*//////////////////////////////////////////////////////////////
                            MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier onlyManager() {
        require(msg.sender == manager, "NOT_MANAGER");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZER
    //////////////////////////////////////////////////////////////*/

    function initialize(address commissionAddr, uint256 commissionPct_) public initializer {
        commissionReceiver = commissionAddr;
        commissionPct = commissionPct_;
        __Ownable_init();
        emit Initialize(commissionAddr, commissionPct_);
    }
    /*//////////////////////////////////////////////////////////////
                            OWNER METHOD
    //////////////////////////////////////////////////////////////*/

    function setManager(address managerAddr) external onlyOwner {
        require(managerAddr != address(0), "ZERO_ADDRESS");
        require(manager != managerAddr, "MANAGER_REPEAT");
        manager = managerAddr;
        emit UpdateManager(managerAddr);
    }

    function setCommissionPct(uint256 _commissionPct) external onlyOwner {
        require(_commissionPct <= 1e4, "invalid commission percentage");
        commissionPct = _commissionPct;
        emit UpdateCommissionPct(_commissionPct);
    }

    function setCommissionAddr(address commissionAddr) external onlyOwner {
        require(commissionAddr != address(0), "ZERO_ADDRESS");
        require(commissionReceiver != commissionAddr, "COMMISSION_REPEAT");
        commissionReceiver = commissionAddr;
        emit UpdateCommissionAddr(commissionAddr);
    }

    /*//////////////////////////////////////////////////////////////
                            MANAGER MOTHOD
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice deposit Ether to ETH2 deposit contract only called by manager
     * @param pubkey A BLS12-381 public key.
     * @param signature A BLS12-381 signature.
     * @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
     * Used as a protection against malformed input.
     */
    function doEth2Deposit(bytes calldata pubkey, bytes calldata signature, bytes32 deposit_data_root)
        external
        payable
        onlyManager
    {
        depositContract.deposit{value: 32 ether}(
            pubkey, abi.encodePacked(uint96(0x010000000000000000000000), address(this)), signature, deposit_data_root
        );
    }

    function withdraw(address user, uint256 ethAmount, uint256 profit) external onlyManager {
        uint256 commission = 1e18 * profit * commissionPct / 1e22;
        payable(commissionReceiver).transfer(commission);
        (bool succeed,) = payable(user).call{value: ethAmount - commission}("");
        require(succeed, "Failed to withdraw");
    }

    receive() external payable {}
}
