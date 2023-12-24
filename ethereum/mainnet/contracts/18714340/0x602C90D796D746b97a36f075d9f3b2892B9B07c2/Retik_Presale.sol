//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
        if (returndata.length > 0) {
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface Aggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract Retik_Presale is ReentrancyGuard, Ownable {
    uint256 public overalllRaised;
    uint256 public presaleId;
    uint256 public USDT_MULTIPLIER;
    uint256 public ETH_MULTIPLIER;
    address public fundReceiver;
    uint256 public uniqueBuyers;

    struct PresaleData {
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256 nextStagePrice;
        uint256 Sold;
        uint256 tokensToSell;
        uint256 UsdtHardcap;
        uint256 amountRaised;
        bool Active;
        bool isEnableClaim;
    }

    struct VestingData {
        uint256 vestingStartTime;
        uint256 initialClaimPercent;
        uint256 vestingTime;
        uint256 vestingPercentage;
        uint256 totalClaimCycles;
    }

    struct UserData {
        uint256 investedAmount;
        uint256 claimAt;
        uint256 claimAbleAmount;
        uint256 claimedVestingAmount;
        uint256 claimedAmount;
        uint256 claimCount;
        uint256 activePercentAmount;
    }

    IERC20Metadata public USDTInterface;
    IERC20Metadata public USDCInterface;
    Aggregator internal aggregatorInterface;

    mapping(uint256 => bool) public paused;
    mapping(uint256 => PresaleData) public presale;
    mapping(uint256 => VestingData) public vesting;
    mapping(address => mapping(uint256 => UserData)) public userClaimData;
    mapping(address => bool) public isExcludeMinToken;
    mapping(address => bool) public isBlackList;
    mapping(address => bool) public isExist;

    uint256 public MinTokenTobuy;
    uint256 public currentSale;
    address public SaleToken;

    event PresaleCreated(
        uint256 indexed _id,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime
    );

    event PresaleUpdated(
        bytes32 indexed key,
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );

    event TokensBought(
        address indexed user,
        uint256 indexed id,
        address indexed purchaseToken,
        uint256 tokensBought,
        uint256 amountPaid,
        uint256 timestamp
    );

    event TokensClaimed(
        address indexed user,
        uint256 indexed id,
        uint256 amount,
        uint256 timestamp
    );

    event PresaleTokenAddressUpdated(
        address indexed prevValue,
        address indexed newValue,
        uint256 timestamp
    );

    event PresalePaused(uint256 indexed id, uint256 timestamp);
    event PresaleUnpaused(uint256 indexed id, uint256 timestamp);

    constructor(
        address _oracle,
        address _usdt,
        address _usdc,
        address _SaleToken,
        uint256 _MinTokenTobuy
    ) {
        aggregatorInterface = Aggregator(_oracle);
        SaleToken = _SaleToken;
        MinTokenTobuy = _MinTokenTobuy;
        USDTInterface = IERC20Metadata(_usdt);
        USDCInterface = IERC20Metadata(_usdc);
        ETH_MULTIPLIER = (10**18);
        USDT_MULTIPLIER = (10**6);
        fundReceiver = msg.sender;
    }

    function createPresale(
        uint256 _price,
        uint256 _nextStagePrice,
        uint256 _tokensToSell,
        uint256 _UsdtHardcap
    ) external onlyOwner {
        require(_price > 0, "Zero price");
        require(_tokensToSell > 0, "Zero tokens to sell");

        presaleId++;

        presale[presaleId] = PresaleData(
            0,
            0,
            _price,
            _nextStagePrice,
            0,
            _tokensToSell,
            _UsdtHardcap,
            0,
            false,
            false
        );

        emit PresaleCreated(presaleId, _tokensToSell, 0, 0);
    }

    function setPresaleStage(uint256 _id) public onlyOwner {
        require(presale[_id].tokensToSell > 0, "Presale don't exist");
        if (currentSale != 0) {
            presale[currentSale].endTime = block.timestamp;
            presale[currentSale].Active = false;
        }
        presale[_id].startTime = block.timestamp;
        presale[_id].Active = true;
        currentSale = _id;
    }

    function setPresaleVesting(
        uint256[] memory _id,
        uint256[] memory vestingStartTime,
        uint256[] memory _initialClaimPercent,
        uint256[] memory _vestingTime,
        uint256[] memory _vestingPercentage
    ) public onlyOwner {
        for (uint256 i = 0; i < _id.length; i++) {
            vesting[_id[i]] = VestingData(
                vestingStartTime[i],
                _initialClaimPercent[i],
                _vestingTime[i],
                _vestingPercentage[i],
                (1000 - _initialClaimPercent[i]) / _vestingPercentage[i]
            );
        }
    }

    function updatePresaleVesting(
        uint256 _id,
        uint256 _vestingStartTime,
        uint256 _initialClaimPercent,
        uint256 _vestingTime,
        uint256 _vestingPercentage
    ) public onlyOwner {
        vesting[_id].vestingStartTime = _vestingStartTime;
        vesting[_id].initialClaimPercent = _initialClaimPercent;
        vesting[_id].vestingTime = _vestingTime;
        vesting[_id].vestingPercentage = _vestingPercentage;
        vesting[_id].totalClaimCycles =
            (100 - _initialClaimPercent) /
            _vestingPercentage;
    }

    uint256 initialClaimPercent;
    uint256 vestingTime;
    uint256 vestingPercentage;
    uint256 totalClaimCycles;

    function enableClaim(uint256 _id, bool _status) public onlyOwner {
        presale[_id].isEnableClaim = _status;
    }

    function updatePresale(
        uint256 _id,
        uint256 _price,
        uint256 _nextStagePrice,
        uint256 _tokensToSell,
        uint256 _Hardcap,
        bool isclaimAble
    ) external onlyOwner {
        require(_price > 0, "Zero price");
        require(_tokensToSell > 0, "Zero tokens to sell");
        require(_Hardcap > 0, "Zero harcap");
        presale[_id].price = _price;
        presale[_id].nextStagePrice = _nextStagePrice;
        presale[_id].tokensToSell = _tokensToSell;
        presale[_id].UsdtHardcap = _Hardcap;
        presale[_id].isEnableClaim = isclaimAble;
    }

    function changeFundWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Invalid parameters");
        fundReceiver = _wallet;
    }

    function changeUSDTToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero token address");
        USDTInterface = IERC20Metadata(_newAddress);
    }

    function changeUSDCToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero token address");
        USDCInterface = IERC20Metadata(_newAddress);
    }

    function pausePresale(uint256 _id) external checkPresaleId(_id) onlyOwner {
        require(!paused[_id], "Already paused");
        paused[_id] = true;
        emit PresalePaused(_id, block.timestamp);
    }

    function unPausePresale(uint256 _id)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        require(paused[_id], "Not paused");
        paused[_id] = false;
        emit PresaleUnpaused(_id, block.timestamp);
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        price = (price * (10**10));
        return uint256(price);
    }

    modifier checkPresaleId(uint256 _id) {
        require(_id > 0 && _id == currentSale, "Invalid presale id");
        _;
    }

    modifier checkSaleState(uint256 _id, uint256 amount) {
        require(presale[_id].Active == true, "preSAle not Active");
        require(
            amount > 0 &&
                amount <= presale[_id].tokensToSell - presale[_id].Sold,
            "Invalid sale amount"
        );
        _;
    }

    function ExcludeAccouctFromMinBuy(address _user, bool _status)
        external
        onlyOwner
    {
        isExcludeMinToken[_user] = _status;
    }

    function buyWithUSDT(uint256 usdAmount)
        external
        checkPresaleId(currentSale)
        checkSaleState(currentSale, usdtToTokens(currentSale, usdAmount))
        nonReentrant
        returns (bool)
    {
        require(!paused[currentSale], "Presale paused");
        require(
            presale[currentSale].Active == true,
            "Presale is not active yet"
        );
        require(!isBlackList[msg.sender], "Account is blackListed");
        require(
            presale[currentSale].amountRaised + usdAmount <=
                presale[currentSale].UsdtHardcap,
            "Amount should be less than leftHardcap"
        );
        if (!isExist[msg.sender]) {
            isExist[msg.sender] = true;
            uniqueBuyers++;
        }
        uint256 tokens = usdtToTokens(currentSale, usdAmount);
        presale[currentSale].Sold += tokens;
        presale[currentSale].amountRaised += usdAmount;
        overalllRaised += usdAmount;

        if (isExcludeMinToken[msg.sender] == false) {
            require(tokens >= MinTokenTobuy, "Less than min amount");
        }
        if (userClaimData[_msgSender()][currentSale].claimAbleAmount > 0) {
            userClaimData[_msgSender()][currentSale].claimAbleAmount += tokens;
            userClaimData[_msgSender()][currentSale].investedAmount += usdAmount;
        } else {
            userClaimData[_msgSender()][currentSale] = UserData(
                usdAmount,
                0,
                tokens,
                0,
                0,
                0,
                0
            );
        }

        uint256 ourAllowance = USDTInterface.allowance(
            _msgSender(),
            address(this)
        );
        require(usdAmount <= ourAllowance, "Make sure to add enough allowance");
        (bool success, ) = address(USDTInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                fundReceiver,
                usdAmount
            )
        );
        require(success, "Token payment failed");
        emit TokensBought(
            _msgSender(),
            currentSale,
            address(USDTInterface),
            tokens,
            usdAmount,
            block.timestamp
        );
        return true;
    }

    function changeClaimAddress(address _oldAddress, address _newWallet)
        public
        onlyOwner
    {
        for (uint256 i = 1; i < presaleId; i++) {
            require(isExist[_oldAddress], "User not a participant");
            userClaimData[_newWallet][i].claimAbleAmount = userClaimData[
                _oldAddress
            ][i].claimAbleAmount;
            userClaimData[_oldAddress][i].claimAbleAmount = 0;
        }
        isExist[_oldAddress] = false;
        isExist[_newWallet] = true;
    }

    function blackListUser(address _user, bool _value) public onlyOwner {
        isBlackList[_user] = _value;
    }

    function buyWithUSDC(uint256 usdcAmount)
        external
        checkPresaleId(currentSale)
        checkSaleState(currentSale, usdtToTokens(currentSale, usdcAmount))
        nonReentrant
        returns (bool)
    {
        require(!paused[currentSale], "Presale paused");
        require(
            presale[currentSale].Active == true,
            "Presale is not active yet"
        );
        require(
            presale[currentSale].amountRaised + usdcAmount <=
                presale[currentSale].UsdtHardcap,
            "Amount should be less than leftHardcap"
        );
        require(!isBlackList[msg.sender], "Account is blackListed");
        if (!isExist[msg.sender]) {
            isExist[msg.sender] = true;
            uniqueBuyers++;
        }
        uint256 tokens = usdtToTokens(currentSale, usdcAmount);
        presale[currentSale].Sold += tokens;
        presale[currentSale].amountRaised += usdcAmount;
        overalllRaised += usdcAmount;

        if (isExcludeMinToken[msg.sender] == false) {
            require(tokens >= MinTokenTobuy, "Less than min amount");
        }
        if (userClaimData[_msgSender()][currentSale].claimAbleAmount > 0) {
            userClaimData[_msgSender()][currentSale].claimAbleAmount += tokens;
            userClaimData[_msgSender()][currentSale].investedAmount += usdcAmount;
        } else {
            userClaimData[_msgSender()][currentSale] = UserData(
                usdcAmount,
                0,
                tokens,
                0,
                0,
                0,
                0
            );
            require(isExist[_msgSender()], "User not a participant");
        }

        uint256 ourAllowance = USDTInterface.allowance(
            _msgSender(),
            address(this)
        );
        require(
            usdcAmount <= ourAllowance,
            "Make sure to add enough allowance"
        );
        (bool success, ) = address(USDCInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                fundReceiver,
                usdcAmount
            )
        );
        require(success, "Token payment failed");
        emit TokensBought(
            _msgSender(),
            currentSale,
            address(USDTInterface),
            tokens,
            usdcAmount,
            block.timestamp
        );
        return true;
    }

    function buyWithEth()
        external
        payable
        checkPresaleId(currentSale)
        checkSaleState(currentSale, ethToTokens(currentSale, msg.value))
        nonReentrant
        returns (bool)
    {
        uint256 usdAmount = (msg.value * getLatestPrice() * USDT_MULTIPLIER) /
            (ETH_MULTIPLIER * ETH_MULTIPLIER);
        require(
            presale[currentSale].amountRaised + usdAmount <=
                presale[currentSale].UsdtHardcap,
            "Amount should be less than leftHardcap"
        );
        require(!isBlackList[msg.sender], "Account is blackListed");
        require(!paused[currentSale], "Presale paused");
        require(
            presale[currentSale].Active == true,
            "Presale is not active yet"
        );
        if (!isExist[msg.sender]) {
            isExist[msg.sender] = true;
            uniqueBuyers++;
        }

        uint256 tokens = usdtToTokens(currentSale, usdAmount);
        if (isExcludeMinToken[msg.sender] == false) {
            require(tokens >= MinTokenTobuy, "Insufficient amount!");
        }
        presale[currentSale].Sold += tokens;
        presale[currentSale].amountRaised += usdAmount;
        overalllRaised += usdAmount;

        if (userClaimData[_msgSender()][currentSale].claimAbleAmount > 0) {
            userClaimData[_msgSender()][currentSale].claimAbleAmount += tokens;
            userClaimData[_msgSender()][currentSale].investedAmount += usdAmount;
        } else {
            userClaimData[_msgSender()][currentSale] = UserData(
                usdAmount,
                0, // Last claimed at
                tokens, // total tokens to be claimed
                0, // vesting claimed amount
                0, // claimed amount
                0, // claim count
                0 // vesting percent
            );
        }

        sendValue(payable(fundReceiver), msg.value);
        emit TokensBought(
            _msgSender(),
            currentSale,
            address(0),
            tokens,
            msg.value,
            block.timestamp
        );
        return true;
    }

    function ethBuyHelper(uint256 _id, uint256 amount)
        external
        view
        returns (uint256 ethAmount)
    {
        uint256 usdPrice = (amount * presale[_id].price);
        ethAmount =
            (usdPrice * ETH_MULTIPLIER) /
            (getLatestPrice() * 10**IERC20Metadata(SaleToken).decimals());
    }

    function usdtBuyHelper(uint256 _id, uint256 amount)
        external
        view
        returns (uint256 usdPrice)
    {
        usdPrice =
            (amount * presale[_id].price) /
            10**IERC20Metadata(SaleToken).decimals();
    }

    function ethToTokens(uint256 _id, uint256 amount)
        public
        view
        returns (uint256 _tokens)
    {
        uint256 usdAmount = (amount * getLatestPrice() * USDT_MULTIPLIER) /
            (ETH_MULTIPLIER * ETH_MULTIPLIER);
        _tokens = usdtToTokens(_id, usdAmount);
    }

    function usdtToTokens(uint256 _id, uint256 amount)
        public
        view
        returns (uint256 _tokens)
    {
        _tokens = (amount * presale[_id].price) / USDT_MULTIPLIER;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    function claimableAmount(address user, uint256 _id)
        public
        view
        returns (uint256)
    {
        UserData memory _user = userClaimData[user][_id];

        require(_user.claimAbleAmount > 0, "Nothing to claim");
        uint256 amount = _user.claimAbleAmount;
        require(amount > 0, "Already claimed");
        return amount;
    }

    function claimAmount(uint256 _id) public returns (bool) {
        require(isExist[_msgSender()], "User not a participant");
        uint256 amount = claimableAmount(msg.sender, _id);
        require(amount > 0, "No claimable amount");
        require(!isBlackList[msg.sender], "Account is blackListed");
        require(SaleToken != address(0), "Presale token address not set");
        require(
            amount <= IERC20(SaleToken).balanceOf(address(this)),
            "Not enough tokens in the contract"
        );
        require((presale[_id].isEnableClaim == true), "Claim is not enable");
        uint256 transferAmount;
        if (userClaimData[msg.sender][_id].claimCount == 0) {
            transferAmount =
                (amount * (vesting[_id].initialClaimPercent)) /
                1000;
            userClaimData[msg.sender][_id].activePercentAmount =
                (amount * vesting[_id].vestingPercentage) /
                1000;
            bool status = IERC20(SaleToken).transfer(
                msg.sender,
                transferAmount
            );
            require(status, "Token transfer failed");
            userClaimData[msg.sender][_id].claimAbleAmount -= transferAmount;
            userClaimData[msg.sender][_id].claimedAmount += transferAmount;
            userClaimData[msg.sender][_id].claimCount++;
        } else if (
            userClaimData[msg.sender][_id].claimAbleAmount >
            userClaimData[msg.sender][_id].activePercentAmount
        ) {
            uint256 duration = block.timestamp - vesting[_id].vestingStartTime;
            uint256 multiplier = duration / vesting[_id].vestingTime;
            if (multiplier > vesting[_id].totalClaimCycles) {
                multiplier = vesting[_id].totalClaimCycles;
            }
            uint256 _amount = multiplier *
                userClaimData[msg.sender][_id].activePercentAmount;
            transferAmount =
                _amount -
                userClaimData[msg.sender][_id].claimedVestingAmount;
            require(transferAmount > 0, "Please wait till next claim");
            bool status = IERC20(SaleToken).transfer(
                msg.sender,
                transferAmount
            );
            require(status, "Token transfer failed");
            userClaimData[msg.sender][_id].claimAbleAmount -= transferAmount;
            userClaimData[msg.sender][_id]
                .claimedVestingAmount += transferAmount;
            userClaimData[msg.sender][_id].claimedAmount += transferAmount;
            userClaimData[msg.sender][_id].claimCount++;
        } else {
            uint256 duration = block.timestamp - vesting[_id].vestingStartTime;
            uint256 multiplier = duration / vesting[_id].vestingTime;
            if (multiplier > vesting[_id].totalClaimCycles + 1) {
                transferAmount = userClaimData[msg.sender][_id].claimAbleAmount;
                require(transferAmount > 0, "Please wait till next claim");
                bool status = IERC20(SaleToken).transfer(
                    msg.sender,
                    transferAmount
                );
                require(status, "Token transfer failed");
                userClaimData[msg.sender][_id]
                    .claimAbleAmount -= transferAmount;
                userClaimData[msg.sender][_id].claimedAmount += transferAmount;
                userClaimData[msg.sender][_id]
                    .claimedVestingAmount += transferAmount;
                userClaimData[msg.sender][_id].claimCount++;
            } else {
                revert("Wait for next claiim");
            }
        }
        return true;
    }

    function WithdrawTokens(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(fundReceiver, amount);
    }

    function WithdrawContractFunds(uint256 amount) external onlyOwner {
        sendValue(payable(fundReceiver), amount);
    }

    function ChangeTokenToSell(address _token) public onlyOwner {
        SaleToken = _token;
    }

    function EditMinTokenToBuy(uint256 _amount) public onlyOwner {
        MinTokenTobuy = _amount;
    }

    function ChangeOracleAddress(address _oracle) public onlyOwner {
        aggregatorInterface = Aggregator(_oracle);
    }

    function blockStamp() public view returns(uint256) {
        return block.timestamp;
    }
}