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

contract Red_Ai is ReentrancyGuard, Ownable {
    uint256 public overalllRaised;
    uint256 public presaleId;
    uint256 public USDT_MULTIPLIER;
    uint256 public ETH_MULTIPLIER;
    address public fundReceiver;
    uint256 public uniqueBuyers;
    uint256 public vestingStartTime;
    uint256 public vestingTime;
    uint256 public vestingPercentage;
    uint256 public totalClaimCycles;

    struct PresaleData {
        uint256 price;
        uint256 Sold;
        uint256 tokensToSell;
        uint256 UsdtHardcap;
        uint256 amountRaised;
        bool Active;
        bool isEnableClaim;
    }

    function setVesgingData(
        uint256 _vestingStartTime,
        uint256 _vestingTime,
        uint256 _vestingPercentage,
        uint256 _totalClaimCycles
    ) public onlyOwner {
        vestingStartTime = _vestingStartTime;
        vestingTime = _vestingTime;
        vestingPercentage = _vestingPercentage;
        totalClaimCycles = _totalClaimCycles;
    }

    struct UserData {
        uint256 investedAmount;
        uint256 claimAt;
        uint256 claimAbleAmount;
        uint256 claimedVestingAmount;
        uint256 claimedAmount;
        uint256 claimCount;
        uint256 activePercentAmount;
        uint256 cyclesClaimed;
    }

    IERC20Metadata public USDTInterface;
    Aggregator internal aggregatorInterface;

    mapping(uint256 => bool) public paused;
    mapping(uint256 => PresaleData) public presale;
    mapping(address => mapping(uint256 => UserData)) public userClaimData;
    mapping(address => bool) public isExist;
    address public RedAI;

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

    event PreRedAIAddressUpdated(
        address indexed prevValue,
        address indexed newValue,
        uint256 timestamp
    );

    event PresalePaused(uint256 indexed id, uint256 timestamp);
    event PresaleUnpaused(uint256 indexed id, uint256 timestamp);

    constructor(
        address _oracle,
        address _usdt,
        address _RedAI
    ) {
        aggregatorInterface = Aggregator(_oracle);
        RedAI = _RedAI;
        USDTInterface = IERC20Metadata(_usdt);
        ETH_MULTIPLIER = (10**18);
        USDT_MULTIPLIER = (10**6);
        fundReceiver = 0xAA74ca9e4F4F25B8508Ea45a55C97356bBa80c82;
        vestingStartTime = block.timestamp + 180 days;
        vestingTime = 1 days;
        vestingPercentage = 10;
        totalClaimCycles = 100;
    }

    function createPresale(
        uint256 _price,
        uint256 _tokensToSell,
        uint256 _UsdtHardcap
    ) external onlyOwner {
        require(_price > 0, "Zero price");
        require(_tokensToSell > 0, "Zero tokens to sell");

        presaleId++;

        presale[presaleId] = PresaleData(
            _price,
            0,
            _tokensToSell,
            _UsdtHardcap,
            0,
            false,
            false
        );

        emit PresaleCreated(presaleId, _tokensToSell, 0, 0);
    }

    function setPresaleActive(uint256 _id) public onlyOwner {
        require(presale[_id].tokensToSell > 0, "Presale don't exist");
        presale[_id].Active = true;
    }

    function enableClaim(uint256 _id, bool _status) public onlyOwner {
        presale[_id].isEnableClaim = _status;
    }

    function changeFundWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Invalid parameters");
        fundReceiver = _wallet;
    }

    function changeUSDTToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero token address");
        USDTInterface = IERC20Metadata(_newAddress);
    }

    function pausePresale(uint256 _id) external onlyOwner {
        require(!paused[_id], "Already paused");
        paused[_id] = true;
        emit PresalePaused(_id, block.timestamp);
    }

    function unPausePresale(uint256 _id) external onlyOwner {
        require(paused[_id], "Not paused");
        paused[_id] = false;
        emit PresaleUnpaused(_id, block.timestamp);
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        price = (price * (10**10));
        return uint256(price);
    }

    modifier checkSaleState(uint256 _id, uint256 amount) {
        require(presale[_id].Active == true, "preSle not Active");
        require(
            amount > 0 &&
                amount <= presale[_id].tokensToSell - presale[_id].Sold,
            "Invalid sale amount"
        );
        _;
    }

    function buyWithUSDT(uint256 _id, uint256 usdAmount)
        external
        checkSaleState(_id, usdtToTokens(_id, usdAmount))
        nonReentrant
        returns (bool)
    {
        if (_id == 2) {
            require(
                usdAmount >= 10000 * 10**6,
                "Tokens Should be more than 10000"
            );
        }
        require(!paused[_id], "Presale paused");
        require(presale[_id].Active == true, "Presale is not active yet");
        require(
            presale[_id].amountRaised + usdAmount <= presale[_id].UsdtHardcap,
            "Amount should be less than leftHardcap"
        );
        if (!isExist[msg.sender]) {
            isExist[msg.sender] = true;
            uniqueBuyers++;
        }
        uint256 tokens = usdtToTokens(_id, usdAmount);
        presale[_id].Sold += tokens;
        presale[_id].amountRaised += usdAmount;
        overalllRaised += usdAmount;
        if (userClaimData[_msgSender()][_id].claimAbleAmount > 0) {
            userClaimData[_msgSender()][_id].claimAbleAmount += tokens;
            userClaimData[_msgSender()][_id].investedAmount += usdAmount;
        } else {
            userClaimData[_msgSender()][_id] = UserData(
                usdAmount,
                0,
                tokens,
                0,
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
            _id,
            address(USDTInterface),
            tokens,
            usdAmount,
            block.timestamp
        );
        return true;
    }

    function buyWithEth(uint256 _id)
        external
        payable
        checkSaleState(_id, ethToTokens(_id, msg.value))
        nonReentrant
        returns (bool)
    {
        uint256 usdAmount = (msg.value * getLatestPrice() * USDT_MULTIPLIER) /
            (ETH_MULTIPLIER * ETH_MULTIPLIER);
        if (_id == 2) {
            require(
                usdAmount >= 10000 * 10**6,
                "Tokens Should be more than 10000"
            );
        }
        require(
            presale[_id].amountRaised + usdAmount <= presale[_id].UsdtHardcap,
            "Amount should be less than leftHardcap"
        );
        require(!paused[_id], "Presale paused");
        require(presale[_id].Active == true, "Presale is not active yet");
        if (!isExist[msg.sender]) {
            isExist[msg.sender] = true;
            uniqueBuyers++;
        }

        uint256 tokens = usdtToTokens(_id, usdAmount);
        presale[_id].Sold += tokens;
        presale[_id].amountRaised += usdAmount;
        overalllRaised += usdAmount;

        if (userClaimData[_msgSender()][_id].claimAbleAmount > 0) {
            userClaimData[_msgSender()][_id].claimAbleAmount += tokens;
            userClaimData[_msgSender()][_id].investedAmount += usdAmount;
        } else {
            userClaimData[_msgSender()][_id] = UserData(
                usdAmount,
                0, // Last claimed at
                tokens, // total tokens to be claimed
                0, // vesting claimed amount
                0, // claimed amount
                0, // claim count
                0, // vesting percent
                0 //claimedCycles
            );
        }

        sendValue(payable(fundReceiver), msg.value);
        emit TokensBought(
            _msgSender(),
            _id,
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
            (getLatestPrice() * 10**IERC20Metadata(RedAI).decimals());
    }

    function usdtBuyHelper(uint256 _id, uint256 amount)
        external
        view
        returns (uint256 usdPrice)
    {
        usdPrice =
            (amount * presale[_id].price) /
            10**IERC20Metadata(RedAI).decimals();
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

    function claimPublic() public {
        require(isExist[_msgSender()], "User not a participant");
        require(presale[1].isEnableClaim == true, "Claim is not enable");
        uint256 amount = claimableAmount(msg.sender, 1);
        require(amount > 0, "No claimable amount");
        require(RedAI != address(0), "Presale token address not set");
        require(
            amount <= IERC20(RedAI).balanceOf(address(this)),
            "Not enough tokens in the contract"
        );
        bool status = IERC20(RedAI).transfer(msg.sender, amount);
        require(status, "Token transfer failed");
        userClaimData[msg.sender][1].claimedAmount += amount;
        userClaimData[msg.sender][1].claimAbleAmount -= amount;
    }

    function claimPrivate() public {
        require(isExist[_msgSender()], "User not a participant");
        require(presale[2].isEnableClaim == true, "Claim is not enable");
        uint256 amount = claimableAmount(msg.sender, 2);
        require(amount > 0, "No claimable amount");
        require(RedAI != address(0), "Presale token address not set");
        require(
            amount <= IERC20(RedAI).balanceOf(address(this)),
            "Not enough tokens in the contract"
        );
        uint256 transferAmount;
        require(
            block.timestamp >= vestingStartTime,
            "wait for vesting start time"
        );
        require(
            userClaimData[msg.sender][2].cyclesClaimed < 100,
            "All cycles are claimed"
        );
        if (userClaimData[msg.sender][2].claimCount == 0) {
            userClaimData[msg.sender][2].activePercentAmount =
                (amount * vestingPercentage) /
                1000;
        }
        uint256 duration = block.timestamp - vestingStartTime;
        uint256 multiplier = duration / vestingTime;
        if (multiplier > totalClaimCycles) {
            multiplier = totalClaimCycles;
        }
        uint256 _amount = multiplier *
            userClaimData[msg.sender][2].activePercentAmount;
        transferAmount =
            _amount -
            userClaimData[msg.sender][2].claimedVestingAmount;
        require(transferAmount > 0, "Please wait till claim Time");
        bool status = IERC20(RedAI).transfer(msg.sender, transferAmount);
        require(status, "Token transfer failed");
        userClaimData[msg.sender][2].claimAbleAmount -= transferAmount;
        userClaimData[msg.sender][2].claimedVestingAmount += transferAmount;
        userClaimData[msg.sender][2].claimedAmount += transferAmount;
        userClaimData[msg.sender][2].claimCount++;
    }

    function WithdrawTokens(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(fundReceiver, amount);
    }

    function updatePresale(
        uint256 _id,
        uint256 _price,
        uint256 _tokensToSell,
        uint256 _Hardcap,
        bool isclaimAble
    ) external onlyOwner {
        require(_price > 0, "Zero price");
        require(_tokensToSell > 0, "Zero tokens to sell");
        require(_Hardcap > 0, "Zero harcap");
        presale[_id].price = _price;
        presale[_id].tokensToSell = _tokensToSell;
        presale[_id].UsdtHardcap = _Hardcap;
        presale[_id].isEnableClaim = isclaimAble;
    }

    function WithdrawContractFunds(uint256 amount) external onlyOwner {
        sendValue(payable(fundReceiver), amount);
    }

    function ChangeTokenToSell(address _token) public onlyOwner {
        RedAI = _token;
    }

    function ChangeOracleAddress(address _oracle) public onlyOwner {
        aggregatorInterface = Aggregator(_oracle);
    }

    function blockStamp() public view returns (uint256) {
        return block.timestamp;
    }
}