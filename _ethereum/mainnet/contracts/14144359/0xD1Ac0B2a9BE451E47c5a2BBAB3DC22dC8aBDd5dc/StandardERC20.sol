/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./IMint.sol";
import "./IBurn.sol";
import "./IERC165.sol";
import "./Initializer.sol";
import "./Ownership.sol";
import "./ERC20.sol";
import "./ERC2612.sol";
import "./Multicall.sol";

/**
 * @title StandardERC20
 * @author yoonsung.eth
 * @notice ERC20과 ERC2612를 기본으로, ERC165, ERC173 명세를 구현하고 있습니다.
 */
contract StandardERC20 is ERC20, ERC2612, Ownership, Multicall, Initializer, IERC165, IBurn, IMint {
    /**
     * @notice ERC20을 초기화 합니다. 토큰의 이름, 심볼, 소수점 정보를 필요로 합니다. 이 함수는 실행될 때 단 한번만 실행됩니다.
     * 이 함수가 실행될 때 이 함수를 실행한 당사자가 해당 컨트랙트의 소유권을 받게됩니다.
     * @param data 토큰 이름, 토큰 심볼, 소수점 정보를 abi encode 하여, bytes 형태로 전달하여야 합니다.
     */
    function initialize(bytes calldata data) external initializer {
        (name, symbol, decimals) = abi.decode(data, (string, string, uint8));
        version = "1";
        balanceOf[address(this)] = type(uint256).max;
        _initDomainSeparator(name, version);
        _transferOwnership(msg.sender);
    }

    function mint(uint256 value) external onlyOwner returns (bool) {
        totalSupply += value;
        unchecked {
            balanceOf[msg.sender] += value;
        }
        emit Transfer(address(0), msg.sender, value);
        return true;
    }

    function mintTo(address to, uint256 value) external onlyOwner returns (bool) {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
        return true;
    }

    function burn(uint256 value) external onlyOwner returns (bool) {
        balanceOf[msg.sender] -= value;
        unchecked {
            totalSupply -= value;
        }
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    function burnFrom(address from, uint256 value) external onlyOwner returns (bool) {
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        unchecked {
            totalSupply -= value;
        }
        emit Transfer(from, address(0), value);
        return true;
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return
            type(IERC20).interfaceId == interfaceID ||
            type(IERC2612).interfaceId == interfaceID ||
            type(IERC173).interfaceId == interfaceID ||
            type(IERC165).interfaceId == interfaceID ||
            type(IMulticall).interfaceId == interfaceID ||
            type(IBurn).interfaceId == interfaceID ||
            type(IMint).interfaceId == interfaceID;
    }
}
