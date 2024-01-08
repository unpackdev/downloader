// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.0;

import "./IUniswapV2Router02.sol";
import "./Initializable.sol";
import "./IERC20.sol";
import "./IStaking.sol";
import "./Migrateable.sol";
import "./Manageable.sol";

/** Launch
    Roles Needed -
    Staking Contract: External Staker Role (redo in v3)
    Token Contract: Burner (AKA Minter)
 */

contract Accelerator is Initializable, Migrateable, Manageable {
    event AcceleratorToken(
        address indexed from,
        address indexed tokenIn,
        uint256 indexed currentDay,
        address token,
        uint8[3] splitAmounts,
        uint256 axionBought,
        uint256 tokenBought,
        uint256 stakeDays,
        uint256 payout
    );
    event AcceleratorEth(
        address indexed from,
        address indexed token,
        uint256 indexed currentDay,
        uint8[3] splitAmounts,
        uint256 axionBought,
        uint256 tokenBought,
        uint256 stakeDays,
        uint256 payout
    );
    /** Additional Roles */
    bytes32 public constant GIVE_AWAY_ROLE = keccak256('GIVE_AWAY_ROLE');

    /** Public */
    address public staking; // Staking Address
    address public axion; // Axion Address
    address public vcauction; // Used in v3
    address public token; // Token to buy other then aixon
    address payable public uniswap; // Uniswap Adress
    address payable public recipient; // Recipient Address
    uint256 public minStakeDays; // Minimum length of stake from contract
    uint256 public start; // Start of Contract in seconds
    uint256 public secondsInDay; // 86400
    uint256 public maxBoughtPerDay; // Amount bought before bonus is removed
    mapping(uint256 => uint256) public bought; // Total bought for the day
    uint16 bonusStartDays; // # of days to stake before bonus starts
    uint8 bonusStartPercent; // Start percent of bonus 5 - 20, 10 - 25 etc.
    uint8 baseBonus; // Base bonus unrequired by baseStartDays
    uint8[3] public splitAmounts; // 0 axion, 1 btc, 2 recipient
    mapping(address => bool) public allowedTokens; // Tokens allowed to be used for stakeWithToken
    /** Private */
    bool private _paused; // Contract paused

    // -------------------- Modifiers ------------------------

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), 'AUTOSTAKER: paused');
        _;
    }

    // -------------------- Functions ------------------------

    /** @dev stake with token
        Description: Sell a token buy axion and then stake it for # of days
        @param _amountOut {uint256}
        @param _amountTokenOut {uint256}
        @param _deadline {uint256}
        @param _days {uint256}
     */
    function axionBuyAndStakeEth(
        uint256 _amountOut,
        uint256 _amountTokenOut,
        uint256 _deadline,
        uint256 _days
    )
        external
        payable
        whenNotPaused
        returns (uint256 axionBought, uint256 tokenBought)
    {
        require(_days >= minStakeDays, 'AUTOSTAKER: Minimum stake days');
        uint256 currentDay = getCurrentDay();
        //** Get Amounts */
        (uint256 _axionAmount, uint256 _tokenAmount, uint256 _recipientAmount) =
            dividedAmounts(msg.value);

        //** Swap tokens */
        axionBought = swapEthForTokens(
            axion,
            staking,
            _axionAmount,
            _amountOut,
            _deadline
        );
        tokenBought = swapEthForTokens(
            token,
            staking,
            _tokenAmount,
            _amountTokenOut,
            _deadline
        );

        // Call sendAndBurn
        uint256 payout =
            sendAndBurn(axionBought, tokenBought, _days, currentDay);

        //** Transfer any eithereum in contract to recipient address */
        recipient.transfer(_recipientAmount);

        //** Emit Event  */
        emit AcceleratorEth(
            msg.sender,
            token,
            currentDay,
            splitAmounts,
            axionBought,
            tokenBought,
            _days,
            payout
        );

        /** Return amounts for the frontend */
        return (axionBought, tokenBought);
    }

    /** @dev Swap tokens for tokens
        Description: Use uniswap to swap the token in for axion.
        @param _tokenOutAddress {address}
        @param _to {address}
        @param _amountIn {uint256}
        @param _amountOutMin {uint256}
        @param _deadline {uint256}

        @return {uint256}
     */
    function swapEthForTokens(
        address _tokenOutAddress,
        address _to,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _deadline
    ) internal returns (uint256) {
        /** Path through WETH */
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(uniswap).WETH();
        path[1] = _tokenOutAddress;

        /** Swap for tokens */
        return
            IUniswapV2Router02(uniswap).swapExactETHForTokens{value: _amountIn}(
                _amountOutMin,
                path,
                _to,
                _deadline
            )[1];
    }

    /** @dev stake with ethereum
        Description: Sell a token buy axion and then stake it for # of days
        @param _token {address}
        @param _amount {uint256}
        @param _amountOut {uint256}
        @param _deadline {uint256}
        @param _days {uint256}
     */
    function axionBuyAndStake(
        address _token,
        uint256 _amount,
        uint256 _amountOut,
        uint256 _amountTokenOut,
        uint256 _deadline,
        uint256 _days
    )
        external
        whenNotPaused
        returns (uint256 axionBought, uint256 tokenBought)
    {
        require(_days >= minStakeDays, 'AUTOSTAKER: Minimum stake days');
        require(
            allowedTokens[_token] == true,
            'AUTOSTAKER: This token is not allowed to be used on this contract'
        );
        uint256 currentDay = getCurrentDay();

        //** Get Amounts */
        (uint256 _axionAmount, uint256 _tokenAmount, uint256 _recipientAmount) =
            dividedAmounts(_amount);

        /** Transfer tokens to contract */
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        //** Swap tokens */
        axionBought = swapTokensForTokens(
            _token,
            axion,
            staking,
            _axionAmount,
            _amountOut,
            _deadline
        );

        if (_token != token) {
            tokenBought = swapTokensForTokens(
                _token,
                token,
                staking,
                _tokenAmount,
                _amountTokenOut,
                _deadline
            );
        } else {
            tokenBought = _tokenAmount;
            IERC20(token).transfer(staking, tokenBought);
        }

        // Call sendAndBurn
        uint256 payout =
            sendAndBurn(axionBought, tokenBought, _days, currentDay);

        //** Transfer tokens to Manager */
        IERC20(_token).transfer(recipient, _recipientAmount);

        //* Emit Event */
        emit AcceleratorToken(
            msg.sender,
            _token,
            currentDay,
            token,
            splitAmounts,
            axionBought,
            tokenBought,
            _days,
            payout
        );

        /** Return amounts for the frontend */
        return (axionBought, tokenBought);
    }

    /** @dev Swap tokens for tokens
        Description: Use uniswap to swap the token in for axion.
        @param _tokenInAddress {address}
        @param _tokenOutAddress {address}
        @param _to {address}
        @param _amountIn {uint256}
        @param _amountOutMin {uint256}
        @param _deadline {uint256}

        @return amounts {uint256[]} [TokenIn, ETH, AXN]
     */
    function swapTokensForTokens(
        address _tokenInAddress,
        address _tokenOutAddress,
        address _to,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _deadline
    ) internal returns (uint256) {
        /** Path through WETH */
        address[] memory path = new address[](3);
        path[0] = _tokenInAddress;
        path[1] = IUniswapV2Router02(uniswap).WETH();
        path[2] = _tokenOutAddress;

        /** Check allowance */
        if (
            IERC20(_tokenInAddress).allowance(address(this), uniswap) < 2**255
        ) {
            IERC20(_tokenInAddress).approve(uniswap, 2**255);
        }

        /** Swap for tokens */
        return
            IUniswapV2Router02(uniswap).swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                path,
                _to,
                _deadline
            )[2];
    }

    /** @dev sendAndBurn
        Description: Burns axion, transfers btc to staking, and creates the stake
        @param _axionBought {uint256}
        @param _tokenBought {uint256}
        @param _days {uint256}
        @param _currentDay {uint256}

        @return payout uint256 
     */
    function sendAndBurn(
        uint256 _axionBought,
        uint256 _tokenBought,
        uint256 _days,
        uint256 _currentDay
    ) internal returns (uint256) {
        // uint256 tokensAfterSplit =
        //     _tokenBought - (_tokenBought / splitAmounts[1]);
        //** Transfer BTC, Axion is transferred to staking immediately for burn */
        // IERC20(token).transfer(staking, _tokenBought);
        IStaking(staking).updateTokenPricePerShare(
            msg.sender,
            recipient,
            token,
            _tokenBought
        );

        /** Add additional axion if stake length is greater then 1year */
        uint256 payout = (100 * _axionBought) / splitAmounts[0];
        payout = payout + (payout * baseBonus) / 100;
        if (_days >= bonusStartDays && bought[_currentDay] < maxBoughtPerDay) {
            // Get amount for sale left
            uint256 payoutWithBonus = maxBoughtPerDay - bought[_currentDay];
            // Add to payout
            bought[_currentDay] += payout;
            if (payout > payoutWithBonus) {
                uint256 payoutWithoutBonus = payout - payoutWithBonus;

                payout =
                    (payoutWithBonus +
                        (payoutWithBonus *
                            ((_days / bonusStartDays) + bonusStartPercent)) /
                        100) +
                    payoutWithoutBonus;
            } else {
                payout =
                    payout +
                    (payout * ((_days / bonusStartDays) + bonusStartPercent)) /
                    100; // multiply by percent divide by 100
            }
        } else {
            //** If not returned above add to bought and return payout. */
            bought[_currentDay] += payout;
        }

        //** Stake the burned tokens */
        IStaking(staking).externalStake(payout, _days, msg.sender);
        //** Return amounts for the frontend */
        return payout;
    }

    /** Utility Functions */
    /** @dev currentDay
        Description: Get the current day since start of contract
     */
    function getCurrentDay() public view returns (uint256) {
        return (now - start) / secondsInDay;
    }

    /** @dev splitAmounts */
    function getSplitAmounts() public view returns (uint8[3] memory) {
        uint8[3] memory _splitAmounts;
        for (uint256 i = 0; i < splitAmounts.length; i++) {
            _splitAmounts[i] = splitAmounts[i];
        }
        return _splitAmounts;
    }

    /** @dev dividedAmounts
        Description: Uses Split amounts to return amountIN should be each
        @param _amountIn {uint256}
     */
    function dividedAmounts(uint256 _amountIn)
        internal
        view
        returns (
            uint256 _axionAmount,
            uint256 _tokenAmount,
            uint256 _recipientAmount
        )
    {
        _axionAmount = (_amountIn * splitAmounts[0]) / 100;
        _tokenAmount = (_amountIn * splitAmounts[1]) / 100;
        _recipientAmount = (_amountIn * splitAmounts[2]) / 100;
    }

    // -------------------- Setter Functions ------------------------
    /** @dev setAllowedToken
        Description: Allow tokens can be swapped for axion.
        @param _token {address}
        @param _allowed {bool}
     */
    function setAllowedToken(address _token, bool _allowed)
        external
        onlyManager
    {
        allowedTokens[_token] = _allowed;
    }

    /** @dev setAllowedTokens
        Description: Allow tokens can be swapped for axion.
        @param _tokens {address}
        @param _allowed {bool}
     */
    function setAllowedTokens(
        address[] calldata _tokens,
        bool[] calldata _allowed
    ) external onlyManager {
        for (uint256 i = 0; i < _tokens.length; i++) {
            allowedTokens[_tokens[i]] = _allowed[i];
        }
    }

    /** @dev setPaused
        @param _p {bool}
     */
    function setPaused(bool _p) external onlyManager {
        _paused = _p;
    }

    /** @dev setFee
        @param _days {uint256}
     */
    function setMinStakeDays(uint256 _days) external onlyManager {
        minStakeDays = _days;
    }

    /** @dev splitAmounts
        @param _splitAmounts {uint256[]}
     */
    function setSplitAmounts(uint8[3] calldata _splitAmounts)
        external
        onlyManager
    {
        uint8 total = _splitAmounts[0] + _splitAmounts[1] + _splitAmounts[2];
        require(total == 100, 'ACCELERATOR: Split Amounts must == 100');

        splitAmounts = _splitAmounts;
    }

    /** @dev maxBoughtPerDay
        @param _amount uint256 
    */
    function setMaxBoughtPerDay(uint256 _amount) external onlyManager {
        maxBoughtPerDay = _amount;
    }

    /** @dev setBaseBonus
        @param _amount uint256 
    */
    function setBaseBonus(uint8 _amount) external onlyManager {
        baseBonus = _amount;
    }

    /** @dev setBonusStart%
        @param _amount uint8 
    */
    function setBonusStartPercent(uint8 _amount) external onlyManager {
        bonusStartPercent = _amount;
    }

    /** @dev setBonusStartDays
        @param _amount uint8 
    */
    function setBonusStartDays(uint16 _amount) external onlyManager {
        bonusStartDays = _amount;
    }

    /** @dev setRecipient
        @param _recipient uint8 
    */
    function setRecipient(address payable _recipient) external onlyManager {
        recipient = _recipient;
    }

    /** @dev setStart
        @param _start uint8 
    */
    function setStart(uint256 _start) external onlyManager {
        start = _start;
    }

    /** @dev setToken
        @param _token {address} 
    */
    function setToken(address _token) external onlyManager {
        token = _token;
        IStaking(staking).addDivToken(_token);
    }

    /** @dev setVC
        @param _vcauction {address} 
    */
    function setVCAuction(address _vcauction) external onlyManager {
        vcauction = _vcauction;
    }

    /** @dev setVC
        @param _staking {address} 
    */
    function setStaking(address _staking) external onlyManager {
        staking = _staking;
    }

    // -------------------- Getter Functions ------------------------
    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /** @dev initialize
        Description: Initialize contract
        @param _migrator {address}
        @param _manager {address}
     */
    function initialize(address _migrator, address _manager)
        external
        initializer
    {
        /** Setup roles and addresses */
        _setupRole(MIGRATOR_ROLE, _migrator);
        _setupRole(MANAGER_ROLE, _manager);
    }

    function startAddresses(
        address _staking,
        address _axion,
        address _token,
        address payable _uniswap,
        address payable _recipient
    ) external onlyMigrator {
        staking = _staking;
        axion = _axion;
        token = _token;
        uniswap = _uniswap;
        recipient = _recipient;
    }

    function startVariables(
        uint256 _minStakeDays,
        uint256 _start,
        uint256 _secondsInDay,
        uint256 _maxBoughtPerDay,
        uint8 _bonusStartPercent,
        uint16 _bonusStartDays,
        uint8 _baseBonus,
        uint8[3] calldata _splitAmounts
    ) external onlyMigrator {
        uint8 total = _splitAmounts[0] + _splitAmounts[1] + _splitAmounts[2];
        require(total == 100, 'ACCELERATOR: Split Amounts must == 100');

        minStakeDays = _minStakeDays;
        start = _start;
        secondsInDay = _secondsInDay;
        maxBoughtPerDay = _maxBoughtPerDay;
        bonusStartPercent = _bonusStartPercent;
        bonusStartDays = _bonusStartDays;
        baseBonus = _baseBonus;
        splitAmounts = _splitAmounts;
    }
}
