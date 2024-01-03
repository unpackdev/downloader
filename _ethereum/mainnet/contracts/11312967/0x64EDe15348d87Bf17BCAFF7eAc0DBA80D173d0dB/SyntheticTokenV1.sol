// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

import "./SafeMath.sol";
import "./Amount.sol";

import "./SyntheticStorage.sol";

import "./Adminable.sol";

contract SyntheticTokenV1 is Adminable, SyntheticStorage, IERC20 {

    using SafeMath for uint256;
    using Amount for Amount.Principal;

    /* ========== Events ========== */

    event MinterAdded(address _minter, uint256 _limit);

    event MinterRemoved(address _minter);

    event MinterLimitUpdated(address _minter, uint256 _limit);

    event MetadataChanged();

    /* ========== Modifiers ========== */

    modifier onlyMinter() {
        require(
            _minters[msg.sender] == true,
            "SyntheticToken: only callable by minter"
        );
        _;
    }

    /* ========== Init Function ========== */

    /**
     * @dev Initialise the synthetic token
     *
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param version The version number of this token
     */
    function init(
        string memory name,
        string memory symbol,
        uint8 version
    )
        public
        onlyAdmin
    {
        _name = name;
        _symbol = symbol;
        _version = version;
    }

    /* ========== View Functions ========== */

    function name()
        external
        view
        returns (string memory)
    {
        return _name;
    }

    function symbol()
        external
        view
        returns (string memory)
    {
        return _symbol;
    }

    function decimals()
        external
        pure
        returns (uint8)
    {
        return 18;
    }

    function version()
        external
        view
        returns (uint8)
    {
        return _version;
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(
        address account
    )
        public
        view
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function getAllMinters()
        external
        view
        returns (address[] memory)
    {
        return _mintersArray;
    }

    function isValidMinter(
        address _minter
    )
        external
        view
        returns (bool)
    {
        return _minters[_minter];
    }

    function getMinterIssued(
        address _minter
    )
        external
        view
        returns (Amount.Principal memory)
    {
        return _minterIssued[_minter];
    }

    function getMinterLimit(
        address _minter
    )
        external
        view
        returns (uint256)
    {
        return _minterLimits[_minter];
    }

    /* ========== Admin Functions ========== */

    /**
     * @dev Add a new minter to the synthetic token.
     *
     * @param _minter The address of the minter to add
     * @param _limit The starting limit for how much this synth can mint
     */
    function addMinter(
        address _minter,
        uint256 _limit
    )
        external
        onlyAdmin
    {
        require(
            _minters[_minter] != true,
            "Minter already exists"
        );

        _mintersArray.push(_minter);
        _minters[_minter] = true;
        _minterLimits[_minter] = _limit;

        emit MinterAdded(_minter, _limit);
    }

    /**
     * @dev Remove a minter from the synthetic token
     *
     * @param _minter Address to remove the minter
     */
    function removeMinter(
        address _minter
    )
        external
        onlyAdmin
    {
        require(
            _minters[_minter] == true,
            "Minter does not exist"
        );

        for (uint i = 0; i < _mintersArray.length; i++) {
            if (address(_mintersArray[i]) == _minter) {
                delete _mintersArray[i];
                _mintersArray[i] = _mintersArray[_mintersArray.length - 1];
                _mintersArray.length--;

                break;
            }
        }

        delete _minters[_minter];
        delete _minterLimits[_minter];

        emit MinterRemoved(_minter);
    }

    /**
     * @dev Update the limit of the minter
     *
     * @param _minter The address of the minter to set
     * @param _limit The new limit to set for this address
     */
    function updateMinterLimit(
        address _minter,
        uint256 _limit
    )
        public
        onlyAdmin
    {
        require(
            _minters[_minter] == true,
            "Minter does not exist"
        );

        _minterLimits[_minter] = _limit;

        emit MinterLimitUpdated(_minter, _limit);
    }

    /* ========== Minter Functions ========== */

    /**
     * @dev Mint synthetic tokens
     *
     * @notice Can only be called by a valid minter.
     *
     * @param to The destination to mint the synth to
     * @param value The amount of synths to mint
     */
    function mint(
        address to,
        uint256 value
    )
        external
        onlyMinter
    {
        Amount.Principal memory issuedAmount = _minterIssued[msg.sender].add(
            Amount.Principal({ sign: true, value: value })
        );

        require(
            issuedAmount.value <= _minterLimits[msg.sender] || issuedAmount.sign == false,
            "Minter limit reached"
        );

        _minterIssued[msg.sender] = issuedAmount;
        _mint(to, value);
    }

    /**
     * @dev Burn synthetic tokens
     *
     * @notice Can only be called by a valid minter.
     *
     * @param from The destination to burn the synth from
     * @param value The amount of the synth to burn
     */
    function burn(
        address from,
        uint256 value
    )
        external
        onlyMinter
    {
        _minterIssued[msg.sender] = _minterIssued[msg.sender].sub(
            Amount.Principal({ sign: true, value: value })
        );

        _burn(from, value);
    }

    /**
     * @dev Transfer any collateral held to another address
     *
     * @param token The address of the token to transfer
     * @param to The destination to send the collateral to
     * @param value The amount of the tokens to transfer
     */
    function transferCollateral(
        address token,
        address to,
        uint256 value
    )
        external
        onlyMinter
        returns (bool)
    {
        return IERC20(token).transfer(
            to,
            value
        );
    }

    /* ========== ERC20 Functions ========== */

    function transfer(
        address recipient,
        uint256 amount
    )
        public
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    )
        public
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount)
        );

        return true;
    }

    /* ========== Internal Functions ========== */

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
    {
        require(
            sender != address(0),
            "ERC20: transfer from the zero address"
        );

        require(
            recipient != address(0),
            "ERC20: transfer to the zero address"
        );

        _balances[sender] = _balances[sender].sub(amount);

        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(
        address account,
        uint256 amount
    )
        internal
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(
        address account,
        uint256 amount
    )
        internal
    {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    )
        internal
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
