// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./CommonCalendar.sol";
import "./SafeMath.sol";

contract CalendarSteward {
    /*
    This smart contract collects patronage from current owner through a Harberger tax model and 
    takes stewardship of the asset token if the patron can't pay anymore.

    Harberger Tax (COST): 
    - Asset is always on sale.
    - You have to have a price set.
    - Tax (Patronage) is paid to maintain ownership.
    */
    using SafeMath for uint256;

    mapping(uint256 => uint256) public price; //  map tokenId to price
    CommonCalendar public assetToken; // ERC721 NFT.
    address public auction;

    mapping(uint256 => uint256) public totalCollected; // all patronage ever collected
    mapping(uint256 => uint256) public currentCollected; 
    mapping(uint256 => uint256) public timeLastCollected;
    mapping(address => uint256) public timeLastCollectedPatron; 
    mapping(address => uint256) public deposit; 
    mapping(address => uint256) public totalPatronOwnedTokenPrice;

    mapping(uint256 => address) public benefactors; 
    mapping(address => uint256) public benefactorFunds;

    mapping(uint256 => address) public currentPatron; 
    mapping(uint256 => mapping(address => bool)) public patrons;
    mapping(uint256 => mapping(address => uint256)) public timeHeld;

    mapping(uint256 => uint256) public timeAcquired;
    mapping(uint256 => uint256) public priceEveryHour;

    // 1200% patronage
    mapping(uint256 => uint256) public patronageNumerator;

    enum StewardState {Foreclosed, Owned}
    mapping(uint256 => StewardState) public state;

    address public admin;
    address public owner;

    //////////////// NEW variables in v2///////////////////
    mapping(uint256 => uint256) public tokenGenerationRate; // we can reuse the patronage denominator

    event Buy(uint256 indexed tokenId, address indexed owner, uint256 price);
    event DayOwner(address owner);
    event PriceChange(uint256 indexed tokenId, uint256 newPrice);
    event Foreclosure(address indexed prevOwner, uint256 foreclosureTime);
    event RemainingDepositUpdate(
        address indexed tokenPatron,
        uint256 remainingDeposit
    );

    event AddToken(
        uint256 indexed tokenId,
        uint256 patronageNumerator
    );
    // QUESTION: in future versions, should these two events (CollectPatronage and CollectLoyalty) be combined into one? - they only ever happen at the same time.
    event CollectPatronage(
        uint256 indexed tokenId,
        address indexed patron,
        uint256 remainingDeposit,
        uint256 amountReceived
    );

    modifier onlyPatron(uint256 tokenId) {
        require(msg.sender == currentPatron[tokenId], "Not patron");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyReceivingBenefactorOrAdmin(uint256 tokenId) {
        require(
            msg.sender == benefactors[tokenId] || msg.sender == admin,
            "Not benefactor or admin"
        );
        _;
    }

    modifier collectPatronage(uint256 tokenId) {
        _collectPatronage(tokenId);
        _;
    }

    modifier collectPatronageAddress(address tokenPatron) {
        _collectPatronagePatron(tokenPatron);
        _;
    }

    constructor(CommonCalendar _assetToken, address _admin) {
        assetToken = (_assetToken);
        admin = _admin;
        owner = msg.sender;
    }

    function setAuction(address _auction) public  {
        require(auction == address(0));
        auction = _auction;
    }

    // Source: https://github.com/provable-things/ethereum-api/blob/master/oraclizeAPI_0.5.sol#L1045
    function uintToStr(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }

        // Determine length of bytes.
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        // get each unit of bytes string.
        bytes memory bstr = new bytes(len);
        while (_i != 0) {
            // ascii codes for digits are 48-57
            bstr[--len] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    function listNewToken(
        address to, uint8 month, uint8 dayOfMonth, uint256 _newPrice, uint256 _deposit, string memory dayName
        ) public payable {
        address payable _benefactor = payable(0x613ea163982868DecEf2D9C1A1cbE23e43186549);
        uint256 _patronageNumerator = 10000000000; // 1%
        assert(_benefactor != address(0));
        uint256 tokenID = assetToken.mintItem(to, month, dayOfMonth);
        benefactors[tokenID] = _benefactor;
        state[tokenID] = StewardState.Foreclosed; 
        patronageNumerator[tokenID] = _patronageNumerator;
        emit AddToken(
            tokenID,
            _patronageNumerator
        );
        if(to != owner) {
            buy(to, tokenID, month, dayOfMonth, _newPrice, _deposit, dayName);   
        }
    }

    // function listNewTokens(
    //     uint256[] memory tokens,
    //     address payable[] memory _benefactors,
    //     uint256[] memory _patronageNumerator
    //     ) public onlyAdmin {
    //     assert(tokens.length == _benefactors.length);
    //     assert(tokens.length == _patronageNumerator.length);

    //     for (uint8 i = 0; i < tokens.length; ++i) {
    //         assert(_benefactors[i] != address(0));
    //         string memory idString = uintToStr(tokens[i]);
    //         string memory tokenUriBase = "https://harberger.test.com/token/";
    //         string memory tokenUri = string(
    //             abi.encodePacked(tokenUriBase, idString)
    //         );
    //         assetToken.mintWithTokenURI(address(this), tokens[i], tokenUri);
    //         benefactors[tokens[i]] = _benefactors[i];
    //         state[tokens[i]] = StewardState.Foreclosed; // TODO: Maybe Implement reverse dutch auction on intial sale or other such mechanisms to avoid the deadloss weight of
    //         patronageNumerator[tokens[i]] = _patronageNumerator[i];
    //         emit AddToken(
    //             tokens[i],
    //             _patronageNumerator[i]
    //         );
    //     }
    // }

    function changeReceivingBenefactor(
        uint256 tokenId,
        address payable _newReceivingBenefactor
    ) public onlyReceivingBenefactorOrAdmin(tokenId) {
        address oldBenfactor = benefactors[tokenId];
        require(
            oldBenfactor != _newReceivingBenefactor,
            "Cannot change to same address"
        );
        benefactors[tokenId] = _newReceivingBenefactor;
        benefactorFunds[_newReceivingBenefactor] = benefactorFunds[_newReceivingBenefactor]
            .add(benefactorFunds[oldBenfactor]);
        benefactorFunds[oldBenfactor] = 0;
    }

    function changeAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }

    /* public view functions */
    function patronageOwed(uint256 tokenId)
        public
        view
        returns (uint256 patronageDue)
    {
        if (timeLastCollected[tokenId] == 0) return 0;

        return
            price[tokenId]
                .mul(block.timestamp.sub(timeLastCollected[tokenId]))
                .mul(patronageNumerator[tokenId])
                .div(1000000000000)
                .div(365 days);
    }

    function patronageOwedWithTimestamp(uint256 tokenId)
        public
        view
        returns (uint256 patronageDue, uint256 timestamp)
    {
        return (patronageOwed(tokenId), block.timestamp);
    }

    // TODO: make a version of this function that is for patronage owed by token rather than by tokenPatron like it is now.
    function patronageOwedByPatron(address tokenPatron)
        public
        view
        returns (uint256 patronageDue)
    {
        if (timeLastCollectedPatron[tokenPatron] == 0) return 0;
        return
            totalPatronOwnedTokenPrice[tokenPatron]
                .mul(block.timestamp.sub(timeLastCollectedPatron[tokenPatron]))
                .div(1000000000000)
                .div(365 days);
    }

    function patronageOwedByPatronWithTimestamp(address tokenPatron)
        public
        view
        returns (uint256 patronageDue, uint256 timestamp)
    {
        return (patronageOwedByPatron(tokenPatron), block.timestamp);
    }

    function foreclosedPatron(address tokenPatron) public view returns (bool) {
        // returns whether it is in foreclosed state or not
        // depending on whether deposit covers patronage due
        // useful helper function when price should be zero, but contract doesn't reflect it yet.
        if (patronageOwedByPatron(tokenPatron) >= deposit[tokenPatron]) {
            return true;
        } else {
            return false;
        }
    }

    function foreclosed(uint256 tokenId) public view returns (bool) {
        // returns whether it is in foreclosed state or not
        // depending on whether deposit covers patronage due
        // useful helper function when price should be zero, but contract doesn't reflect it yet.
        address tokenPatron = currentPatron[tokenId];
        return foreclosedPatron(tokenPatron);
    }

    function depositAbleToWithdraw(address tokenPatron)
        public
        view
        returns (uint256)
    {
        uint256 collection = patronageOwedByPatron(tokenPatron);
        if (collection >= deposit[tokenPatron]) {
            return 0;
        } else {
            return deposit[tokenPatron].sub(collection);
        }
    }

    function foreclosureTimePatron(address tokenPatron)
        public
        view
        returns (uint256)
    {
        // patronage per second
        uint256 pps = totalPatronOwnedTokenPrice[tokenPatron]
            .div(1000000000000)
            .div(365 days);
        return block.timestamp.add(depositAbleToWithdraw(tokenPatron).div(pps)); // zero division if price is zero.
    }

    function foreclosureTime(uint256 tokenId) public view returns (uint256) {
        address tokenPatron = currentPatron[tokenId];
        return foreclosureTimePatron(tokenPatron);
    }

    // TODO:: think of more efficient ways for recipients to collect patronage for lots of tokens at the same time.0
    function _collectPatronage(uint256 tokenId) public {
        // determine patronage to pay
        if (state[tokenId] == StewardState.Owned) {
            address currentOwner = currentPatron[tokenId];
            uint256 previousTokenCollection = timeLastCollected[tokenId];
            uint256 patronageOwedByTokenPatron = patronageOwedByPatron(
                currentOwner
            );
            uint256 collection;

            // it should foreclose and take stewardship
            if (patronageOwedByTokenPatron >= deposit[currentOwner]) {

                    uint256 newTimeLastCollected
                 = timeLastCollectedPatron[currentOwner].add(
                    (
                        (block.timestamp.sub(timeLastCollectedPatron[currentOwner]))
                            .mul(deposit[currentOwner])
                            .div(patronageOwedByTokenPatron)
                    )
                );

                timeLastCollected[tokenId] = newTimeLastCollected;
                timeLastCollectedPatron[currentOwner] = newTimeLastCollected;
                collection = price[tokenId]
                    .mul(newTimeLastCollected.sub(previousTokenCollection))
                    .mul(patronageNumerator[tokenId])
                    .div(1000000000000)
                    .div(365 days);
                deposit[currentOwner] = 0;
                _foreclose(tokenId);
            } else {
                collection = price[tokenId]
                    .mul(block.timestamp.sub(previousTokenCollection))
                    .mul(patronageNumerator[tokenId])
                    .div(1000000000000)
                    .div(365 days);

                timeLastCollected[tokenId] = block.timestamp;
                timeLastCollectedPatron[currentOwner] = block.timestamp;
                currentCollected[tokenId] = currentCollected[tokenId].add(
                    collection
                );
                deposit[currentOwner] = deposit[currentOwner].sub(
                    patronageOwedByTokenPatron
                );
            }
            totalCollected[tokenId] = totalCollected[tokenId].add(collection);
            address benefactor = benefactors[tokenId];
            benefactorFunds[benefactor] = benefactorFunds[benefactor].add(
                collection
            );
            // if foreclosed, tokens are minted and sent to the steward since _foreclose is already called.
            emit CollectPatronage(
                tokenId,
                currentOwner,
                deposit[currentOwner],
                collection
            );
        }
    }

    // This does accounting without transfering any tokens
    function _collectPatronagePatron(address tokenPatron) public {
        uint256 patronageOwedByTokenPatron = patronageOwedByPatron(tokenPatron);
        if (
            patronageOwedByTokenPatron > 0 &&
            patronageOwedByTokenPatron >= deposit[tokenPatron]
        ) {

                uint256 previousCollectionTime
             = timeLastCollectedPatron[tokenPatron];
            // up to when was it actually paid for?
            uint256 newTimeLastCollected = previousCollectionTime.add(
                (
                    (block.timestamp.sub(previousCollectionTime))
                        .mul(deposit[tokenPatron])
                        .div(patronageOwedByTokenPatron)
                )
            );
            timeLastCollectedPatron[tokenPatron] = newTimeLastCollected;
            deposit[tokenPatron] = 0;
        } else {
            timeLastCollectedPatron[tokenPatron] = block.timestamp;
            deposit[tokenPatron] = deposit[tokenPatron].sub(
                patronageOwedByTokenPatron
            );
        }

        emit RemainingDepositUpdate(tokenPatron, deposit[tokenPatron]);
    }

    // note: anyone can deposit
    function depositWei() public payable {
        depositWeiPatron(msg.sender);
    }

    function depositWeiPatron(address patron) public payable {
        require(totalPatronOwnedTokenPrice[patron] > 0, "No tokens owned");
        deposit[patron] = deposit[patron].add(msg.value);
        emit RemainingDepositUpdate(patron, deposit[patron]);
    }

    function buy(
        address to,
        uint256 tokenId,
        uint8 month,
        uint8 dayOfMonth,
        uint256 _newPrice,
        uint256 _deposit,
        string memory _dayName
    )
        public
        payable
        collectPatronage(tokenId)
        collectPatronageAddress(to)
    {
        require(_newPrice > 0, "Price is zero");
        require(_deposit > 0, "Deposit eth amount is zero");
        // uint256 remainingValueForDeposit = depositValue.sub(price[tokenId]);
        // This prevents slipage if someone frontruns this transaction and changes the price unexpectedly.
        // require(
        //     remainingValueForDeposit >= _deposit,
        //     "The deposit available is < what was stated in the transaction"
        // );
        address currentOwner = assetToken.ownerOf(tokenId);
        emit DayOwner(currentOwner);
        address tokenPatron = currentPatron[tokenId];

        if (state[tokenId] == StewardState.Owned) {
            uint256 totalToPayBack = price[tokenId];
            // NOTE: pay back the deposit only if it is the only token the patron owns.
            if (
                totalPatronOwnedTokenPrice[tokenPatron] ==
                price[tokenId].mul(patronageNumerator[tokenId])
            ) {
                totalToPayBack = totalToPayBack.add(deposit[tokenPatron]);
                deposit[tokenPatron] = 0;
            }

            // pay previous owner their price + deposit back.
            address payable payableCurrentPatron = payable(
                tokenPatron
            );
            bool transferSuccess = payableCurrentPatron.send(totalToPayBack);
            if (!transferSuccess) {
                deposit[tokenPatron] = deposit[tokenPatron].add(totalToPayBack);
            }
        } else if (state[tokenId] == StewardState.Foreclosed) {
            state[tokenId] = StewardState.Owned;
            timeLastCollected[tokenId] = block.timestamp;
            timeLastCollectedPatron[to] = block.timestamp;
        }

        deposit[to] = deposit[to].add(_deposit);
        transferAssetTokenTo(
            tokenId,
            currentOwner,
            tokenPatron,
            to,
            _newPrice
        );
        assetToken.setDayName(month, dayOfMonth, _dayName);
        emit Buy(tokenId, to, _newPrice);
    }

    function getDaySellPrice(uint256 tokenId) public view returns (uint256 sellPrice) {
        return price[tokenId];
    }

    function changeDayNamePrice(uint256 tokenId, uint8 _monthNumber, uint8 _dayOfMonth, string memory _dayName, uint256 _newPrice)
        public
        onlyPatron(tokenId)
        collectPatronage(tokenId)
    {
        require(state[tokenId] != StewardState.Foreclosed, "Foreclosed");
        require(_newPrice != 0, "Incorrect Price");

        totalPatronOwnedTokenPrice[msg.sender] = totalPatronOwnedTokenPrice[msg
            .sender]
            .sub(price[tokenId].mul(patronageNumerator[tokenId]))
            .add(_newPrice.mul(patronageNumerator[tokenId])); // Update total price of all owned tokens

        price[tokenId] = _newPrice;
        assetToken.setDayName(_monthNumber, _dayOfMonth, _dayName);
        emit PriceChange(tokenId, price[tokenId]);
    }

    function withdrawDeposit(uint256 _wei)
        public
        collectPatronageAddress(msg.sender)
        returns (uint256)
    {
        _withdrawDeposit(_wei);
    }

    function withdrawBenefactorFunds() public {
        withdrawBenefactorFundsTo(payable(msg.sender));
    }

    function withdrawBenefactorFundsTo(address payable benefactor) public {
        require(benefactorFunds[benefactor] > 0, "No funds available");
        uint256 amountToWithdraw = benefactorFunds[benefactor];
        benefactorFunds[benefactor] = 0;

        bool transferSuccess = benefactor.send(amountToWithdraw);
        if (!transferSuccess) {
            revert("Unable to withdraw benefactor funds");
        }
    }

    function exit() public collectPatronageAddress(msg.sender) {
        _withdrawDeposit(deposit[msg.sender]);
    }

    /* internal */
    function _withdrawDeposit(uint256 _wei) internal {
        // note: can withdraw whole deposit, which puts it in immediate to be foreclosed state.
        require(deposit[msg.sender] >= _wei, "Withdrawing too much");

        deposit[msg.sender] = deposit[msg.sender].sub(_wei);

        // msg.sender == patron
        bool transferSuccess = payable(msg.sender).send(_wei);
        if (!transferSuccess) {
            revert("Unable to withdraw deposit");
        }
    }

    function _foreclose(uint256 tokenId) internal {
        // become steward of assetToken (aka foreclose)
        address currentOwner = assetToken.ownerOf(tokenId);
        address tokenPatron = currentPatron[tokenId];
        transferAssetTokenTo(
            tokenId,
            currentOwner,
            tokenPatron,
            address(this),
            0
        );
        state[tokenId] = StewardState.Foreclosed;
        currentCollected[tokenId] = 0;

        emit Foreclosure(currentOwner, timeLastCollected[tokenId]);
    }

    function transferAssetTokenTo(
        uint256 tokenId,
        address _currentOwner,
        address _currentPatron,
        address _newOwner,
        uint256 _newPrice
    ) internal {
        totalPatronOwnedTokenPrice[_newOwner] = totalPatronOwnedTokenPrice[_newOwner]
            .add(_newPrice.mul(patronageNumerator[tokenId]));
        totalPatronOwnedTokenPrice[_currentPatron] = totalPatronOwnedTokenPrice[_currentPatron]
            .sub(price[tokenId].mul(patronageNumerator[tokenId]));

        // note: it would also tabulate time held in stewardship by smart contract
        timeHeld[tokenId][_currentPatron] = timeHeld[tokenId][_currentPatron]
            .add((timeLastCollected[tokenId].sub(timeAcquired[tokenId])));
        assetToken.transferFrom(_currentOwner, _newOwner, tokenId);
        currentPatron[tokenId] = _newOwner;

        price[tokenId] = _newPrice;
        timeAcquired[tokenId] = block.timestamp;
        patrons[tokenId][_newOwner] = true;
    }
}
