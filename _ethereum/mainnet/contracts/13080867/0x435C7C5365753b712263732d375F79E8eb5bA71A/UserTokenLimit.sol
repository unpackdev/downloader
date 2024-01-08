// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./SafeMath.sol";
import "./Configable.sol";

contract UserTokenLimit is Configable {
    using SafeMath for uint;

    struct TokenLimit {
        bool enabled;
        uint blocks;
        uint amount;
    }
    //key:(token)
    mapping(address => TokenLimit) public tokenLimits;

    struct UserLimit {
        uint lastBlock;
        uint consumption;
    }
    //key:(white user, token)
    mapping(address => mapping(address => UserLimit)) public userLimits;

    function setTokenLimit(address _token, bool _enabled, uint _blocks, uint _amount) public onlyManager {
        TokenLimit storage limit = tokenLimits[_token];
        limit.enabled = _enabled;
        limit.blocks = _blocks;
        limit.amount = _amount;
    }

    function setTokenLimits(address[] memory _token, bool[] memory _enabled, uint[] memory _blocks, uint[] memory _amount) external onlyManager {
        require(
            _token.length == _enabled.length 
            && _enabled.length == _blocks.length 
            && _blocks.length == _amount.length 
            , "UserTokenLimit: INVALID_PARAM"
        );
        for (uint i; i < _token.length; i++) {
            setTokenLimit(_token[i], _enabled[i], _blocks[i], _amount[i]);
        }
    }

    function setTokenLimitEnable(address _token, bool _enabled) public onlyManager {
        TokenLimit storage limit = tokenLimits[_token];
        limit.enabled = _enabled;
    }

    function setTokenLimitEnables(address[] memory _token, bool[] memory _enabled) external onlyManager {
        require(
            _token.length == _enabled.length 
            , "UserTokenLimit: INVALID_PARAM"
        );
        for (uint i; i < _token.length; i++) {
            setTokenLimitEnable(_token[i], _enabled[i]);
        }
    }

    function getUserLimit(address _user, address _token, uint _value) public view returns (uint) {
        TokenLimit memory tokenLimit = tokenLimits[_token];
        if (tokenLimit.enabled == false) {
            return _value;
        }
        
        if(_value > tokenLimit.amount) {
            _value = tokenLimit.amount;
        }

        UserLimit memory limit = userLimits[_user][_token];
        if (block.number.sub(limit.lastBlock) >= tokenLimit.blocks) {
            return _value;
        }

        if (limit.consumption.add(_value) > tokenLimit.amount) {
            _value = tokenLimit.amount.sub(limit.consumption);
        }
        return _value;
    }

    function _updateUserTokenLimit(address _token, uint _value) internal {
        TokenLimit memory tokenLimit = tokenLimits[_token];
        if(tokenLimit.enabled == false) {
            return;
        }

        UserLimit storage limit = userLimits[msg.sender][_token];
        if(block.number.sub(limit.lastBlock) > tokenLimit.blocks) {
            limit.consumption = 0;
        }
        limit.lastBlock = block.number;
        limit.consumption = limit.consumption.add(_value);
    }
}