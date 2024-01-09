// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Interfaces.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";


contract StashFactoryV2 {
    using Address for address;

    bytes4 private constant rewarded_token = 0x16fa50b1; //rewarded_token()
    bytes4 private constant reward_tokens = 0x54c49fe9; //reward_tokens(uint256)
    bytes4 private constant rewards_receiver = 0x01ddabf1; //rewards_receiver(address)
    address public constant proxyFactory = 0x66807B5598A848602734B82E432dD88DBE13fC8f;

    address public immutable operator; // booster
    address public immutable rewardFactory;

    address public v1Implementation;
    address public v2Implementation;
    address public v3Implementation;

    constructor(address _operator, address _rewardFactory) {
        operator = _operator;
        rewardFactory = _rewardFactory;
    }

    function setImplementation(address _v1, address _v2, address _v3) external {
        require(msg.sender == IDeposit(operator).owner(), "!auth");

        v1Implementation = _v1;
        v2Implementation = _v2;
        v3Implementation = _v3;
    }

    //Create a stash contract for the given gauge.
    //function calls are different depending on the version of curve gauges so determine which stash type is needed
    function CreateStash(uint256 _pid, address _gauge, address _staker, uint256 _stashVersion) external returns(address) {
        require(msg.sender == operator, "!authorized");

        if (_stashVersion == uint256(3) && IsV3(_gauge)) {
            //v3
            require(v3Implementation != address(0), "0 impl");
            address stash = IProxyFactory(proxyFactory).clone(v3Implementation);
            IStash(stash).initialize(_pid, operator, _staker, _gauge, rewardFactory);
            return stash;
        } else if (_stashVersion == uint256(1) && IsV1(_gauge)) {
            //v1
            require(v1Implementation != address(0), "0 impl");
            address stash = IProxyFactory(proxyFactory).clone(v1Implementation);
            IStash(stash).initialize(_pid, operator, _staker, _gauge, rewardFactory);
            return stash;
        } else if (_stashVersion == uint256(2) && !IsV3(_gauge) && IsV2(_gauge)) {
            //v2
            require(v2Implementation != address(0), "0 impl");
            address stash = IProxyFactory(proxyFactory).clone(v2Implementation);
            IStash(stash).initialize(_pid, operator, _staker, _gauge, rewardFactory);
            return stash;
        }
        bool isV1 = IsV1(_gauge);
        bool isV2 = IsV2(_gauge);
        bool isV3 = IsV3(_gauge);
        require(!isV1 && !isV2 && !isV3, "stash version mismatch");
        return address(0);
    }

    function IsV1(address _gauge) private returns(bool) {
        bytes memory data = abi.encode(rewarded_token);
        (bool success,) = _gauge.call(data);
        return success;
    }

    function IsV2(address _gauge) private returns(bool) {
        bytes memory data = abi.encodeWithSelector(reward_tokens,uint256(0));
        (bool success,) = _gauge.call(data);
        return success;
    }

    function IsV3(address _gauge) private returns(bool) {
        bytes memory data = abi.encodeWithSelector(rewards_receiver,address(0));
        (bool success,) = _gauge.call(data);
        return success;
    }
}