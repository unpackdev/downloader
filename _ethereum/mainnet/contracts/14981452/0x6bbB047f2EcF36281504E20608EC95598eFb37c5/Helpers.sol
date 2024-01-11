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
}