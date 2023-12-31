// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeMath.sol";
import "./Voucher.sol";
import "./ReentrancyGuard.sol";

contract AUSD is Voucher, ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => bool) private _allowedToken;
    mapping(address => bool) private _whiteList;
    address private _owner;

    modifier onlyWhiteList() {
        require(_whiteList[_msgSender()], "Only whitelist");
        _;
    }

    modifier onlyAllowToken(address token) {
        require(_allowedToken[token], "Only allowed tokens");
        _;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Only owner");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address factory_,
        address usdc,
        address usdt,
        address dai
    ) Voucher(name_, symbol_, factory_) {
        _allowedToken[usdc] = true;
        _allowedToken[usdt] = true;
        _allowedToken[dai] = true;

        _whiteList[_msgSender()] = true;
        _owner = _msgSender();
    }

    function isWhiteList(address _account) public view returns (bool) {
        return _whiteList[_account];
    }

    function isTokenAllowed(address _token) public view returns (bool) {
        return _allowedToken[_token];
    }

    function addWhiteList(address _account) external onlyOwner {
        _whiteList[_account] = true;
    }

    function removeWhiteList(address _account) external onlyOwner {
        _whiteList[_account] = false;
    }

    function mortgageMint(
        address _token,
        uint256 _tokenAmount
    ) external nonReentrant onlyWhiteList onlyAllowToken(_token) {
        IERC20(_token).transferFrom(_msgSender(), address(this), _tokenAmount);
        _mint(
            _msgSender(),
            _tokenAmount.mul(10 ** 18).div(
                10 ** IERC20Metadata(_token).decimals()
            )
        );
    }

    function redeem(
        address _token,
        uint256 _tokenAmount
    ) external nonReentrant onlyWhiteList onlyAllowToken(_token) {
        IERC20(_token).transfer(_msgSender(), _tokenAmount);
        _burn(
            _msgSender(),
            _tokenAmount.mul(10 ** 18).div(
                10 ** IERC20Metadata(_token).decimals()
            )
        );
    }
}
