//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ERC20.sol";
import "./weth.sol";

contract GnosisSafeReceiverProxy is Ownable {
    address safe;
    IWETH WETH;

    constructor(address _safe, address _weth) Ownable() {
        safe = _safe;
        WETH = IWETH(_weth);

        // transfer ownership form deployer to DAO
        transferOwnership(_safe);
    }

    // Wrap all ETH and forward WETH to DAO
    function forward() public {
        (bool sent, bytes memory _data) = payable(address(WETH)).call{
            value: address(this).balance
        }("");

        require(sent, "Failed to wrap ETH");

        WETH.transfer(safe, WETH.balanceOf(address(this)));
    }

    // Withdraw arbitray ERC20 tokens to Safe
    function withdraw(address token) public {
        IERC20(token).transfer(safe, IERC20(token).balanceOf(address(this)));
    }

    // receive payments in ETH
    fallback() external payable {}

    // update safe
    function updateSafe(address _safe) external onlyOwner {
        safe = _safe;
    }

    // get safe address
    function getSafe() external view returns (address) {
        return safe;
    }
}
