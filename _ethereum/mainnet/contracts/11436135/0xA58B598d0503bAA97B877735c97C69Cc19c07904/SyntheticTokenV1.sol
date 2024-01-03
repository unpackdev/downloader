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

    event InitCalled();

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
        string memory version
    )
        public
        onlyAdmin
    {
        _name = name;
        _symbol = symbol;
        _version = version;

        DOMAIN_SEPARATOR = initDomainSeparator(name, version);

        emit InitCalled();
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
        returns (string memory)
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
            "SyntheticToken: Minter already exists"
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
            "SyntheticToken: minter does not exist"
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
            "SyntheticToken: minter does not exist"
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
            "SyntheticToken: minter limit reached"
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

    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * assuming the latter's signed approval.
     *
     * IMPORTANT: The same issues Erc20 `approve` has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the Eip712-formatted function arguments.
     * - The signature must use `owner`'s current nonce.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8   v,
        bytes32 r,
        bytes32 s
    )
        public
    {

        require(
            deadline == 0 || deadline >= block.timestamp,
            "SyntheticToken: Permit expired"
        );

        require(
            spender != address(0),
            "SyntheticToken: spender cannot be 0x0"
        );

        require(
            value > 0,
            "SyntheticToken: approval value must be greater than 0"
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                    PERMIT_TYPEHASH,
                    owner,
                    spender,
                    value,
                    permitNonces[owner]++,
                    deadline
                )
            )
        ));

        address recoveredAddress = ecrecover(
            digest,
            v,
            r,
            s
        );

        require(
            recoveredAddress != address(0) && owner == recoveredAddress,
            "SyntheticToken: Signature invalid"
        );

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
            "SyntheticToken: transfer from the zero address"
        );

        require(
            recipient != address(0),
            "SyntheticToken: transfer to the zero address"
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
        require(
            account != address(0),
            "SyntheticToken: mint to the zero address"
        );

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
        require(
            account != address(0),
            "SyntheticToken: burn from the zero address"
        );

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
        require(
            owner != address(0),
            "SyntheticToken: approve from the zero address"
        );

        require(
            spender != address(0),
            "SyntheticToken: approve to the zero address"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /* ========== Private Functions ========== */

    /**
     * @dev Initializes EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function initDomainSeparator(
        string memory name,
        string memory version
    )
        private
        returns (bytes32)
    {
        uint256 chainID;
        /* solium-disable-next-line */
        assembly {
            chainID := chainid()
        }

        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainID,
                address(this)
            )
        );
    }
}
