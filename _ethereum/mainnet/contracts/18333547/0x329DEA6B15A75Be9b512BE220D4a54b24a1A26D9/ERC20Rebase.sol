//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ECRecover.sol";
import "./OkStorage.sol";

contract ERC20Rebase is OkStorage {
    uint256 internal constant PRECISION = 1e18;

    constructor() {}

    // ERC20 function

    function __ERC20_init() internal initializer {}

    function name() external pure returns (string memory) {
        return "Beacon ETH 2.0";
    }

    function symbol() external pure returns (string memory) {
        return "BETH";
    }

    function decimals() external view returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        uint256 a = totalShare() * exchangeRate();
        uint256 b = PRECISION;
        return a / b;
    }

    function balanceOf(address _account) public view returns (uint256) {
        uint256 a = _getShare()[_account] * exchangeRate();
        uint256 b = PRECISION;
        return a / b;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _getAllowance()[_owner][_spender];
    }

    function transfer(address _recipient, uint256 _amount)
        public
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_recipient)
        returns (bool)
    {
        return _transfer(msg.sender, _recipient, _amount);
    }

    function approve(address _spender, uint256 _amount)
        public
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_spender)
        returns (bool)
    {
        return _approve(msg.sender, _spender, _amount);
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount)
        public
        whenNotPaused
        notBlacklisted(_sender)
        notBlacklisted(_recipient)
        returns (bool)
    {
        require(_getAllowance()[_sender][msg.sender] >= _amount, "ERC20: transfer amount exceeds allowance");
        _getAllowance()[_sender][msg.sender] -= _amount;
        return _transfer(_sender, _recipient, _amount);
    }

    //https://eips.ethereum.org/EIPS/eip-2612
    function permit(address from, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        whenNotPaused
        notBlacklisted(from)
        notBlacklisted(spender)
    {
        require(deadline >= block.timestamp, "ERC20: permit is expired");
        require(from != address(0), "ERC20: permit from the zero address");

        bytes memory data = abi.encode(PERMIT_TYPEHASH, from, spender, value, _getNonce()[from], deadline);
        _getNonce()[from] += 1;
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), keccak256(data)));
        require(ECRecover.recover(digest, v, r, s) == from, "EIP2612: invalid signature");
        _approve(from, spender, value);
    }

    function increaseAllowance(address spender, uint256 increment)
        external
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {
        return _approve(msg.sender, spender, _getAllowance()[msg.sender][spender] + increment);
    }

    function decreaseAllowance(address spender, uint256 decrement)
        external
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {
        require(_getAllowance()[msg.sender][spender] >= decrement, "ERC20: decreased allowance below zero");
        return _approve(msg.sender, spender, _getAllowance()[msg.sender][spender] - decrement);
    }

    function sharesOf(address _account) external view returns (uint256) {
        return _getShare()[_account];
    }

    function getTotalShares() public view returns (uint256) {
        return totalShare();
    }

    function getSharesByPooledEth(uint256 _ethAmount) public view returns (uint256) {
        uint256 exR = exchangeRate();
        if (exR == 0) return 0;
        return _ethAmount * PRECISION / exR;
    }

    function getPooledEthByShares(uint256 _shareAmount) public view returns (uint256) {
        if (totalShare() == 0) return 0;
        return _shareAmount * exchangeRate() / PRECISION;
    }

    function transferShares(address _recipient, uint256 _sharesAmount)
        public
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_recipient)
        returns (uint256)
    {
        _transferShares(msg.sender, _recipient, _sharesAmount);
        uint256 tokensAmount = getPooledEthByShares(_sharesAmount);
        emit Transfer(msg.sender, _recipient, tokensAmount);
        return tokensAmount;
    }

    function transferSharesFrom(address _sender, address _recipient, uint256 _sharesAmount)
        public
        whenNotPaused
        notBlacklisted(_sender)
        notBlacklisted(_recipient)
        returns (uint256)
    {
        uint256 tokensAmount = getPooledEthByShares(_sharesAmount);
        require(_getAllowance()[_sender][msg.sender] >= tokensAmount, "ERC20: transfer amount exceeds allowance");
        _getAllowance()[_sender][msg.sender] -= tokensAmount;
        _transferShares(_sender, _recipient, _sharesAmount);
        emit Transfer(_sender, _recipient, tokensAmount);
        return tokensAmount;
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal returns (bool) {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _getAllowance()[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
        return true;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) internal returns (bool) {
        uint256 exR = exchangeRate();
        uint256 share = _amount * PRECISION / exR;

        _transferShares(_sender, _recipient, share);

        emit Transfer(_sender, _recipient, _amount);
        return true;
    }

    function _transferShares(address _sender, address _recipient, uint256 _sharesAmount) internal returns (bool) {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");

        require(_getShare()[_sender] >= _sharesAmount, "ERC20: transfer amount exceeds balance");
        _getShare()[_sender] -= _sharesAmount;
        _getShare()[_recipient] += _sharesAmount;
        emit TransferShares(_sender, _recipient, _sharesAmount);
        return true;
    }

    function _mint(address _account, uint256 _amount) internal returns (bool) {
        require(_account != address(0), "ERC20: mint to the zero address");

        uint256 exR = exchangeRate();
        uint256 share = _amount * PRECISION / exR;

        _getShare()[_account] += share;
        _setTotalShare(totalShare() + share);

        emit Transfer(address(0), _account, _amount);
        emit Mint(msg.sender, _account, _amount, exR);
        return true;
    }

    function _burn(address _account, uint256 _amount) internal returns (bool) {
        require(_account != address(0), "ERC20: burn from the zero address");

        uint256 exR = exchangeRate();
        uint256 share = _amount * PRECISION / exR;

        require(_getShare()[_account] >= share, "ERC20: burn amount exceeds balance");
        _getShare()[_account] -= share;
        _setTotalShare(totalShare() - share);

        emit Transfer(_account, address(0), _amount);
        emit Burn(msg.sender, _account, _amount, exR);
        return true;
    }
}
