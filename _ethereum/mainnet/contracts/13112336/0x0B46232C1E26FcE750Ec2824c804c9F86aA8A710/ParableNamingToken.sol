pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ICards.sol";
import "./Context.sol";

/**
 *
 * ParableNamingToken Contract (The native token of Parable NFT)
 * @dev Extends standard ERC20 contract
 */
contract ParableNamingToken is Context, IERC20 {
    using SafeMath for uint256;

    // Constants
    uint256 public SECONDS_IN_A_DAY = 86400;

    uint256 public constant INITIAL_ALLOTMENT = 915 * (10 ** 18);

    uint256 public constant PRE_REVEAL_MULTIPLIER = 3;

    // Public variables
    uint256 public emissionStart;

    uint256 public emissionEnd;

    uint256 public emissionPerDay = 10 * (10 ** 18);

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping(uint256 => uint256) private _lastClaim;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _cardsAddress;

    // RIDDLES ============================
    bytes32 public answer1 = 0xf66787a57e534b366e3676c512fbb495160c2c4f0901093402a06522149b7307;
    bytes32 public answer2 = 0x065fc08578d53af81e342fe54199044aef5e2ae50f6115748ff823ff04bcc47a;
    bytes32 public answer3 = 0xe54964fe8be20bd4c2ba9a98215a27c34ad530485cbe9828304f321ef82c5c76;
    bytes32 public answer4 = 0xf858a6e04d2da8f9c64116c14f824674d08ec5b13f08893c0895ebe9e3e54dd1;
    bytes32 public answer5 = 0xb67784e6189fcd60a377261f124944fb06144e7f517c9b783bc5adcb3e8eda87;
    bytes32 public answer6 = 0x1407973d4f60ff9a5ed7d6489e48d244b248ce24feee9acbd034ba0e255367e8;
    bytes32 public answer7 = 0xcdfcc99b58fd8a9ca04a677ce8e60a3327ab8334ca53ccbeb12600f444ab9c74;
    uint256 public riddleStart; // timestamp when solutions to riddles can be submitted
    uint256 public riddle1_solved = 0;
    uint256 public riddle2_solved = 0;
    uint256 public riddle3_solved = 0;
    uint256 public riddle4_solved = 0;
    uint256 public riddle5_solved = 0;
    uint256 public riddle6_solved = 0;
    uint256 public riddle7_solved = 0;
    mapping(uint256 => bool) private _riddle1Claimed; // bool defaults to false
    mapping(uint256 => bool) private _riddle2Claimed;
    mapping(uint256 => bool) private _riddle3Claimed;
    mapping(uint256 => bool) private _riddle4Claimed;
    mapping(uint256 => bool) private _riddle5Claimed;
    mapping(uint256 => bool) private _riddle6Claimed;
    mapping(uint256 => bool) private _riddle7Claimed;
    uint256 public constant riddle_1_reward = 365 * (10 ** 18);
    uint256 public constant riddle_2_reward = 460 * (10 ** 18);
    uint256 public constant riddle_3_reward = 550 * (10 ** 18);
    uint256 public constant riddle_4_reward = 640 * (10 ** 18);
    uint256 public constant riddle_5_reward = 730 * (10 ** 18);
    uint256 public constant riddle_6_reward = 915 * (10 ** 18);
    uint256 public constant riddle_7_reward = 1830 * (10 ** 18);
    // =========================================
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18. Also initalizes {emissionStart}
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint256 emissionStartTimestamp, uint256 riddleStartTimestamp) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
        emissionStart = emissionStartTimestamp;
        emissionEnd = emissionStartTimestamp + (86400 * 365 * 10);
        riddleStart = riddleStartTimestamp;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev When accumulated PNTs have last been claimed for a Parable index
     */
    function lastClaim(uint256 tokenIndex) public view returns (uint256) {
        require(ICards(_cardsAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex <= ICards(_cardsAddress).totalSupply(), "NFT at index has not been minted yet");

        uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0 ? uint256(_lastClaim[tokenIndex]) : emissionStart;
        return lastClaimed;
    }

    /**
     * @dev Accumulated PNT tokens for a Parable token index.
     */
    function accumulated(uint256 tokenIndex) public view returns (uint256) {
        require(block.timestamp > emissionStart, "Emission has not started yet");
        require(ICards(_cardsAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex <= ICards(_cardsAddress).totalSupply(), "NFT at index has not been minted yet");

        uint256 lastClaimed = lastClaim(tokenIndex);

        // Sanity check if last claim was on or after emission end
        if (lastClaimed >= emissionEnd) return 0;

        uint256 accumulationPeriod = block.timestamp < emissionEnd ? block.timestamp : emissionEnd; // Getting the min value of both
        uint256 totalAccumulated = accumulationPeriod.sub(lastClaimed).mul(emissionPerDay).div(SECONDS_IN_A_DAY);

        // If claim hasn't been done before for the index, add initial allotment (plus prereveal multiplier if applicable)
        if (lastClaimed == emissionStart) {
            uint256 initialAllotment = ICards(_cardsAddress).isMintedBeforeReveal(tokenIndex) == true ? INITIAL_ALLOTMENT.mul(PRE_REVEAL_MULTIPLIER) : INITIAL_ALLOTMENT;
            totalAccumulated = totalAccumulated.add(initialAllotment);
        }

        // RIDDLE REWARDS
        if (riddle1_solved > ICards(_cardsAddress).mintedTimestamp(tokenIndex) && !(_riddle1Claimed[tokenIndex])) {
            totalAccumulated = totalAccumulated.add(riddle_1_reward);
        }
        if (riddle2_solved > ICards(_cardsAddress).mintedTimestamp(tokenIndex) && !(_riddle2Claimed[tokenIndex])) {
            totalAccumulated = totalAccumulated.add(riddle_2_reward);
        }
        if (riddle3_solved > ICards(_cardsAddress).mintedTimestamp(tokenIndex) && !(_riddle3Claimed[tokenIndex])) {
            totalAccumulated = totalAccumulated.add(riddle_3_reward);
        }
        if (riddle4_solved > ICards(_cardsAddress).mintedTimestamp(tokenIndex) && !(_riddle4Claimed[tokenIndex])) {
            totalAccumulated = totalAccumulated.add(riddle_4_reward);
        }
        if (riddle5_solved > ICards(_cardsAddress).mintedTimestamp(tokenIndex) && !(_riddle5Claimed[tokenIndex])) {
            totalAccumulated = totalAccumulated.add(riddle_5_reward);
        }
        if (riddle6_solved > ICards(_cardsAddress).mintedTimestamp(tokenIndex) && !(_riddle6Claimed[tokenIndex])) {
            totalAccumulated = totalAccumulated.add(riddle_6_reward);
        }
        if (riddle7_solved > ICards(_cardsAddress).mintedTimestamp(tokenIndex) && !(_riddle7Claimed[tokenIndex])) {
              totalAccumulated = totalAccumulated.add(riddle_7_reward);
        }

        return totalAccumulated;
    }

    /**
     * @dev Permissioning not added because it is only callable once. It is set right after deployment and verified.
     */

    function setCardsAddress(address cardsAddress) public {
        require(_cardsAddress == address(0), "Already set");

        _cardsAddress = cardsAddress;
    }



    // RIDDLES =================================================

    // check if it's more efficient to store the hash in a var instead of hasing 7 times
    function guess(string memory _word) public  {
        require(block.timestamp > riddleStart, "Riddles have not started yet");
        bytes32 submitted_guess = keccak256(abi.encodePacked(_word));
        require(submitted_guess == answer1 || submitted_guess == answer2 || submitted_guess == answer3 || submitted_guess == answer4 || submitted_guess == answer5 || submitted_guess == answer6 || submitted_guess == answer7, "Wrong guess");

        if (submitted_guess == answer1) {
            require(riddle1_solved == 0, "already solved");
            riddle1_solved = block.timestamp;
        } else if (submitted_guess == answer2) {
            require(riddle2_solved == 0, "already solved");
            riddle2_solved = block.timestamp;
        } else if (submitted_guess == answer3) {
            require(riddle3_solved == 0, "already solved");
            riddle3_solved = block.timestamp;
        } else if (submitted_guess == answer4) {
            require(riddle4_solved == 0, "already solved");
            riddle4_solved = block.timestamp;
        } else if (submitted_guess == answer5) {
            require(riddle5_solved == 0, "already solved");
            riddle5_solved = block.timestamp;
        } else if (submitted_guess == answer6) {
            require(riddle6_solved == 0, "already solved");
            riddle6_solved = block.timestamp;
        } else if (submitted_guess == answer7) {
            require(riddle7_solved == 0, "already solved");
            riddle7_solved = block.timestamp;
        }
    }

    // ======================================




    /**
     * @dev Claim mints PNTs and supports multiple Parable token indices at once.
     */
    function claim(uint256[] memory tokenIndices) public returns (uint256) {
        require(block.timestamp > emissionStart, "Emission has not started yet");

        uint256 totalClaimQty = 0;
        for (uint i = 0; i < tokenIndices.length; i++) {
            // Sanity check for non-minted index
            require(tokenIndices[i] <= ICards(_cardsAddress).totalSupply(), "NFT at index has not been minted yet");
            // Duplicate token index check
            for (uint j = i + 1; j < tokenIndices.length; j++) {
                require(tokenIndices[i] != tokenIndices[j], "Duplicate token index");
            }

            uint tokenIndex = tokenIndices[i];
            require(ICards(_cardsAddress).ownerOf(tokenIndex) == msg.sender, "Sender is not the owner");

            uint256 claimQty = accumulated(tokenIndex);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty.add(claimQty);
                _lastClaim[tokenIndex] = block.timestamp;
            }

            if (riddle1_solved > ICards(_cardsAddress).mintedTimestamp(tokenIndex) && !(_riddle1Claimed[tokenIndex])) {
                _riddle1Claimed[tokenIndex] = true;
            }
             if (riddle2_solved > ICards(_cardsAddress).mintedTimestamp(tokenIndex) && !(_riddle2Claimed[tokenIndex])) {
                _riddle2Claimed[tokenIndex] = true;
            }
             if (riddle3_solved > ICards(_cardsAddress).mintedTimestamp(tokenIndex) && !(_riddle3Claimed[tokenIndex])) {
                _riddle3Claimed[tokenIndex] = true;
            }
             if (riddle4_solved > ICards(_cardsAddress).mintedTimestamp(tokenIndex) && !(_riddle4Claimed[tokenIndex])) {
                _riddle4Claimed[tokenIndex] = true;
            }
             if (riddle5_solved > ICards(_cardsAddress).mintedTimestamp(tokenIndex) && !(_riddle5Claimed[tokenIndex])) {
                _riddle5Claimed[tokenIndex] = true;
            }
             if (riddle6_solved > ICards(_cardsAddress).mintedTimestamp(tokenIndex) && !(_riddle6Claimed[tokenIndex])) {
                _riddle6Claimed[tokenIndex] = true;
            }
             if (riddle7_solved > ICards(_cardsAddress).mintedTimestamp(tokenIndex) && !(_riddle7Claimed[tokenIndex])) {
                _riddle7Claimed[tokenIndex] = true;
            }


        }

        require(totalClaimQty != 0, "No accumulated PNT");
        _mint(msg.sender, totalClaimQty);
        return totalClaimQty;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        // Approval check is skipped if the caller of transferFrom is the Card contract. For better UX.
        if (msg.sender != _cardsAddress) {
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    // ++
    /**
     * @dev Burns a quantity of tokens held by the caller.
     *
     * Emits an {Transfer} event to 0 address
     *
     */
    function burn(uint256 burnQuantity) public virtual override returns (bool) {
        _burn(msg.sender, burnQuantity);
        return true;
    }
    // ++

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
