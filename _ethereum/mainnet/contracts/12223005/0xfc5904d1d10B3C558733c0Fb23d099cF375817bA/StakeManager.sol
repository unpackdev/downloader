pragma solidity >=0.8.0;

import "./IStake.sol";
import "./Stake.sol";
import "./Base.sol";

contract StakeManager is Base {
    event StakeCreated(address indexed from, address stakeToken, address rewardToken, address stake);

    event LibUpdated(address indexed newLib);

    address[] public stakes;

    address lib;

    constructor(address _config, address _lib) Base(_config) {
        require(_lib != address(0), "lib address = 0");
        lib = _lib;
    }

    /**
     * @dev update stake library
     */
    function updateLib(address _lib) external onlyCEO() {
        require(_lib != address(0), "lib address = 0");
        lib = _lib;
        emit LibUpdated(_lib);
    }

    /**
     * @dev return number of stake
     */
    function stakeCount() external view returns (uint256) {
        return stakes.length;
    }

    /**
     * @dev return array of all stake contracts
     * @return array of stakes
     */
    function allStakes() external view returns (address[] memory) {
        return stakes;
    }

    /**
     * @dev claim rewards of sepcified address of stakes
     */
    function claims(address[] calldata _stakes) external {
        for (uint256 i; i < _stakes.length; i++) {
            IStake(_stakes[i]).claim0(msg.sender);
        }
    }

    /**
     * @dev create a new stake contract
     * @param _stakeToken address of stakeable token
     * @param _startDate epoch seconds of mining start
     * @param _endDate epoch seconds of mining complete
     * @param _totalReward reward total
     */
    function createStake(
        address _stakeToken,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _totalReward
    ) external onlyCEO() {
        require(_stakeToken != address(0), "zero address");
        require(_endDate > _startDate, "_endDate <= _startDate");
        address rewardToken = config.protocolToken();

        address stakeAddress = clone(lib);
        IStake(stakeAddress).initialize(_stakeToken, rewardToken, _startDate, _endDate, _totalReward);
        TransferHelper.safeTransferFrom(rewardToken, msg.sender, stakeAddress, _totalReward);
        stakes.push(stakeAddress);
        emit StakeCreated(msg.sender, _stakeToken, rewardToken, stakeAddress);
        config.notify(IConfig.EventType.STAKE_CREATED, stakeAddress);
    }

    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }
}
