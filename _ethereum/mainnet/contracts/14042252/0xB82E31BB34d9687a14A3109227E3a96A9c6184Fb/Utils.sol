// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./ECDSA.sol";

/*
 * 基本合约
 */
contract Base is Ownable, AccessControl, Pausable {
    // 调试日志事件
    event DebugLog(string info);

    // 检查指定地址是否是合约地址
    modifier isContract(address account) {
        require(Address.isContract(account), 'Caller is not a contract address');
        _;
    }

    // 检查指定地址是否是外部地址
    modifier isExternal(address account) {
        require(!Address.isContract(account), 'Caller is not a external address');
        _;
    }

    // 基本合约的构造函数
    constructor() {
        //在合约构造时，为所有者设置默认管理员角色，只有默认管理员可以动态授予和撤销角色
        _setupRole(DEFAULT_ADMIN_ROLE, owner());
    }

    // 打印调试日志
    function debugLog(string memory info) internal {
        emit DebugLog(info);
    }
}

/*
 * 工具库
 */
library Utils {
    // 通用验证签名，明文需要调用abi.encodePacked(...)获取message
    function validSign(address from, bytes memory message, bytes memory sign) internal pure returns (bool) {
        bytes32 _message = ECDSA.toEthSignedMessageHash(keccak256(message));
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(_message, sign);

        if (error != ECDSA.RecoverError.NoError) {
            //验证签名错误
            return false;
        }

        if (from != recovered) {
            //验证签名地址错误
            return false;
        }

        return true;
    }

    // 将地址转换为uint160
    function addressToUint160(address account) internal pure returns (uint160) {
        return uint160(account);
    }

    // 将uint160转换为地址
    function uint160ToAddress(uint160 value) internal pure returns (address) {
        return address(value);
    }

    // 将地址转换为uint256
    function addressToUint256(address account) internal pure returns (uint256) {
        return uint256(uint160(account));
    }

    // 将uint256转换为字符串
    function uint256ToString(uint256 value) internal pure returns (string memory) {
        return bytesToString(abi.encodePacked(value));
    }

    // 将指定地址转换为字符串
    function addressToString(address account) internal pure returns (string memory) {
        return bytesToString(abi.encodePacked(account));
    }

    // 将指定地址转换为字符串
    function bytesToString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}