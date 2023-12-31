// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./OFT.sol";

import "./IMintable.sol";

contract FXDX is OFT, IMintable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_USER_MINT_AMOUNT = 10 ** 27; // 1B

    bool public immutable userMintable;
    uint256 public userMintAmount;
    mapping (address => bool) public isMinter;

    modifier onlyMinter() {
        require(isMinter[msg.sender], "FXDX: forbidden");
        _;
    }

    constructor(bool _userMintable, address _lzEndpoint) OFT("FXDX", "FXDX", _lzEndpoint) {
        userMintable = _userMintable;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function setMinter(address _minter, bool _isActive) external onlyOwner {
        isMinter[_minter] = _isActive;
    }

    function mint(address _account, uint256 _amount) external onlyMinter {
        require(userMintable, "FXDX: mint is not allowed");
        require(userMintAmount + _amount <= MAX_USER_MINT_AMOUNT, "FXDX: max user mint amount exceeds");

        userMintAmount += _amount;
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external onlyMinter {
        require(userMintable, "FXDX: burn is not allowed");
        require(userMintAmount >= _amount, "FXDX: burn amount exceeds userMintAmount");

        userMintAmount -= _amount;
        _burn(_account, _amount);
    }
}
