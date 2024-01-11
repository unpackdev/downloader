// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Configure.sol";
import "./TransferHelper.sol";
import "./IAuthCenter.sol";
import "./FundsBasic.sol";

// import "./console.sol";

contract FundsProvider is Ownable, FundsBasic {
    using TransferHelper for address;

    event UpdateSupportToken(address token, bool status);
    event SetAuthCenter(address preAuthCenter, address authCenter);

    address public authCenter;
    mapping(address => bool) supportTokens;
    bool flag;

    function init(address _authCenter) external {
        require(!flag, "BYDEFI: already initialized!");
        super.initialize();
        authCenter = _authCenter;
        flag = true;
    }

    function pull(
        address _token,
        uint256 _amt,
        address _to
    ) external override returns (uint256 amt) {
        require(msg.sender != tx.origin, "BYDEFI: should be called by operator!");

        IAuthCenter(authCenter).ensureFundsProviderPullAccess(msg.sender);
        IAuthCenter(authCenter).ensureFundsProviderPullAccess(tx.origin);

        amt = _pull(_token, _amt, _to);
    }

    function rebalancePull(
        address _token,
        uint256 _amt,
        address _to
    ) external returns (uint256 amt) {
        IAuthCenter(authCenter).ensureFundsProviderRebalanceAccess(msg.sender);
        amt = _pull(_token, _amt, _to);
    }

    function updateSupportToken(address _token, bool _status) external onlyOwner {
        require(_token != Configure.ZERO_ADDRESS, "BYDEFI: Invalid Token Address!");
        supportTokens[_token] = _status;
        emit UpdateSupportToken(_token, _status);
    }

    function isSupported(address _token) external view returns (bool) {
        return supportTokens[_token];
    }

    function setAuthCenter(address _authCenter) external onlyOwner {
        address pre = authCenter;
        authCenter = _authCenter;
        emit SetAuthCenter(pre, _authCenter);
    }

    function useless() public pure returns (uint256 a, string memory s) {
        a = 100;
        s = "hello world!";
    }
}
