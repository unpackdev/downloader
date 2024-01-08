// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./IMarsBaseOtc.sol";
import "./Vault.sol";

contract MarsBaseOtc is Ownable, IMarsBaseOtc, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeMath for uint8;

    Vault public vault;

    uint256 public constant BROKERS_DENOMINATOR = 10000;

    // public mappings
    // White list of liquidity tokens
    mapping(address => bool) public isAddressInWhiteList;
    // Info about bids
    mapping(bytes32 => OrderInfo) public orders;
    mapping(bytes32 => BrokerInfo) public ownerBroker;
    mapping(bytes32 => BrokerInfo) public usersBroker;
    mapping(bytes32 => OrdersBidInfo[]) public ordersBid;
    mapping(bytes32 => OrdersBidInfo[]) public ordersOwnerBid;

    // to prevent too deep stack
    struct IntVars {
        uint256 amount;
        uint256 toBroker;
        uint256 toUser;
        uint256 i;
        uint256 len;
        uint256 ind;
    }

    //events
    event OrderCreated(
        bytes32 id,
        address owner,
        address token,
        uint256 amountOfToken,
        uint256 expiratinDate,
        uint16 discount,
        OrderTypeInfo typeOrder,
        bool isManual
    );

    event BuyOrderDeposit(
        bytes32 _id,
        address _token,
        address _from,
        uint256 _amount
    );

    event SellOrderDeposit(
        bytes32 _id,
        address _token,
        address _from,
        uint256 _amount
    );

    event OrderCancelled(bytes32 id);

    event OrderSwapped(bytes32 id);

    event OrderPartialSwapped(bytes32 id);

    // modifiers
    modifier onlyWhenVaultDefined() {
        require(address(vault) != address(0), "101");
        _;
    }

    modifier onlyWhenOrderExists(bytes32 id) {
        require(orders[id].owner != address(0), "102");
        _;
    }

    modifier onlyOrderOwner(bytes32 id) {
        require(orders[id].owner == _msgSender(), "103");
        _;
    }

    modifier standartChecking(bytes32 id) {
        OrderInfo memory order = orders[id];
        require(order.owner != address(0), "102");
        require(order.isCancelled == false, "601");
        require(order.isSwapped == false, "602");
        require(block.timestamp <= order.expirationDate, "604");
        _;
    }

    constructor() {}

    function tokenFallback(
        address,
        uint256,
        bytes calldata
    ) external {}

    /**
     * for back, which make swap for several bids
     * it close bids and order
     * @param id uniqe id of order
     * @param distribution rules for transfer tokens
     */
    function makeSwap(bytes32 id, OrdersBidInfo[] memory distribution)
        external
        override
        nonReentrant
        onlyOwner
    {
        OrderInfo memory order = orders[id];

        require(order.owner != address(0), "102");
        require(order.isCancelled == false, "601");
        require(order.isSwapped == false, "602");
        require(order.isManual == false, "603");
        require(block.timestamp <= order.expirationDate, "604");
        require(distribution.length > 0, "605");

        orders[id].isSwapped = true;

        address[] memory ownerTokensInvested;
        uint256[] memory ownerAmountsInvested;
        (ownerTokensInvested, ownerAmountsInvested) = getOrderOwnerInvestments(
            id
        );
        address[] memory usersTokensInvested;
        uint256[] memory usersAmountsInvested;
        (usersTokensInvested, usersAmountsInvested) = getOrderUserInvestments(
            id,
            address(0)
        );

        require(usersTokensInvested.length > 0, "506");
        require(ownerTokensInvested.length > 0, "507");

        address[] memory orderInvestors = getInvestors(id);

        IntVars memory vars;
        BrokerInfo memory brInfo;

        for (vars.i = 0; vars.i < distribution.length; vars.i = vars.i.add(1)) {
            if (distribution[vars.i].amountInvested == 0) continue;
            if (distribution[vars.i].investor != order.owner) {
                vars.ind = _findAddress(
                    orderInvestors,
                    distribution[vars.i].investor,
                    orderInvestors.length
                );
                require(vars.ind < orderInvestors.length, "508");
                brInfo = usersBroker[id];
            } else brInfo = ownerBroker[id];

            vars.ind = _findAddress(
                ownerTokensInvested,
                distribution[vars.i].investedToken,
                ownerTokensInvested.length
            );

            if (vars.ind >= ownerTokensInvested.length) {
                vars.ind = _findAddress(
                    usersTokensInvested,
                    distribution[vars.i].investedToken,
                    usersTokensInvested.length
                );
                require(vars.ind < usersTokensInvested.length, "509");
                require(
                    usersAmountsInvested[vars.ind] >=
                        distribution[vars.i].amountInvested,
                    "510"
                );
                usersAmountsInvested[vars.ind] = usersAmountsInvested[vars.ind]
                    .sub(distribution[vars.i].amountInvested);
            } else {
                require(
                    ownerAmountsInvested[vars.ind] >=
                        distribution[vars.i].amountInvested,
                    "511"
                );
                ownerAmountsInvested[vars.ind] = ownerAmountsInvested[vars.ind]
                    .sub(distribution[vars.i].amountInvested);
            }

            _transferTokens(
                id,
                distribution[vars.i].amountInvested,
                brInfo.percents,
                distribution[vars.i].investedToken,
                distribution[vars.i].investor,
                brInfo.broker,
                distribution[vars.i].from,
                true
            );
        }

        brInfo = ownerBroker[id];

        for (
            vars.i = 0;
            vars.i < usersTokensInvested.length;
            vars.i = vars.i.add(1)
        ) {
            if (usersAmountsInvested[vars.i] == 0) continue;
            _transferTokens(
                id,
                usersAmountsInvested[vars.i],
                brInfo.percents,
                usersTokensInvested[vars.i],
                order.owner,
                brInfo.broker,
                distribution[vars.i].from,
                true
            );
            usersAmountsInvested[vars.i] = 0;
        }

        _checkZeroBalance(ownerTokensInvested.length, ownerAmountsInvested);
        _checkZeroBalance(usersTokensInvested.length, usersAmountsInvested);

        emit OrderSwapped(id);
    }

    /**
     * for back, which make partial swap for several bids
     * it does not close bids and order
     * @param id uniqe id of order
     * @param distribution rules for transfer tokens
     */
    function makePartialSwap(bytes32 id, OrdersBidInfo[] memory distribution)
        external
        override
        nonReentrant
        standartChecking(id)
        onlyOwner
    {
        OrderInfo memory order = orders[id];

        require(order.isManual == false, "603");
        require(distribution.length > 0, "605");

        IntVars memory vars;
        OrdersBidInfo memory bid;
        BrokerInfo memory brInfo;

        for (vars.i = 0; vars.i < distribution.length; vars.i = vars.i.add(1)) {
            require(_ifAddressExists(id, distribution[vars.i].investor), "513");

            if (distribution[vars.i].from != order.owner) {
                brInfo = usersBroker[id];
                vars.ind = findBid(
                    false,
                    id,
                    distribution[vars.i].from,
                    distribution[vars.i].investedToken
                );
                bid = _setNewAmountInvested(
                    id,
                    vars.ind,
                    distribution[vars.i].amountInvested,
                    false
                );
            } else {
                brInfo = ownerBroker[id];
                vars.ind = findBid(
                    true,
                    id,
                    distribution[vars.i].from,
                    distribution[vars.i].investedToken
                );
                bid = _setNewAmountInvested(
                    id,
                    vars.ind,
                    distribution[vars.i].amountInvested,
                    true
                );
            }

            _transferTokens(
                id,
                distribution[vars.i].amountInvested,
                brInfo.percents,
                distribution[vars.i].investedToken,
                distribution[vars.i].investor,
                brInfo.broker,
                distribution[vars.i].from,
                true
            );
        }

        emit OrderPartialSwapped(id);
    }

    /**
     * for order`s owner, which make swap for one bid
     * it close bid and order
     * @param id uniqe id of order
     * @param orderIndex bid for transfer tokens
     */
    function makeSwapOrderOwner(bytes32 id, uint256 orderIndex)
        external
        override
        nonReentrant
        standartChecking(id)
    {
        OrderInfo memory order = orders[id];
        orders[id].isSwapped = true;

        require(order.owner == _msgSender(), "103");
        require(order.isManual == true, "603");

        IntVars memory vars;
        vars.len = ordersBid[id].length;

        require(vars.len > 0, "605");
        require(orderIndex < vars.len, "606");

        OrdersBidInfo memory bid = ordersBid[id][orderIndex];
        address investor = bid.investor;
        BrokerInfo memory brInfo = ownerBroker[id];

        _transferTokens(
            id,
            bid.amountInvested,
            brInfo.percents,
            bid.investedToken,
            order.owner,
            brInfo.broker,
            investor,
            true
        );

        for (vars.i = 0; vars.i < vars.len; vars.i = vars.i.add(1)) {
            if (vars.i == orderIndex) continue;
            bid = ordersBid[id][vars.i];
            _transferTokens(
                id,
                bid.amountInvested,
                0,
                bid.investedToken,
                bid.investor,
                brInfo.broker,
                address(0),
                false
            );
        }

        vars.len = ordersOwnerBid[id].length;
        brInfo = usersBroker[id];

        for (vars.i = 0; vars.i < vars.len; vars.i = vars.i.add(1)) {
            bid = ordersOwnerBid[id][vars.i];
            _transferTokens(
                id,
                bid.amountInvested,
                brInfo.percents,
                bid.investedToken,
                investor,
                brInfo.broker,
                bid.investor,
                true
            );
        }

        
        emit OrderSwapped(id);
    }

    /**
     * for back, which make partial swap for one bids
     * it does not close bids and order
     * @param id uniqe id of order
     * @param orderIndex bid for transfer tokens
     * @param amount array of amounts to user from owner`s bids
     */
    function makePartialSwapByOwner(
        bytes32 id,
        uint256 orderIndex,
        uint256[] memory amount
    ) external override nonReentrant standartChecking(id) onlyOwner {
        OrderInfo memory order = orders[id];

        require(order.isManual == false, "603");

        IntVars memory vars;

        vars.len = ordersBid[id].length;
        require(orderIndex < vars.len, "606");

        vars.len = ordersOwnerBid[id].length;
        require(amount.length == vars.len, "607");

        OrdersBidInfo memory bid = ordersBid[id][orderIndex];
        address investor = bid.investor;

        BrokerInfo memory brInfo = ownerBroker[id];
        _setNewAmountInvested(id, orderIndex, bid.amountInvested, false);
        _transferTokens(
            id,
            bid.amountInvested,
            brInfo.percents,
            bid.investedToken,
            order.owner,
            brInfo.broker,
            bid.investor,
            true
        );

        brInfo = usersBroker[id];

        for (vars.i = 0; vars.i < vars.len; vars.i = vars.i.add(1)) {
            bid = ordersOwnerBid[id][vars.i];
            _setNewAmountInvested(id, vars.i, amount[vars.i], true);
            _transferTokens(
                id,
                amount[vars.i],
                brInfo.percents,
                bid.investedToken,
                investor,
                brInfo.broker,
                bid.investor,
                true
            );
        }

        emit OrderPartialSwapped(id);
    }

    /**
     * for creating order
     * @param id uniqe id of order
     * @param _token token for order
     * @param _amountOfToken amount for order
     * @param _expirationDate date when order will be closed
     * @param _ownerBroker brokr for owner
     * @param _ownerBrokerPerc percent for broker
     * @param _usersBroker broker for user
     * @param _usersBrokerPerc percent for user broker
     * @param _discount discount
     * @param typeOrder type order sell=2, buy=1
     * @param _isManual for orders owner or back
     */
    function createOrder(
        bytes32 id,
        address _token,
        uint256 _amountOfToken,
        uint256 _expirationDate,
        address _ownerBroker,
        uint256 _ownerBrokerPerc,
        address _usersBroker,
        uint256 _usersBrokerPerc,
        uint16 _discount,
        OrderTypeInfo typeOrder,
        bool _isManual
    ) external override nonReentrant onlyWhenVaultDefined {
        require(orders[id].owner == address(0), "201");
        require(_amountOfToken > 0, "202");
        require(_discount < 1000, "203");
        require(typeOrder != OrderTypeInfo.error, "204");
        require(_expirationDate > block.timestamp, "205");

        orders[id].owner = msg.sender;
        orders[id].token = _token;
        orders[id].amountOfToken = _amountOfToken;
        orders[id].expirationDate = _expirationDate;
        orders[id].discount = _discount;
        orders[id].orderType = typeOrder;
        orders[id].isManual = _isManual;

        if (_ownerBroker != address(0)) {
            require(
                _ownerBrokerPerc > 0 && _ownerBrokerPerc < BROKERS_DENOMINATOR,
                "206"
            );
            ownerBroker[id].broker = _ownerBroker;
            ownerBroker[id].percents = _ownerBrokerPerc;
        }

        if (_usersBroker != address(0)) {
            require(
                _usersBrokerPerc > 0 && _usersBrokerPerc < BROKERS_DENOMINATOR,
                "207"
            );
            usersBroker[id].broker = _usersBroker;
            usersBroker[id].percents = _usersBrokerPerc;
        }

        emit OrderCreated(
            id,
            msg.sender,
            _token,
            _amountOfToken,
            _expirationDate,
            _discount,
            typeOrder,
            _isManual
        );
    }

    /**
     * create bids
     * @param id id of order
     * @param token token for bid
     * @param amount amount of tokens
     */
    function orderDeposit(
        bytes32 id,
        address token,
        uint256 amount
    )
        external
        payable
        override
        nonReentrant
        onlyWhenVaultDefined
        standartChecking(id)
    {
        if (token == address(0)) {
            require(msg.value == amount, "304");
            address(vault).transfer(msg.value);
        } else {
            require(msg.value == 0, "305");
            uint256 allowance = IERC20(token).allowance(
                msg.sender,
                address(this)
            );
            require(amount <= allowance, "306");
            TransferHelper.safeTransferFrom(token, msg.sender, address(vault), amount);
        }
        if (orders[id].orderType == OrderTypeInfo.buyType)
            _buyOrderDeposit(id, token, msg.sender, amount);
        else if (orders[id].orderType == OrderTypeInfo.sellType)
            _sellOrderDeposit(id, token, msg.sender, amount);
    }

    /**
     * close order
     * @param id id of order
     */
    function cancel(bytes32 id)
        external
        override
        nonReentrant
        onlyWhenVaultDefined
        onlyWhenOrderExists(id)
    {
        require(orders[id].isCancelled == false, "401");
        require(orders[id].isSwapped == false, "402");

        address caller = _msgSender();
        require(caller == orders[id].owner || caller == owner(), "403");

        _cancel(id);

        emit OrderCancelled(id);
    }

    /**
     * close bid
     * @param id will be owner of order
     * @param bidIndex index of bid
     */
    function cancelBid(bytes32 id, uint256 bidIndex)
        external
        override
        nonReentrant
        onlyWhenVaultDefined
        onlyWhenOrderExists(id)
    {
        uint256 len;
        OrdersBidInfo memory bidRead;
        OrdersBidInfo[] storage bidArrWrite;
        address sender = _msgSender();

        if (orders[id].owner == sender) bidArrWrite = ordersOwnerBid[id];
        else bidArrWrite = ordersBid[id];

        bidRead = bidArrWrite[bidIndex];
        len = bidArrWrite.length;

        require(bidIndex < len, "701");
        require(bidRead.investor == sender, "702");

        vault.withdraw(
            bidRead.investedToken,
            bidRead.investor,
            bidRead.amountInvested
        );

        if (bidIndex < len - 1) bidArrWrite[bidIndex] = bidArrWrite[len - 1];

        bidArrWrite.pop();
    }

    /**
     * cange amount tokens in bid
     * @param id will be owner of order
     * @param bidIndex index of bid
     * @param newValue of tokens
     */
    function changeBid(
        bytes32 id,
        uint256 bidIndex,
        uint256 newValue
    ) external nonReentrant onlyWhenVaultDefined onlyWhenOrderExists(id) {
        require(newValue > 0, "801");

        uint256 len;
        OrdersBidInfo memory bidRead;
        OrdersBidInfo[] storage bidArrWrite;
        address sender = _msgSender();

        if (orders[id].owner == sender) bidArrWrite = ordersOwnerBid[id];
        else bidArrWrite = ordersBid[id];

        bidRead = bidArrWrite[bidIndex];
        len = bidArrWrite.length;

        require(bidIndex < len, "802");
        require(bidRead.investor == sender, "803");
        require(bidRead.amountInvested != newValue, "804");

        if (bidRead.amountInvested < newValue) {
            TransferHelper.safeTransferFrom(bidRead.investedToken, sender, address(vault), newValue.sub(bidRead.amountInvested));
            bidArrWrite[bidIndex].amountInvested = newValue;
        } else if (bidRead.amountInvested > newValue) {
            vault.withdraw(
                bidRead.investedToken,
                bidRead.investor,
                bidRead.amountInvested.sub(newValue)
            );
            bidArrWrite[bidIndex].amountInvested = newValue;
        }
    }

    /**
     * @param _vault contract of vault
     */
    function setVault(Vault _vault) external onlyOwner {
        vault = _vault;
    }

    /**
     * set new date for closing order
     * @param id of order
     * @param newExpirationDate new date
     */
    function setNewExpirationDate(bytes32 id, uint256 newExpirationDate)
        external
        onlyOrderOwner(id)
        onlyWhenOrderExists(id)
    {
        require(newExpirationDate > block.timestamp, "205");
        orders[id].expirationDate = newExpirationDate;
    }

    /**
     * set new discount for order
     * @param id of order
     * @param newDiscount new date
     */
    function setDiscount(bytes32 id, uint16 newDiscount)
        external
        onlyOrderOwner(id)
        onlyWhenOrderExists(id)
    {
        orders[id].discount = newDiscount;
    }

    /**
     * set new amount of tokens in order
     * @param id of order
     * @param newAmountOfToken new amount
     */
    function setAmountOfToken(bytes32 id, uint256 newAmountOfToken)
        external
        onlyOrderOwner(id)
        onlyWhenOrderExists(id)
    {
        orders[id].amountOfToken = newAmountOfToken;
    }

    /**
     * add token to white list
     * @param newToken address of token
     */
    function addWhiteList(address newToken) external onlyOwner {
        isAddressInWhiteList[newToken] = true;
    }

    /**
     * delete token from white list
     * @param tokenToDelete address of token
     */
    function deleteFromWhiteList(address tokenToDelete) external onlyOwner {
        isAddressInWhiteList[tokenToDelete] = false;
    }

    /**
     * create key for new order
     * @param owner will be owner of order
     */
    function createKey(address owner) external view returns (bytes32 result) {
        uint256 creationTime = block.timestamp;
        result = 0x0000000000000000000000000000000000000000000000000000000000000000;
        assembly {
            result := or(result, mul(owner, 0x1000000000000000000000000))
            result := or(result, and(creationTime, 0xffffffffffffffffffffffff))
        }
    }

    function ordersBidLen(bytes32 id) external view returns (uint256) {
        return ordersBid[id].length;
    }

    /**
     * send tokens from the vault if noone took it
     * @param id of order
     * @param investor investor of bid
     * @param to address where to send
     * @param bidIndex index of bid
     */
    function emergencyWithdraw(bytes32 id, address investor, address to, uint256 bidIndex) external onlyOwner nonReentrant {
        require(investor != address(0) && to != address(0), ' investor is address(0)');
        
        OrdersBidInfo[] storage bidArrWrite;

        if (orders[id].owner == investor) bidArrWrite = ordersOwnerBid[id];
        else bidArrWrite = ordersBid[id];
        
        vault.withdraw(bidArrWrite[bidIndex].investedToken, to, bidArrWrite[bidIndex].amountInvested);
        bidArrWrite[bidIndex].amountInvested = 0;
    }

    // public functions
    /**
     * find bid
     * @param id  of order
     * @param owner find for investor or owner
     * @param investor investor
     * @param toFind what needs to be found
     */
    function findBid(
        bool owner,
        bytes32 id,
        address investor,
        address toFind
    ) public view returns (uint256 i) {
        OrdersBidInfo[] memory array;
        if (owner) array = ordersOwnerBid[id];
        else array = ordersBid[id];
        i = _findBid(array, investor, toFind, array.length);
        require(array.length > i, "902");
    }

    /**
     * get investors for order
     * @param id  of order
     */
    function getInvestors(bytes32 id)
        public
        view
        returns (address[] memory investors)
    {
        OrdersBidInfo[] storage bids = ordersBid[id];
        uint256 len = bids.length;
        investors = new address[](len);
        uint256 count = 0;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            uint256 ind = _findAddress(investors, bids[i].investor, count);
            require(ind <= count, "MarsBaseOtc: Internal error getInvestors");
            if (ind == count) {
                investors[count] = bids[i].investor;
                count = count.add(1);
            }
        }
        uint256 delta = len.sub(count);
        if (delta > 0) {
            // decrease len of arrays tokens and amount
            // https://ethereum.stackexchange.com/questions/51891/how-to-pop-from-decrease-the-length-of-a-memory-array-in-solidity
            assembly {
                mstore(investors, sub(mload(investors), delta))
            }
        }
    }

    /**
     * get investments from owner for order
     * @param id of order
     */
    function getOrderOwnerInvestments(bytes32 id)
        public
        view
        returns (address[] memory tokens, uint256[] memory amount)
    {
        return _getUserInvestments(ordersOwnerBid[id], orders[id].owner);
    }

    /**
     * get investments from user for order
     * @param id of order
     */
    function getOrderUserInvestments(bytes32 id, address user)
        public
        view
        returns (address[] memory tokens, uint256[] memory amount)
    {
        return _getUserInvestments(ordersBid[id], user);
    }

    // private functions
    function _setNewAmountInvested(
        bytes32 id,
        uint256 orderIndex,
        uint256 amount,
        bool owner
    ) private returns (OrdersBidInfo memory bid) {
        if (owner) {
            bid = ordersOwnerBid[id][orderIndex];
            require(bid.amountInvested >= amount, "903");
            ordersOwnerBid[id][orderIndex].amountInvested =
                bid.amountInvested -
                amount;
        } else {
            bid = ordersBid[id][orderIndex];
            require(bid.amountInvested >= amount, "903");
            ordersBid[id][orderIndex].amountInvested =
                bid.amountInvested -
                amount;
        }
        return bid;
    }

    function _findAddress(
        address[] memory array,
        address toFind,
        uint256 len
    ) private pure returns (uint256 i) {
        require(array.length >= len, "MarsBaseOtc: Wrong len argument");
        for (i = 0; i < len; i = i.add(1)) {
            if (array[i] == toFind) return i;
        }
    }

    function _buyOrderDeposit(
        bytes32 id,
        address token,
        address investor,
        uint256 amount
    ) private {
        OrdersBidInfo memory ownersBid = OrdersBidInfo({
            investor: investor,
            investedToken: token,
            amountInvested: amount,
            from: address(0)
        });

        if (investor == orders[id].owner) {
            require(isAddressInWhiteList[token] == true, "308");
            ordersOwnerBid[id].push(ownersBid);
        } else {
            require(token == orders[id].token, "309");
            ordersBid[id].push(ownersBid);
        }

        emit BuyOrderDeposit(id, token, investor, amount);
    }

    function _sellOrderDeposit(
        bytes32 id,
        address token,
        address investor,
        uint256 amount
    ) private {
        OrdersBidInfo memory ownersBid = OrdersBidInfo({
            investor: investor,
            investedToken: token,
            amountInvested: amount,
            from: address(0)
        });

        if (investor == orders[id].owner) {
            require(token == orders[id].token, "310");
            ordersOwnerBid[id].push(ownersBid);
        } else {
            require(isAddressInWhiteList[token] == true, "311");
            require(token != orders[id].token, "310");
            ordersBid[id].push(ownersBid);
        }

        emit SellOrderDeposit(id, token, investor, amount);
    }

    function _cancel(bytes32 id)
        private
        onlyWhenVaultDefined
        onlyWhenOrderExists(id)
    {
        address[] memory tokens;
        uint256[] memory investments;
        (tokens, investments) = _getUserInvestments(
            ordersOwnerBid[id],
            orders[id].owner
        );
        uint256 len = tokens.length;
        uint256 i;
        for (i = 0; i < len; i = i.add(1)) {
            vault.withdraw(tokens[i], orders[id].owner, investments[i]);
        }

        address[] memory investors = getInvestors(id);
        len = investors.length;
        uint256 len2;
        uint256 j;
        for (i = 0; i < len; i = i.add(1)) {
            (tokens, investments) = _getUserInvestments(
                ordersBid[id],
                investors[i]
            );
            len2 = tokens.length;
            for (j = 0; j < len2; j = j.add(1)) {
                vault.withdraw(tokens[j], investors[i], investments[j]);
            }
        }

        orders[id].isCancelled = true;
    }

    function _getUserInvestments(OrdersBidInfo[] storage bids, address user)
        private
        view
        returns (address[] memory tokens, uint256[] memory amount)
    {
        uint256 len = bids.length;
        tokens = new address[](len);
        amount = new uint256[](len);
        uint256 count = 0;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            if (user == address(0) || bids[i].investor == user) {
                uint256 ind = _findAddress(
                    tokens,
                    bids[i].investedToken,
                    count
                );
                if (ind < count)
                    amount[ind] = amount[ind].add(bids[i].amountInvested);
                else {
                    tokens[count] = bids[i].investedToken;
                    amount[count] = bids[i].amountInvested;
                    count = count.add(1);
                }
            }
        }
        uint256 delta = len.sub(count);
        if (delta > 0) {
            // decrease len of arrays tokens and amount
            // https://ethereum.stackexchange.com/questions/51891/how-to-pop-from-decrease-the-length-of-a-memory-array-in-solidity
            assembly {
                mstore(tokens, sub(mload(tokens), delta))
            }
            assembly {
                mstore(amount, sub(mload(amount), delta))
            }
        }
    }

    function _findBid(
        OrdersBidInfo[] memory array,
        address investor,
        address toFind,
        uint256 len
    ) private pure returns (uint256 i) {
        for (i = 0; i < len; i = i.add(1)) {
            if (
                array[i].investedToken == toFind &&
                array[i].investor == investor
            ) return i;
        }
    }

    function _transferTokens(
        bytes32 id,
        uint256 amountInvested,
        uint256 percents,
        address investedToken,
        address investor,
        address broker,
        address from,
        bool forTwo
    ) private {
        if (forTwo) {
            IntVars memory vars;

            vars.toBroker = amountInvested.mul(percents).div(
                BROKERS_DENOMINATOR
            );
            vars.toUser = amountInvested.sub(vars.toBroker);

            vault.withdrawForTwo(
                investedToken,
                investor,
                vars.toUser,
                broker,
                vars.toBroker
            );

            OrderInfo memory order = orders[id];

            if (
                order.token == investedToken &&
                ((order.orderType == OrderTypeInfo.buyType &&
                    order.owner == investor) ||
                    (order.orderType == OrderTypeInfo.sellType &&
                        order.owner == from))
            ) {
                if (
                    order.amountOfToken <= amountInvested &&
                    orders[id].isSwapped == false
                ) {
                    orders[id].isSwapped = true;
                    orders[id].amountOfToken = 0;
                } else {
                    orders[id].amountOfToken =
                        order.amountOfToken -
                        amountInvested;
                }
            }
        } else vault.withdraw(investedToken, investor, amountInvested);
    }

    function _checkZeroBalance(uint256 len, uint256[] memory array)
        private
        pure
    {
        for (uint256 i = 0; i < len; i = i.add(1)) {
            require(array[i] == 0, "512");
        }
    }

    function _ifAddressExists(bytes32 id, address investor)
        private
        view
        returns (bool check)
    {
        check = false;
        OrderInfo memory order = orders[id];
        OrdersBidInfo[] memory array;
        if (investor == order.owner) array = ordersOwnerBid[id];
        else array = ordersBid[id];

        for (uint256 i = 0; i < array.length && !check; i = i.add(1)) {
            if (array[i].investor == investor) check = true;
        }
    }

    //test functions
    function getLenght(bytes32 _id, bool owner) public view returns (uint256) {
        if (owner) return ordersOwnerBid[_id].length;
        return ordersBid[_id].length;
    }

    function getOrdersOwnerBids(bytes32 _id)
        public
        view
        returns (OrdersBidInfo[] memory)
    {
        return ordersOwnerBid[_id];
    }

    function getOrdersOwnerBid(bytes32 _id, uint256 i)
        public
        view
        returns (OrdersBidInfo memory bid)
    {
        return ordersOwnerBid[_id][i];
    }

    function getOrdersUserBid(bytes32 _id, uint256 i)
        public
        view
        returns (OrdersBidInfo memory bid)
    {
        return ordersBid[_id][i];
    }
}
