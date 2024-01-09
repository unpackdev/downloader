// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IUniswapV2Pair.sol";

// import "./IERC20.sol";

contract FleepToken is ERC20 {

    //state of token
    enum State {
        INITIAL,
        ACTIVE
    }

    State public state = State.INITIAL;

    function getState() public view returns (State) {
        return state;
    }

    function enableToken() public onlyOwner {
        state = State.ACTIVE;
    }

    function disableToken() public onlyOwner {
        state = State.INITIAL;
    }

    function setState(uint256 _value) public onlyOwner {
        require(uint256(State.ACTIVE) >= _value);
        require(uint256(State.INITIAL) <= _value);
        state = State(_value);
    }

    function requireActiveState() view internal {
        require(state == State.ACTIVE, 'Require token enable trading');
    }

    address public owner = msg.sender;
    address public devWallet;
    address public rewardWallet;
    uint256 initialTime;
    uint256 initialPrice; // 1.5$ * 10 ** 18
    //price feed uniswap
    //if useFeedPrice == false, don't apply tax for token
    bool public useFeedPrice = false;
    address public pairFeedPrice;
    bool public isToken0;
    // tax control list
    mapping(address => bool) applyTaxList;
    mapping(address => bool) ignoreTaxList;

    //define event
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    // modifier control
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    constructor(
        address _devWallet,
        address _rewardWallet,
        // bool _isToken0,
        uint256 _initialTime,
        uint256 _initialPrice
    ) payable ERC20("Fleep Token", "FLEEP") {
        //initital total supply is 1000.000 tokens
        devWallet = _devWallet;
        rewardWallet = _rewardWallet;
        _mint(msg.sender, 600000 * 10**decimals());
        _mint(devWallet, 200000 * 10**decimals());
        _mint(rewardWallet, 200000 * 10**decimals());
        //-- data feed
        pairFeedPrice = address(0);
        isToken0 = false;
        //-- end datafeed
        initialTime = _initialTime;
        // explore
        initialPrice = _initialPrice;
        ignoreTaxList[devWallet] = true;
        ignoreTaxList[rewardWallet] = true;
    }

    // modify transfer function to check tax effect
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        //tax here
        address from = _msgSender();
        uint256 finalAmount = amount;
        if (
            ignoreTaxList[from] == true || ignoreTaxList[recipient] == true
        ) {} else if (
            applyTaxList[from] == true && applyTaxList[recipient] == true
        ) {
            // not apply tax
            // do nothings
        } else if (applyTaxList[from] == true) {
            if (useFeedPrice) {
                int256 deviant = getDeviant();
                // if from Effect => user buy token from LP
                // [to] buy token, so [to] will receive reward
                (uint256 pct, uint256 base) = getBuyerRewardPercent(deviant);
                uint256 rewardForBuyer = (amount * pct) / (base * 100);
                // finalAmount = finalAmount - rewardForBuyer;
                _transfer(rewardWallet, recipient, rewardForBuyer);
            }
        } else if (applyTaxList[recipient] == true) {
            if (useFeedPrice) {
                //check max sell token
                require(finalAmount <= getMaxSellable(), "Final amount over max sellable amount");
                int256 deviant = getDeviant();
                // if [to] effect (example: [to] is LP Pool) => [from] sell token
                (uint256 pct, uint256 base) = getTaxPercent(deviant);
                (uint256 pctReward, uint256 baseReward) = getRewardPercent(
                    deviant
                );
                uint256 tax = (amount * pct) / (base * 100);
                uint256 taxToReward = (amount * pctReward) / (baseReward * 100);
                require(finalAmount > tax, "tax need smaller than amount");
                require(tax > taxToReward, "tax need bigger than taxToReward");
                finalAmount = finalAmount - tax;
                _transfer(_msgSender(), rewardWallet, taxToReward);
                _transfer(_msgSender(), devWallet, tax - taxToReward);
            }
        } else {
            // do nothings
        }
        //end
        //validate state
        if (ignoreTaxList[from] != true && ignoreTaxList[recipient] != true) {
            requireActiveState();
        }
        //end
        _transfer(_msgSender(), recipient, finalAmount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 finalAmount = amount;
        address from = sender;
        if (
            ignoreTaxList[from] == true || ignoreTaxList[recipient] == true
        ) {} else if (
            applyTaxList[from] == true && applyTaxList[recipient] == true
        ) {
            // not apply tax
            // do nothings
        } else if (applyTaxList[from] == true) {
            if (useFeedPrice) {
                int256 deviant = getDeviant();
                // if from Effect => user buy token from LP
                // [to] buy token, so [to] will receive reward
                (uint256 pct, uint256 base) = getBuyerRewardPercent(deviant);
                uint256 rewardForBuyer = (amount * pct) / (base * 100);
                // finalAmount = finalAmount - rewardForBuyer;
                _transfer(rewardWallet, recipient, rewardForBuyer);
            }
        } else if (applyTaxList[recipient] == true) {
            if (useFeedPrice) {
                //check max sell token
                require(finalAmount <= getMaxSellable(), "Final amount over max sellable amount");
                int256 deviant = getDeviant();
                // if [to] effect (example: [to] is LP Pool) => [from] sell token
                (uint256 pct, uint256 base) = getTaxPercent(deviant);
                (uint256 pctReward, uint256 baseReward) = getRewardPercent(
                    deviant
                );
                uint256 tax = (amount * pct) / (base * 100);
                uint256 taxToReward = (amount * pctReward) / (baseReward * 100);
                require(
                    balanceOf(sender) >= (amount + tax),
                    "Out of token becase tax apply"
                );
                // require(finalAmount > tax, "tax need smaller than amount");
                require(tax > taxToReward, "tax need bigger than taxToReward");
                finalAmount = finalAmount - tax;
                _transfer(sender, rewardWallet, taxToReward);
                _transfer(sender, devWallet, tax - taxToReward);
            }
        } else {
            // do nothings
        }
        //validate state
        if (ignoreTaxList[from] != true && ignoreTaxList[recipient] != true) {
            requireActiveState();
        }
        //end
        return super.transferFrom(sender, recipient, amount);
    }

    function changeInitialTimestamp(uint256 _initialTimestamp)
        public
        onlyOwner
        returns (bool)
    {
        initialTime = _initialTimestamp;
        return true;
    }

    function changeInitialPeggedPrice(uint256 _initialPrice)
        public
        onlyOwner
        returns (bool)
    {
        initialPrice = _initialPrice;
        return true;
    }

    function setUseFeedPrice(bool _useFeedPrice) public onlyOwner {
        useFeedPrice = _useFeedPrice;
    }

    function setPairForPrice(address _pairFeedPrice, bool _isToken0)
        public
        onlyOwner
    {
        pairFeedPrice = _pairFeedPrice;
        isToken0 = _isToken0;
    }

    //apply tax list
    function addToApplyTaxList(address _address) public onlyOwner {
        applyTaxList[_address] = true;
    }

    function removeApplyTaxList(address _address) public onlyOwner {
        applyTaxList[_address] = false;
    }

    function isApplyTaxList(address _address) public view returns (bool) {
        return applyTaxList[_address];
    }

    //ignore tax list
    function addToIgnoreTaxList(address _address) public onlyOwner {
        ignoreTaxList[_address] = true;
    }

    function removeIgnoreTaxList(address _address) public onlyOwner {
        ignoreTaxList[_address] = false;
    }

    function isIgnoreTaxList(address _address) public view returns (bool) {
        return ignoreTaxList[_address];
    }

    // calculate price based on pair reserves
    // numberToken0 x price0 = numberToken1 x price1
    function getTokenPrice(
        address _pairAddress,
        bool _isToken0,
        uint256 amount
    ) public view returns (uint256) {
        if (_isToken0) {
            return getToken0Price(_pairAddress, amount);
        } else {
            return getToken1Price(_pairAddress, amount);
        }
    }

    function getTokenPrice() public view returns (uint256) {
        if (isToken0) {
            return getToken0Price(pairFeedPrice, 1);
        } else {
            return getToken1Price(pairFeedPrice, 1);
        }
    }

    function getMaxSellable() public view returns (uint256) {
        if (isToken0) {
            return getMaxSellable0(pairFeedPrice);
        } else {
            return getMaxSellable1(pairFeedPrice);
        }
    }

    function getMaxSellable0(address pairAddress)
        internal
        view
        returns (uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 Res0, , ) = pair.getReserves();
        return Res0 * 10 / 100;
    }

    function getMaxSellable1(address pairAddress)
        internal
        view
        returns (uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (, uint256 Res1, ) = pair.getReserves();
        return Res1 * 10 / 100;
    }

    function getToken1Price(address pairAddress, uint256 amount)
        internal
        view
        returns (uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        ERC20 token1 = ERC20(pair.token1());
        (uint256 Res0, uint256 Res1, ) = pair.getReserves();
        // decimals
        uint256 res0 = Res0 * (10**token1.decimals());
        return ((amount * res0) / Res1);
        // result = (price_1 /price_0) *  (10 ** token0.decimals())
    }

    /**
    return price of token 0 wall calculate by price of token 1 and GWEN of token 1
     */
    function getToken0Price(address pairAddress, uint256 amount)
        internal
        view
        returns (uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        ERC20 token0 = ERC20(pair.token0());
        (uint256 Res0, uint256 Res1, ) = pair.getReserves();
        //(Res0 / token0.decimals()) * price0 = (Res1 / token1.decimals()) * price1
        return (amount * Res1 * (10**token0.decimals())) / Res0;
        // result = (price_0 /price_1) *  (10 ** token1.decimals())
    }

    uint256 SECOND_PER_DAY = 86400; //24 * 60 * 60;
    uint256 private A = 0;
    uint256 private perA  = 1;
    uint256 private B  = 0;
    uint256 private perB  = 1;

    function setRate(uint256 _A, uint256 _perA, uint256 _B, uint256 _perB)
        public
        onlyOwner
    {
        //change initial price and time
        initialPrice = getPeggedPrice();
        initialTime = block.timestamp;
        //change rate
        A = _A;
        perA  = _perA;
        B = _B;
        perB = _perB;
    }

    /**
     pegged price increase by day: 0.0002X+0.01 (x is number of day from initialDay)
     ==> pegged_price_n = initial_price + n * (0.01) + (n*(n+1)/2 * 0.0002)

     increase per day:  X * A / perA + B / perB
     */
    //return the price of token * 10 ** 18
    function getPeggedPrice() public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if (currentTime <= initialTime) {
            return initialPrice;
        }
        uint256 daysFromBegin = ceil(
            (currentTime - initialTime) / SECOND_PER_DAY,
            1
        );
        uint256 peggedPrice = uint256(
            initialPrice +
                ((10**decimals()) * daysFromBegin * B) /
                perB +
                ((10**decimals()) * daysFromBegin * (daysFromBegin + 1) * A) /
                (perA * 2)
        );
        return (peggedPrice);
    }

    /**
    return deviant of price - beetween current price and pegged price
     */
    function getDeviant() public view returns (int256) {
        // calculate with the same measurement
        int256 peggedPrice = int256(getPeggedPrice());
        int256 currentPrice = int256(getTokenPrice(pairFeedPrice, isToken0, 1));
        return ((currentPrice - peggedPrice) * 100) / peggedPrice;
    }

    uint256 DEVIDE_STEP = 5;

    function getTaxPercent() public view returns (uint256, uint256){
        int256 deviant = getDeviant();
        return getTaxPercent(deviant);
    }

    function getTaxPercent(int256 deviant)
        public
        view
        returns (uint256, uint256)
    {
        // 0.93674 ^ -5 = 138645146889 / 10 ** 11
        //tax : 0.93674^{x}+3

        if (deviant < 0) {
            uint256 uDeviant = uint256(-deviant);
            uint256 step = uDeviant / DEVIDE_STEP;
            uint256 resident = uDeviant - step * DEVIDE_STEP;
            uint256 j = 0;
            uint256 percent = 10**18;
            // return 9 ** uDeviant;
            for (j = 0; j < step; j += 1) {
                //for loop example
                percent = (percent * 138645146889) / 10**11;
            }
            percent = (percent * (100000**resident)) / (93674**resident);
            return (percent / (10**14) + 3 * 10000, 10**4);
        } else {
            //business
            uint256 uDeviant = uint256(deviant);
            uint256 step = uDeviant / DEVIDE_STEP;
            uint256 resident = uDeviant - step * DEVIDE_STEP;
            uint256 j = 0;
            uint256 percent = 10**18;
            // return 9 ** uDeviant;
            for (j = 0; j < step; j += 1) {
                //for loop example
                percent = (percent * 93674**5) / (100000**5);
            }
            percent = (percent * (93674**resident)) / (100000**resident);
            return (percent / (10**14) + 3 * 10000, 10**4);
        }
    }

    function getRewardPercent() public view returns (uint256, uint256){
        int256 deviant = getDeviant();
        return getRewardPercent(deviant);
    }

    function getRewardPercent(int256 deviant)
        public
        view
        returns (uint256, uint256)
    {
        //1.0654279291277341544231240477738 = 1/0.93859 ~ 1.0654
        // 0.93859 ^ -10 = 1.8846936700630545738235994788055 ~ 188469367 / 10**8
        // 0.93859 ^ -5 = 137284145846 / 10 ** 11
        // 0.93859 ** x = (1/(0.93859))^ (-x) = (1 + 0.0654279291277341544231240477738) ^ -x ~ = 1 + (-x) *  0.0654279291277341544231240477738
        //reward : 0.93859 ^ -x + 0.2

        if (deviant < 0) {
            uint256 uDeviant = uint256(-deviant);
            uint256 step = uDeviant / DEVIDE_STEP;
            uint256 resident = uDeviant - step * DEVIDE_STEP;
            uint256 j = 0;
            uint256 percent = 10**18;
            // return 9 ** uDeviant;
            for (j = 0; j < step; j += 1) {
                //for loop example
                percent = (percent * 137284145846) / 10**11;
            }
            percent = (percent * (100000**resident)) / (93859**resident);
            return (percent / (10**14) + 2000, 10**4);
        } else {
            //business
            uint256 uDeviant = uint256(deviant);
            uint256 step = uDeviant / DEVIDE_STEP;
            uint256 resident = uDeviant - step * DEVIDE_STEP;
            uint256 j = 0;
            uint256 percent = 10**18;
            // return 9 ** uDeviant;
            for (j = 0; j < step; j += 1) {
                //for loop example
                percent = (percent * 93859**5) / (100000**5);
            }
            percent = (percent * (93859**resident)) / (100000**resident);
            return (percent / (10**14) + 2 * 10**3, 10**4);
        }
    }

    function getBuyerRewardPercent() public view returns (uint256, uint256){
        int256 deviant = getDeviant();
        return getBuyerRewardPercent(deviant);
    }


    function getBuyerRewardPercent(int256 deviant)
        public
        view
        returns (uint256, uint256)
    {
        // 0.947 ^ -5 = 1.31295579684  / 10 ** 11
        //reward : 0.947^{x}+0.05

        if (deviant < 0) {
            uint256 uDeviant = uint256(-deviant);
            uint256 step = uDeviant / DEVIDE_STEP;
            uint256 resident = uDeviant - step * DEVIDE_STEP;
            uint256 j = 0;
            uint256 percent = 10**18;
            // return 9 ** uDeviant;
            for (j = 0; j < step; j += 1) {
                //for loop example
                percent = (percent * 131295579684) / 10**11;
            }
            percent = (percent * (1000**resident)) / (947**resident);
            return (percent / (10**14) + 500, 10**4);
        } else {
            //business
            uint256 uDeviant = uint256(deviant);
            uint256 step = uDeviant / DEVIDE_STEP;
            uint256 resident = uDeviant - step * DEVIDE_STEP;
            uint256 j = 0;
            uint256 percent = 10**18;
            // return 9 ** uDeviant;
            for (j = 0; j < step; j += 1) {
                //for loop example
                percent = (percent * 947**5) / (1000**5);
            }
            percent = (percent * (947**resident)) / (1000**resident);
            return (percent / (10**14) + 500, 10**4);
        }
    }

    // internal function
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        return ((a + m - 1) / m) * m;
    }
}
