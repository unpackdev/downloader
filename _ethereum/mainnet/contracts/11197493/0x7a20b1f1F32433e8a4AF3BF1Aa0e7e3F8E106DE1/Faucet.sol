pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

// This is NOT SAFE for production use since the code is broadcast to the mempool
// this is only for testnet and convenience.
contract Faucet is Ownable {
    using SafeERC20 for IERC20;

    event LogCashIn(bytes32 code, address to);

    mapping(bytes32=>uint256) private _redeemableCodes;
    IERC20 private _token;

    constructor(address tokenAddr) Ownable() public {
        _token = IERC20(tokenAddr);
    }

    function addCode(bytes32 codeHash, uint256 amount) onlyOwner public {
        _redeemableCodes[codeHash] = amount;
    }

    function cashIn(string memory code, address to) public {
        bytes32 hsh = keccak256(abi.encodePacked(code));
        uint256 amount = _redeemableCodes[hsh];
        require(amount > 0, "Faucet:Unknown code");
        _redeemableCodes[hsh] = 0;
        _token.safeTransfer(to, amount);
        emit LogCashIn(hsh, to);
    }
}
