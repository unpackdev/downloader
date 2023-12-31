pragma solidity 0.6.5;

import "./ERC20Extended.sol";
import "./SuperOperators.sol";


contract ERC20BaseToken is SuperOperators, ERC20, ERC20Extended {
    bytes32 internal immutable _name; // work only for string that can fit into 32 bytes
    bytes32 internal immutable _symbol; // work only for string that can fit into 32 bytes

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        address admin
    ) internal {
        require(bytes(tokenName).length > 0, "INVALID_NAME_REQUIRED");
        require(bytes(tokenName).length <= 32, "INVALID_NAME_TOO_LONG");
        _name = _firstBytes32(bytes(tokenName));
        require(bytes(tokenSymbol).length > 0, "INVALID_SYMBOL_REQUIRED");
        require(bytes(tokenSymbol).length <= 32, "INVALID_SYMBOL_TOO_LONG");
        _symbol = _firstBytes32(bytes(tokenSymbol));

        _admin = admin;
    }

    /// @notice A descriptive name for the tokens
    /// @return name of the tokens
    function name() external view returns (string memory) {
        return string(abi.encodePacked(_name));
    }

    /// @notice An abbreviated name for the tokens
    /// @return symbol of the tokens
    function symbol() external view returns (string memory) {
        return string(abi.encodePacked(_symbol));
    }

    /// @notice Gets the total number of tokens in existence.
    /// @return the total number of tokens in existence.
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Gets the balance of `owner`.
    /// @param owner The address to query the balance of.
    /// @return The amount owned by `owner`.
    function balanceOf(address owner) external override view returns (uint256) {
        return _balances[owner];
    }

    /// @notice gets allowance of `spender` for `owner`'s tokens.
    /// @param owner address whose token is allowed.
    /// @param spender address allowed to transfer.
    /// @return remaining the amount of token `spender` is allowed to transfer on behalf of `owner`.
    function allowance(address owner, address spender) external override view returns (uint256 remaining) {
        return _allowances[owner][spender];
    }

    /// @notice returns the number of decimals for that token.
    /// @return the number of decimals.
    function decimals() external virtual pure returns (uint8) {
        return uint8(18);
    }

    /// @notice Transfer `amount` tokens to `to`.
    /// @param to the recipient address of the tokens transfered.
    /// @param amount the number of tokens transfered.
    /// @return success true if success.
    function transfer(address to, uint256 amount) external override returns (bool success) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfer `amount` tokens from `from` to `to`.
    /// @param from whose token it is transferring from.
    /// @param to the recipient address of the tokens transfered.
    /// @param amount the number of tokens transfered.
    /// @return success true if success.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool success) {
        if (msg.sender != from && !_superOperators[msg.sender]) {
            uint256 currentAllowance = _allowances[from][msg.sender];
            if (currentAllowance != ~uint256(0)) {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                require(currentAllowance >= amount, "NOT_AUTHOIZED_ALLOWANCE");
                _allowances[from][msg.sender] = currentAllowance - amount;
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    /// @notice burn `amount` tokens.
    /// @param amount the number of tokens to burn.
    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    /// @notice burn `amount` tokens from `owner`.
    /// @param from address whose token is to burn.
    /// @param amount the number of token to burn.
    function burnFor(address from, uint256 amount) external override {
        if (msg.sender != from && !_superOperators[msg.sender]) {
            uint256 currentAllowance = _allowances[from][msg.sender];
            if (currentAllowance != ~uint256(0)) {
                require(currentAllowance >= amount, "NOT_AUTHOIZED_ALLOWANCE");
                _allowances[from][msg.sender] = currentAllowance - amount;
            }
        }
        _burn(from, amount);
    }

    /// @notice approve `spender` to transfer `amount` tokens.
    /// @param spender address to be given rights to transfer.
    /// @param amount the number of tokens allowed.
    /// @return success true if success.
    function approve(address spender, uint256 amount) external override returns (bool success) {
        _approveFor(msg.sender, spender, amount);
        return true;
    }

    /// @notice approve `spender` to transfer `amount` tokens from `owner`.
    /// @param owner address whose token is allowed.
    /// @param spender  address to be given rights to transfer.
    /// @param amount the number of tokens allowed.
    /// @return success true if success.
    function approveFor(
        address owner,
        address spender,
        uint256 amount
    ) public returns (bool success) {
        require(msg.sender == owner || _superOperators[msg.sender], "NOT_AUTHORIZED"); // TODO metatx
        _approveFor(owner, spender, amount);
        return true;
    }

    function addAllowanceIfNeeded(
        address owner,
        address spender,
        uint256 amountNeeded
    ) public returns (bool success) {
        require(msg.sender == owner || _superOperators[msg.sender], "msg.sender != owner && !superOperator");
        _addAllowanceIfNeeded(owner, spender, amountNeeded);
        return true;
    }

    function _addAllowanceIfNeeded(
        address owner,
        address spender,
        uint256 amountNeeded
    ) internal {
        if (amountNeeded > 0 && !isSuperOperator(spender)) {
            uint256 currentAllowance = _allowances[owner][spender];
            if (currentAllowance < amountNeeded) {
                _approveFor(owner, spender, amountNeeded);
            }
        }
    }

    function _approveFor(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0) && spender != address(0), "Cannot approve with 0x0");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(to != address(0), "Cannot send to 0x0");
        uint256 currentBalance = _balances[from];
        require(currentBalance >= amount, "not enough fund");
        _balances[from] = currentBalance - amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Cannot mint to 0x0");
        require(amount > 0, "cannot mint 0 tokens");
        uint256 currentTotalSupply = _totalSupply;
        uint256 newTotalSupply = currentTotalSupply + amount;
        require(newTotalSupply > currentTotalSupply, "overflow");
        _totalSupply = newTotalSupply;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(amount > 0, "cannot burn 0 tokens");
        if (msg.sender != from && !_superOperators[msg.sender]) {
            uint256 currentAllowance = _allowances[from][msg.sender];
            require(currentAllowance >= amount, "Not enough funds allowed");
            if (currentAllowance != ~uint256(0)) {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                _allowances[from][msg.sender] = currentAllowance - amount;
            }
        }

        uint256 currentBalance = _balances[from];
        require(currentBalance >= amount, "Not enough funds");
        _balances[from] = currentBalance - amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function _firstBytes32(bytes memory src) public pure returns (bytes32 output) {
        assembly {
            output := mload(add(src, 32))
        }
    }
}
