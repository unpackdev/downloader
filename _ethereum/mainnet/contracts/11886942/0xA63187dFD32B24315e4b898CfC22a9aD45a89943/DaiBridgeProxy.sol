// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Context.sol";

interface IERC20Permit {
    function permit(address holder, address spender, uint256 nonce, uint256 expiry,
        bool allowed, uint8 v, bytes32 r, bytes32 s) external;
}

interface IDaiBridge {
    function relayTokens(address _from, address _receiver, uint256 _amount) external;
}

contract DaiBridgeProxy is Context {
    address private _daiToken;
    address private _daiBridge;

    constructor(address daiToken_, address daiBridge_) public {
        _daiToken = daiToken_;
        _daiBridge = daiBridge_;
    }

    function daiToken() public view returns (address) {
        return _daiToken;
    }

    function daiBridge() public view returns (address) {
        return _daiBridge;
    }

    function depositFor(
        uint amount,
        address recipient,
        uint256 permitNonce,
        uint256 permitExpiry,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        IERC20Permit(_daiToken).permit(_msgSender(), _daiBridge, permitNonce, permitExpiry, true, v, r, s);
        IDaiBridge(_daiBridge).relayTokens(_msgSender(), recipient, amount);
    }
}
