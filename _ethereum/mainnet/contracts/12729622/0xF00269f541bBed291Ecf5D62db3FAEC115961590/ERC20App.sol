// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ScaleCodec.sol";
import "./OutboundChannel.sol";

enum ChannelId {Basic, Incentivized}

contract ERC20App is AccessControl {
    using SafeMath for uint256;
    using ScaleCodec for uint256;

    mapping(address => uint256) public balances;

    mapping(ChannelId => Channel) public channels;

    bytes2 constant MINT_CALL = 0x2f00;

    event Locked(
        address token,
        address sender,
        bytes32 recipient,
        uint256 amount
    );

    event Unlocked(
        address token,
        bytes32 sender,
        address recipient,
        uint256 amount
    );

    struct Channel {
        address outbound;
    }

    constructor(Channel memory _basic) {
        Channel storage c1 = channels[ChannelId.Basic];
        c1.outbound = _basic.outbound;
    }

    function lock(
        address _token,
        bytes32 _recipient,
        uint256 _amount,
        ChannelId _channelId
    ) public {
        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _amount),
            "Contract token allowances insufficient to complete this lock request"
        );
        require(_channelId == ChannelId.Basic, "Invalid channel ID");

        balances[_token] = balances[_token].add(_amount);

        emit Locked(_token, msg.sender, _recipient, _amount);

        bytes memory call = encodeCall(_token, msg.sender, _recipient, _amount);

        OutboundChannel channel =
            OutboundChannel(channels[_channelId].outbound);
        channel.submit(msg.sender, call);
    }

    // SCALE-encode payload
    function encodeCall(
        address _token,
        address _sender,
        bytes32 _recipient,
        uint256 _amount
    ) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                MINT_CALL,
                _token,
                _sender,
                byte(0x00), // Encode recipient as MultiAddress::Id
                _recipient,
                _amount.encode256()
            );
    }
}
