// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import "./TransferHelper.sol";
import "./Strings.sol";


library Helpers {
    function getPaths(
        address _token0,
        address _token1
    ) internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _token0;
        path[1] = _token1;
        return path;
    }
 
    function withdrawBalances(address token, address to, uint256 amount) internal {
    
            // transfor to owner 5% of profit 
            // TransferHelper.safeTransfer(
            //     _asset,
            //     owner(),
            //     amount.mul(5).div(100)
            // );
            // transfer to trader profit amounts of assets 
            TransferHelper.safeTransfer(token, to, amount);

        
        // withdraw all ETH
        // (bool success, ) = _initiator.call{ value: address(this).balance }("");
        // require(success, "transfer failed");
    }
    function getMessageUint(
        string memory name,
        uint256 value
    ) internal pure returns (string memory) {
        string(abi.encodePacked(name, Strings.toString(value)));
    }
    function getMessageAddr(
        string memory name,
        address account
    ) internal pure returns (string memory) {
        string(abi.encodePacked(name, bytesToString(abi.encodePacked(account))));
    }

    function bytesToString(bytes memory data) public pure returns(string memory) {
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