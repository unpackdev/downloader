// contracts/MXNTTest.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";

contract Pausable is OwnableUpgradeable {
    event Pause();
    event Unpause();
    bool public paused;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract BlackList is Pausable {
    mapping(address => bool) isBlacklisted;
    address constant REDEMPTION_ADDRESS_COUNT = address(16**5);

    /**
     * @dev Emitted when account blacklist status changes
     */
    event Blacklisted(address indexed account, bool isBlacklisted);

    /**
     * @dev Set blacklisted status for the account.
     * @param _account address to set blacklist flag for
     * @param _isBlacklisted blacklist flag value
     *
     * Requirements:
     *
     * - `msg.sender` should be owner.
     */
    function setBlacklisted(address _account, bool _isBlacklisted)
        external
        onlyOwner
    {
        require(
            _account >= REDEMPTION_ADDRESS_COUNT,
            "MexicanCurrency: blacklisting of redemption address is not allowed"
        );
        isBlacklisted[_account] = _isBlacklisted;
        emit Blacklisted(_account, _isBlacklisted);
    }

    function getBlacklistedStatus(address _maker) external view returns (bool) {
        return isBlacklisted[_maker];
    }
}

contract MXNT is Initializable, ERC20Upgradeable, BlackList {
    uint8 constant DECIMALS = 6;
    uint256 constant CENT = 10**6;
    struct Params {
        uint256 basisPointsRate;
        uint256 maximumFee;
    }
    Params public params;

    using SafeMathUpgradeable for uint256;

    /**
     * @dev Emitted when `value` tokens are minted for `to`
     * @param _to address to mint tokens for
     * @param _value amount of tokens to be minted
     */
    event Mint(address indexed _to, uint256 _value);

    /**
     * @dev Emitted when `value` tokens are transfer for `to`
     * @param _to address to mint tokens for
     * @param _value amount of tokens to be minted
     */
    event SendFee(address indexed _to, uint256 _value);

    modifier executeTransaction(
        address _from,
        address _to,
        uint256 _amount
    ) {
        // require(
        //     balanceOf(_from) >= _amount,
        //     "MexicanCurrency: Not enough funds"
        // );

        // require(
        //     !isBlacklisted[_to],
        //     "MexicanCurrency: recipient is blacklisted"
        // );

        // uint256 fee = (_amount.mul(params.basisPointsRate)).div(10000);
        // if (fee > params.maximumFee) fee = params.maximumFee;

        // _amount = _amount.sub(fee);

        // if (fee > 0 && _from != this.owner()) {
        //     _transfer(_from, this.owner(), fee);
        //     emit SendFee(this.owner(), fee);
        // }

        // if (isRedemptionAddress(_to)) {
        //     _transfer(_from, _to, _amount.sub(_amount.mod(CENT)));
        //     _burn(_to, _amount.sub(_amount.mod(CENT)));
        // } else {
        //     _transfer(_from, _to, _amount);
        // }

        require(
            !isBlacklisted[_to],
            "MexicanCurrency: recipient is blacklisted"
        );

        uint256 fee = (_amount.mul(params.basisPointsRate)).div(10000);
        if (fee > params.maximumFee) fee = params.maximumFee;

        require(
            balanceOf(_from) >= _amount + fee,
            "MexicanCurrency: Not enough funds"
        );

        // _amount = _amount.sub(fee);

        if (fee > 0 && _from != owner()) {
            _transfer(_from, owner(), fee);
            emit SendFee(owner(), fee);
        }

        if (isRedemptionAddress(_to)) {
            _transfer(_from, _to, _amount.sub(_amount.mod(CENT)));
            _burn(_to, _amount.sub(_amount.mod(CENT)));
        } else {
            _transfer(_from, _to, _amount);
        }

        _;
    }

    function initialize(uint256 _initialSupply) public initializer {
        __ERC20_init_unchained("Axolotl MXN", "MXNT");
        __Ownable_init_unchained();
        _mint(_msgSender(), _initialSupply);
        paused = false;
    }

    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }

    function mint(address _account, uint256 _amount) external onlyOwner {
        require(
            !isBlacklisted[_account],
            "MexicanCurrency: account is blacklisted"
        );
        require(
            !isRedemptionAddress(_account),
            "MexicanCurrency: account is a redemption address"
        );
        _mint(_account, _amount);
        emit Mint(_account, _amount);
    }

    function setParams(Params memory _params) public onlyOwner {
        require(_params.basisPointsRate <= 20);
        require(_params.maximumFee < 50);

        params = _params;
        params.maximumFee = params.maximumFee.mul(10**DECIMALS);
    }

    function transfer(address _to, uint256 _amount)
        public
        virtual
        override
        whenNotPaused
        executeTransaction(_msgSender(), _to, _amount)
        returns (bool)
    {
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
        public
        virtual
        override
        whenNotPaused
        executeTransaction(_from, _to, _amount)
        returns (bool)
    {
        uint256 currentAllowance = allowance(_from, _msgSender());
        require(
            currentAllowance >= _amount,
            "MexicanCurrency: transfer amount exceeds allowance"
        );

        _approve(_from, _msgSender(), currentAllowance.sub(_amount));

        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function isRedemptionAddress(address account) internal pure returns (bool) {
        return account < REDEMPTION_ADDRESS_COUNT && account != address(0);
    }
}
