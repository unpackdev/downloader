// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract Distribution {
    using SafeERC20 for IERC20;
    event Distributed(address _who, uint256 _whomuch, uint256 _when);

    function distribute(address _token, address[] memory _to, uint256[] memory _tokens) external {
        address[] memory _who = _to;
        uint256[] memory _amounts = _tokens;
        require(_who.length == _amounts.length, "Distribute:: Length of recipients & amounts should be same");
        require(_who.length <= 25, "Distribute:: Allowed only 25 Transfers");
        uint256 _when = block.timestamp;
        uint256 _noOfTransfer = _who.length;
        for (uint8 i = 0; i < _noOfTransfer; i++) {
            require(_who[i] != address(0), "Distribute:: Can not transfer to Zero Address");
            require(_amounts[i] != 0, "Distribute:: Can not transfer Zero tokens");
            IERC20(_token).safeTransferFrom(msg.sender, _who[i], _amounts[i]);
            emit Distributed(_who[i], _amounts[i], _when);
        }
    }
}