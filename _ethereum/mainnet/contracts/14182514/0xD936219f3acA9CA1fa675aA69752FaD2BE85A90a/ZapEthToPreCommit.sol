// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.6;

import "IERC20.sol";
import "IWETH.sol";
import "IPreCommit.sol";
import "Ownable.sol";

contract ZapEthToPreCommit is Ownable {
    IWETH public immutable weth;
    IPreCommit public immutable preCommit;

    constructor(address _weth, address _preCommit) {
        require(_weth != address(0), "weth = zero address");
        require(_preCommit != address(0), "pre commit = zero address");

        weth = IWETH(_weth);
        preCommit = IPreCommit(_preCommit);

        IERC20(_weth).approve(_preCommit, type(uint).max);
    }

    function zap() external payable {
        require(msg.value > 0, "value = 0");
        weth.deposit{value: msg.value}();
        preCommit.commit(msg.sender, msg.value);
    }

    function recover(address _token) external onlyOwner {
        if (_token != address(0)) {
            IERC20(_token).transfer(
                msg.sender,
                IERC20(_token).balanceOf(address(this))
            );
        } else {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
}
