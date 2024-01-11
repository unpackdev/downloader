// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAuthCenter.sol";
import "./FundsBasic.sol";

// import "./console.sol";

contract Account is FundsBasic {
    IAuthCenter public authCenter;
    bool flag;

    function init(IAuthCenter _authCenter) external {
        require(!flag, "BYDEFI: already initialized!");
        authCenter = _authCenter;
        flag = true;
    }

    function pull(
        address _token,
        uint256 _amt,
        address _to
    ) external override returns (uint256 amt) {
        authCenter.ensureAccountAccess(msg.sender);
        amt = _pull(_token, _amt, _to);
    }

    function useless() public pure returns (uint256 a, string memory s) {
        a = 100;
        s = "hello world!";
    }
}
