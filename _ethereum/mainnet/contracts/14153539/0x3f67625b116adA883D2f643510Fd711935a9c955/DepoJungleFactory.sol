// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./DepoJungle.sol";

contract DepoJungleFactory is Ownable {
    event NewDepoJungleContract(address indexed depoJungle);

    constructor() public {
        //
    }

    /*
     * @notice Deploy the pool
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _endBlock: end block
     * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
     * @param _stakedTokenTransferFee: the transfer fee of stakedToken (if any, else 0)
     * @param _withdrawalInterval: the withdrawal interval for stakedToken (if any, else 0)
     * @param _admin: admin address with ownership
     * @return address of new depo jungle contract
     */
    function deployPool(
        IBEP20 _stakedToken,
        IBEP20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser,
        uint16 _stakedTokenTransferFee,
        uint256 _withdrawalInterval,
        address _admin
    ) external onlyOwner {
        require(_stakedToken.totalSupply() >= 0);
        require(_rewardToken.totalSupply() >= 0);
        require(_stakedToken != _rewardToken, "Tokens must be be different");

        bytes memory bytecode = type(DepoJungleInitializable).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(_stakedToken, _rewardToken, _startBlock)
        );
        address depoJungleAddress;

        assembly {
            depoJungleAddress := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }

        DepoJungleInitializable(depoJungleAddress).initialize(
            _stakedToken,
            _rewardToken,
            _rewardPerBlock,
            _startBlock,
            _bonusEndBlock,
            _poolLimitPerUser,
            _stakedTokenTransferFee,
            _withdrawalInterval,
            _admin
        );

        emit NewDepoJungleContract(depoJungleAddress);
    }
}