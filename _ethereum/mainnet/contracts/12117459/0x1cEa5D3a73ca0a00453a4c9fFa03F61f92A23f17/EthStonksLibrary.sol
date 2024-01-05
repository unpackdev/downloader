pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./AggregatorV3Interface.sol";

import "./StonkNFT.sol";
import "./TokenInterface.sol";

contract EthStonksLibrary {
    using SafeMath for uint;

    address private admin;
    address private stonkRevenueService;

    uint constant private PSN = 10000;
    uint constant private PSNH = 5000;
    uint constant private INVEST_RATIO = 86400;
    uint constant private MARKET_RESET = 864000000000;
    uint constant private CB_ONE = 1e16;
    uint constant private CB_TWO = 1e25;
    uint constant private CB_THREE = 1e37;
    uint32 constant private RND_MAX = 72 hours;
    uint32 constant private PREMARKET_LENGTH = 24 hours;
    uint8 constant private FEE = 20;

    uint constant public MIN_BUY = 1e6;
    uint constant public BROKER_REQ = 1000e6;

    uint constant public MIN_NFT_BUY = 100e6;

    struct Round {
        mapping(uint => address) idToAddr;
        mapping(address => uint) addrToId;
        uint seedBalance;
        uint preMarketSpent;
        uint preMarketDivs;
        uint stonkMarket;
        address spender;
        address prod;
        address chadBroker;
        mapping(int8 => address) lastBuys;
        uint bailoutFund;
        uint nextCb;
        uint32 playerIndex;
        uint32 seedTime;
        uint32 end;
        uint16 index;
        int8 lastBuyIndex;
    }

    struct PlayerRound {
        // management
        uint preMarketSpent;
        uint lastAction;
        uint companies;
        uint oldRateStonks;
        // record keeping
        uint spent;
        uint stonkDivs;
        uint cashbackDivs;
        uint brokerDivs;
        uint brokeredTrades;
        uint bailoutDivs;
        uint chadBrokerDivs;
        uint gasSpent;
    }

    struct Player {
        bool isBroker;
        string lastBroker;
        uint preMarketDivsWithdrawn;
        uint availableDivs;
        mapping(uint => PlayerRound) playerRound;
    }

    struct BailoutEvent {
        string prod;
        string spender;
        string b1;
        string b2;
        string b3;
        string b4;
        string b5;
        uint round;
        uint cb;
        uint amount;
    }

    mapping(address => string) public addressToName;
    mapping(string => address) public nameToAddress;

    mapping(address => Player) internal player;
    mapping(uint => Round) internal round;
    uint public r = 1;

    uint public pmDivBal;       // needs to be separate because it is dynamic for users
    uint public divBal;         // includes bailouts, cashback, broker divs and stonk sales
    uint public devBal;         // dev fee balance 😊

    string private featuredBroker = 'MrF';

    TokenInterface private token;

    AggregatorV3Interface internal priceFeed;

    StonkNFT internal nft;

    bool public enableGas = true;

    event LogPreMarketBuy(string name, string broker, uint value, bool isBroker, bool validBroker);
    event LogBuy(string name, string broker, uint value, bool isBroker, bool validBroker);
    event LogInvest(string name, uint value);
    event LogSell(string name, uint value);
    event LogWithdraw(string name, uint value);
    event LogHistory(uint index, uint fund, uint market, uint timestamp);
    event LogBailouts(BailoutEvent e);

    event NewPlayer(address addr, string name);
    event NewBroker(string name);
    event NewChad(string name, uint divs, uint trades);

    event NewRound(uint endBlock);

    function seedMarket(uint amount)
    external
    {
        token.transferFrom(msg.sender, address(this), amount);
        round[r].seedBalance += amount;
        writeHistory();
    }

    function preMarketBuy(uint _amount, string calldata _broker)
    public
    {
        address addr = msg.sender;
        address brokerAddr = nameToAddress[_broker];
        bool validBroker = false;

        Round storage _round = round[r];
        Player storage _player = player[addr];
        PlayerRound storage _playerRound = player[addr].playerRound[r];

        _round.preMarketSpent += _amount;
        _round.stonkMarket = preStonkMarket(_round.preMarketSpent);

        // no production until premarket ends
        _playerRound.lastAction = PREMARKET_LENGTH + round[r].seedTime;
        _playerRound.preMarketSpent += _amount;

        _playerRound.spent += _amount;
        if (_playerRound.spent > player[_round.spender].playerRound[r].spent) {
            _round.spender = addr;
            // only during premarket
            _round.prod = addr;
        }

        if (!_player.isBroker && _playerRound.spent >= BROKER_REQ) {
            _player.isBroker = true;
            emit NewBroker(addressToName[addr]);
        }

        if (_player.isBroker) {// if user is a broker, they get 10% back
            divBal += _amount / 10;
            _player.availableDivs += _amount / 10;
            _playerRound.cashbackDivs += _amount / 10;
        } else if (player[brokerAddr].isBroker && brokerAddr != addr) {// or if valid broker, 5% each
            validBroker = true;
            divBal += _amount / 10;
            _player.lastBroker = _broker;
            _player.availableDivs += _amount / 20;
            _playerRound.cashbackDivs += _amount / 20;
            player[brokerAddr].availableDivs += _amount / 20;
            player[brokerAddr].playerRound[r].brokerDivs += _amount / 20;
            player[brokerAddr].playerRound[r].brokeredTrades++;
        }

        if (validBroker) {
            updateChadBroker(brokerAddr);
        }

        token.transferFrom(addr, address(this), _amount);
        feeSplit((_amount * FEE) / 100);

        updateLastBuyer();
        writeHistory();
        emit LogPreMarketBuy(addressToName[addr], _broker, _amount, _player.isBroker, validBroker);
    }

    function buy(uint _amount, string calldata _broker)
    external
    {
        address addr = msg.sender;
        address brokerAddr = nameToAddress[_broker];
        bool validBroker = false;

        if (block.timestamp > round[r].end) {// market crash
            incrementRound();
            preMarketBuy(_amount, _broker);
            return;
        }

        if (round[r].stonkMarket > round[r].nextCb) {
            bool roundOver = handleCircuitBreaker();
            if (roundOver) {
                preMarketBuy(_amount, _broker);
                return;
            }
        }

        Round storage _round = round[r];
        Player storage _player = player[addr];
        PlayerRound storage _playerRound = player[addr].playerRound[r];

        _playerRound.spent += _amount;
        if (_playerRound.spent > player[_round.spender].playerRound[r].spent) {
            _round.spender = addr;
        }

        if (!_player.isBroker && _playerRound.spent >= BROKER_REQ) {
            _player.isBroker = true;
            emit NewBroker(addressToName[addr]);
        }

        if (_player.isBroker) {// if user is a broker, they get 10% back
            divBal += _amount / 10;
            _player.availableDivs += _amount / 10;
            _playerRound.cashbackDivs += _amount / 10;
        } else if (player[brokerAddr].isBroker && brokerAddr != addr) {// or if valid broker, 5% each
            validBroker = true;
            divBal += _amount / 10;
            _player.lastBroker = _broker;
            _player.availableDivs += _amount / 20;
            _playerRound.cashbackDivs += _amount / 20;
            player[brokerAddr].availableDivs += _amount / 20;
            player[brokerAddr].playerRound[r].brokerDivs += _amount / 20;
            player[brokerAddr].playerRound[r].brokeredTrades++;
        }

        uint companies = _playerRound.companies.add(calculatePreMarketOwned(addr));

        _playerRound.oldRateStonks += companies.mul(block.timestamp - _playerRound.lastAction);
        _playerRound.lastAction = block.timestamp;
        _playerRound.companies += calculateBuy(_amount) / INVEST_RATIO;

        if (_playerRound.companies > getCompanies(_round.prod)) {
            _round.prod = addr;
        }

        _round.stonkMarket += (calculateBuy(_amount) / 10);

        if (validBroker) {
            updateChadBroker(brokerAddr);
        }

        token.transferFrom(addr, address(this), _amount);
        feeSplit((_amount * FEE) / 100);

        incrementTimer(_amount);
        updateLastBuyer();
        writeHistory();
        emit LogBuy(addressToName[addr], _broker, _amount, _player.isBroker, validBroker);
    }

    function sell()
    external
    {
        if (block.timestamp > round[r].end) {// market crash
            incrementRound();
            return;
        }

        if (round[r].stonkMarket > round[r].nextCb) {
            bool roundOver = handleCircuitBreaker();
            if (roundOver) {
                return;
            }
        }

        address addr = msg.sender;
        uint stonks = getStonks(addr);
        require(stonks > 0);
        uint received = calculateTrade(stonks, round[r].stonkMarket, marketFund());
        uint fee = (received * FEE) / 100;
        received -= fee;

        player[addr].playerRound[r].lastAction = block.timestamp;
        player[addr].playerRound[r].oldRateStonks = 0;
        player[addr].playerRound[r].stonkDivs += received;
        player[addr].availableDivs += received;
        divBal += received;

        round[r].stonkMarket += stonks;

        feeSplit(fee);

        writeHistory();
        emit LogSell(addressToName[addr], received);

        withdrawBonus(); // gas is expensive
    }

    function handleCircuitBreaker()
    public
    returns (bool)
    {
        if (round[r].stonkMarket > CB_THREE) {
            payBailouts(3, round[r].bailoutFund);
            incrementRound();
            return true;
        }

        uint pool = round[r].bailoutFund / 3;
        round[r].bailoutFund -= pool;

        if (round[r].stonkMarket > CB_TWO) {
            round[r].nextCb = CB_THREE;
            payBailouts(2, pool);
            return false;
        }

        // only other option is CB 1
        round[r].nextCb = CB_TWO;
        payBailouts(1, pool);
        return false;
    }

    function incrementRound()
    public
    {
        r++;
        round[r].stonkMarket = MARKET_RESET;
        round[r].seedTime = uint32(block.timestamp);
        round[r].seedBalance = marketFund();
        round[r].end = uint32(block.timestamp) + PREMARKET_LENGTH + RND_MAX;
        round[r].nextCb = CB_ONE;
        round[r].chadBroker = admin;
        
        emit NewRound(block.number);
    }

    function payBailouts(uint cb, uint pool)
    internal
    {
        Round storage _round = round[r];

        address spender = _round.spender;
        address prod = _round.prod;
        address b1 = _round.lastBuys[(5 + _round.lastBuyIndex - 1) % 5];
        address b2 = _round.lastBuys[(5 + _round.lastBuyIndex - 2) % 5];
        address b3 = _round.lastBuys[(5 + _round.lastBuyIndex - 3) % 5];
        address b4 = _round.lastBuys[(5 + _round.lastBuyIndex - 4) % 5];
        address b5 = _round.lastBuys[(5 + _round.lastBuyIndex - 5) % 5];

        // add the pool to divBal
        divBal += pool;
        uint a = pool / 1000;
        // production gets 10%
        uint sent = a * 100;
        player[prod].availableDivs += sent;
        player[prod].playerRound[r].bailoutDivs += sent;

        // each trade gets 4%
        uint buyerBailout = a * 40;
        player[b1].availableDivs += buyerBailout;
        player[b2].availableDivs += buyerBailout;
        player[b3].availableDivs += buyerBailout;
        player[b4].availableDivs += buyerBailout;
        player[b5].availableDivs += buyerBailout;
        player[b1].playerRound[r].bailoutDivs += buyerBailout;
        player[b2].playerRound[r].bailoutDivs += buyerBailout;
        player[b3].playerRound[r].bailoutDivs += buyerBailout;
        player[b4].playerRound[r].bailoutDivs += buyerBailout;
        player[b5].playerRound[r].bailoutDivs += buyerBailout;
        sent += buyerBailout * 5;

        // spender gets 70% + leftovers
        player[spender].availableDivs += (pool - sent);
        player[spender].playerRound[r].bailoutDivs += (pool - sent);

        BailoutEvent memory e;
        e.prod = addressToName[prod];
        e.spender = addressToName[spender];
        e.b1 = addressToName[b1];
        e.b2 = addressToName[b2];
        e.b3 = addressToName[b3];
        e.b4 = addressToName[b4];
        e.b5 = addressToName[b5];
        e.round = r;
        e.cb = cb;
        e.amount = pool;

        emit LogBailouts(e);
    }

    function invest()
    external
    {
        if (block.timestamp > round[r].end) {// market crash
            incrementRound();
            return;
        }

        if (round[r].stonkMarket > round[r].nextCb) {
            bool roundOver = handleCircuitBreaker();
            if (roundOver) {
                return;
            }
        }

        address addr = msg.sender;
        uint stonks = getStonks(addr);
        require(stonks > 0, 'No stonks to invest');
        uint value = calculateSell(stonks);

        uint companies = stonks / INVEST_RATIO;
        player[addr].playerRound[r].companies += companies;

        address prod = round[r].prod;
        if (getCompanies(addr) > getCompanies(prod)) {
            round[r].prod = addr;
        }

        // Reset counter
        player[addr].playerRound[r].lastAction = block.timestamp;
        player[addr].playerRound[r].oldRateStonks = 0;

        writeHistory();
        emit LogInvest(addressToName[addr], value);
    }

    function withdrawBonus()
    public
    {
        address addr = msg.sender;
        uint amount = player[addr].availableDivs;
        divBal = divBal.sub(amount);
        uint divs = totalPreMarketDivs(addr).sub(player[addr].preMarketDivsWithdrawn);
        if (divs > 0) {
            pmDivBal = pmDivBal.sub(divs);
            amount += divs;
            player[addr].preMarketDivsWithdrawn += divs;
        }
        require(amount > 0);
        player[addr].availableDivs = 0;
        token.transfer(addr, amount);
        emit LogWithdraw(addressToName[addr], amount);
    }

    function writeHistory()
    internal
    {
        emit LogHistory(round[r].index++, marketFund(), round[r].stonkMarket, block.timestamp);
    }


    function calculatePreMarketOwned(address addr)
    internal view
    returns (uint)
    {
        if (player[addr].playerRound[r].preMarketSpent == 0) {
            return 0;
        }
        uint stonks = calculateTrade(round[r].preMarketSpent, round[r].seedBalance, MARKET_RESET);
        uint stonkFee = (stonks * FEE) / 100;
        stonks -= stonkFee;
        uint totalSpentBig = round[r].preMarketSpent * 100;
        // inflate for precision
        uint userPercent = stonks / (totalSpentBig / player[addr].playerRound[r].preMarketSpent);
        return (userPercent * 100) / INVEST_RATIO;
    }

    function feeSplit(uint amount)
    internal
    {
        uint a = amount / 20;   // 1%

        Round storage _round = round[r];
        if (block.timestamp < PREMARKET_LENGTH + _round.seedTime) { // pre-market open, don't pay PM divs or chad
            _round.bailoutFund += (amount - (a * 3));               // bailout fund gets 17%
        } else {                                    // pre-market over
            if (_round.nextCb == CB_ONE) {          //  - - - cb1:
                _round.preMarketDivs += (a * 4);                    // 4% for pm divs
                pmDivBal += (a * 4);                                // 8 = pm (4) + devs (3) + chad (1)
                _round.bailoutFund += (amount - (a * 8));           // bailout fund gets 12%
            } else if (_round.nextCb == CB_TWO) {   //  - - - cb2:
                _round.preMarketDivs += (a * 7);                    // 7% for pm divs
                pmDivBal += (a * 7);                                // 11 = pm (7) + devs (3) + chad (1)
                _round.bailoutFund += (amount - (a * 11));          // bailout fund gets 9%
            } else {                                //  - - - cb3:
                _round.preMarketDivs += (a * 15);                   // 15% for pm divs
                pmDivBal += (a * 15);                               // 19 = pm (15) + devs (3) + chad (1)
                _round.bailoutFund += (amount - (a * 19));          // bailout fund gets 1%
            }
            // chadbroker always gets 1% after premarket
            player[_round.chadBroker].playerRound[r].chadBrokerDivs += a;
            player[_round.chadBroker].availableDivs += a;
            divBal += a;
        }
        // devs always get 3%
        devBal += a * 3;
    }


    function stonkNumbers(address addr, uint buyAmount)
    public view
    returns (uint companies, uint stonks, uint receiveBuy, uint receiveSell, uint dividends)
    {
        companies = getCompanies(addr);
        if (companies > 0) {
            stonks = getStonks(addr);
            if (stonks > 0) {
                receiveSell = calculateSell(stonks);
            }
        }
        if (buyAmount > 0) {
            receiveBuy = calculateBuy(buyAmount) / INVEST_RATIO;
        }
        dividends = player[addr].availableDivs + totalPreMarketDivs(addr).sub(player[addr].preMarketDivsWithdrawn);
    }

    function updateLastBuyer()
    internal
    {
        round[r].lastBuys[round[r].lastBuyIndex] = msg.sender;
        round[r].lastBuyIndex = (round[r].lastBuyIndex + 1) % 5;
    }

    function updateChadBroker(address addr)
    internal
    {
        PlayerRound memory _brokerRound = player[addr].playerRound[r];
        PlayerRound memory _chadBrokerRound = player[round[r].chadBroker].playerRound[r];
        if (
            (_brokerRound.brokerDivs > _chadBrokerRound.brokerDivs) &&
            (_brokerRound.brokeredTrades > _chadBrokerRound.brokeredTrades)
        ) {
            round[r].chadBroker = addr;
            emit NewChad(addressToName[addr], _brokerRound.brokerDivs, _brokerRound.brokeredTrades);
        }
    }

    function incrementTimer(uint amount)
    internal
    {
        uint incr;
        if (round[r].stonkMarket < CB_ONE) {            // CB1 = $48 per day
            incr = 30 minutes;
        } else if (round[r].stonkMarket < CB_TWO) {     // CB2 = $144 per day
            incr = 10 minutes;
        } else {
            incr = 1 minutes;                           // CB3 = $1440 per day
        }
        uint newTime = round[r].end + uint32((amount / 1e6) * incr);
        if (newTime > block.timestamp + RND_MAX) {
            round[r].end = uint32(block.timestamp) + RND_MAX;
        } else {
            round[r].end = uint32(newTime);
        }
    }

    function leaderNumbers()
    public view
    returns (uint, uint, uint, uint, uint, uint, uint)
    {
        address spender = round[r].spender;
        address prod = round[r].prod;
        address chad = round[r].chadBroker;
        return
        (
        player[spender].playerRound[r].spent,
        userRoundEarned(spender, r),
        getCompanies(prod),
        getStonks(prod),
        player[chad].playerRound[r].brokeredTrades,
        player[chad].playerRound[r].brokerDivs,
        player[chad].playerRound[r].chadBrokerDivs
        );
    }

    function userRoundEarned(address addr, uint rnd)
    internal view
    returns (uint earned)
    {
        PlayerRound memory _playerRound = player[addr].playerRound[rnd];
        earned += calculatePreMarketDivs(addr, rnd);
        earned += _playerRound.stonkDivs;
        earned += _playerRound.cashbackDivs;
        earned += _playerRound.brokerDivs;
        earned += _playerRound.bailoutDivs;
        earned += _playerRound.chadBrokerDivs;
    }


    function getCompanies(address addr)
    internal view
    returns (uint)
    {
        return (player[addr].playerRound[r].companies + calculatePreMarketOwned(addr));
    }

    function marketFund()
    internal view
    returns (uint)
    {
        return token.balanceOf(address(this)) - (round[r].bailoutFund + divBal + pmDivBal + devBal);
    }

    function calculateTrade(uint rt, uint rs, uint bs)
    internal pure
    returns (uint)
    {
        return PSN.mul(bs) / PSNH.add(PSN.mul(rs).add(PSNH.mul(rt)) / rt);
    }

    function calculateSell(uint stonks)
    internal view
    returns (uint)
    {
        uint received = calculateTrade(stonks, round[r].stonkMarket, marketFund());
        uint fee = (received * FEE) / 100;
        return (received - fee);
    }

    function calculateBuy(uint spent)
    internal view
    returns (uint)
    {
        uint stonks = calculateTrade(spent, marketFund(), round[r].stonkMarket);
        uint stonkFee = (stonks * FEE) / 100;
        return (stonks - stonkFee);
    }


    function getStonks(address addr)
    internal view
    returns (uint)
    {
        return player[addr].playerRound[r].oldRateStonks.add(currentRateStonks(addr));
    }

    function currentRateStonks(address addr)
    internal view
    returns (uint)
    {
        if (player[addr].playerRound[r].lastAction > block.timestamp) {// applies during premarket
            return 0;
        }
        uint secondsPassed = block.timestamp - player[addr].playerRound[r].lastAction;
        return secondsPassed.mul(getCompanies(addr));
    }

    function preStonkMarket(uint totalSpent) // determines stonkMarket value after premarket buys
    internal view
    returns (uint)
    {
        uint stonks = calculateTrade(totalSpent, round[r].seedBalance, MARKET_RESET);
        uint stonkFee = (stonks * FEE) / 100;
        return ((stonks - stonkFee) / 10) + MARKET_RESET;
    }

    function calculatePreMarketDivs(address addr, uint rnd)
    public view
    returns (uint)
    {
        if (player[addr].playerRound[rnd].preMarketSpent == 0) {
            return 0;
        }

        uint totalDivs = round[rnd].preMarketDivs;
        uint totalSpent = round[rnd].preMarketSpent;
        uint playerSpent = player[addr].playerRound[rnd].preMarketSpent;
        uint playerDivs = (((playerSpent * 2 ** 64) / totalSpent) * totalDivs) / 2 ** 64;

        return playerDivs;
    }

    function gameData()
    public view
    returns (uint rnd, uint index, uint open, uint end, uint fund, uint market, uint bailout)
    {
        return
        (
        r,
        round[r].index,
        marketOpen(),
        round[r].end,
        marketFund(),
        round[r].stonkMarket,
        round[r].bailoutFund
        );
    }

    function totalPreMarketDivs(address addr)
    internal view
    returns (uint)
    {
        uint divs;
        for (uint rnd = 1; rnd <= r; rnd++) {
            divs += calculatePreMarketDivs(addr, rnd);
        }
        return divs;
    }

    function marketOpen()
    internal view
    returns (uint)
    {
        if (block.timestamp > round[r].seedTime + PREMARKET_LENGTH) {
            return 0;
        }
        return (round[r].seedTime + PREMARKET_LENGTH) - block.timestamp;
    }
}
