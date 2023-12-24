/**
 *Submitted for verification at Etherscan.io on 2023-11-24
*/

/**
 *Submitted for verification at Etherscan.io on 2023-11-24
*/
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

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
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

    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
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

    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
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

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
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

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

//SPDX-License-Identifier: MIT

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

contract BtcInuSale is ReentrancyGuard, Ownable {
    IERC20Metadata public USDT;
    Aggregator internal aggregatorInterface;
    uint256 public presaleId;
    uint256 public USDT_MULTIPLIER;
    uint256 public ETH_MULTIPLIER;
    address public fundReceiver;
    address public btcInu;

    struct Presale {
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256 soldTokens;
        uint256 tokensToSell;
        uint256 UsdtHardcap;
        uint256 amountRaised;
        bool Active;
    }

    struct ClaimData {
        uint256 claimAt;
        uint256 totalAmount;
        uint256 claimedAmount;
    }

    mapping(uint256 => bool) public paused;
    mapping(uint256 => Presale) public presale;
    mapping(address =>  ClaimData) public userClaimData;

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

    constructor(address _oracle, address _usdt, address _btcInu) {
        aggregatorInterface = Aggregator(_oracle);
        btcInu = _btcInu;
        USDT = IERC20Metadata(_usdt);
        ETH_MULTIPLIER = (10 ** 18);
        USDT_MULTIPLIER = (10 ** 6);
        fundReceiver = msg.sender;
    }

    function createPresale(
        uint256 _price,
        uint256 _tokensToSell,
        uint256 _UsdtHardcap,
        uint256 _startTime,
        uint256 _endTime,
        bool _isActive
    ) external onlyOwner {
        require(_price > 0, "Zero price");
        require(_tokensToSell > 0, "Zero tokens to sell");
        require(presale[presaleId].Active == false, "Inactive the previous presale");

        presaleId++;

        presale[presaleId] = Presale(
            _startTime,
            _endTime,
            _price,
            0,
            _tokensToSell,
            _UsdtHardcap,
            0,
            _isActive
        );

        emit PresaleCreated(presaleId, _tokensToSell, 0, 0);
    }

    function endPresale() public onlyOwner {
        require(presale[presaleId].Active, "This presale is already Inactive");
        presale[presaleId].Active = false;
    }

    function updatePresale(
        uint256 _id,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _price,
        uint256 _tokensToSell,
        uint256 _Hardcap
    ) external checkPresaleId(_id) onlyOwner {
        require(_price > 0, "Zero price");
        require(_tokensToSell > 0, "Zero tokens to sell");
        presale[_id].startTime =_startTime;
        presale[_id].price = _price;
        presale[_id].endTime = _endTime;
        presale[_id].tokensToSell = _tokensToSell;
        presale[_id].UsdtHardcap = _Hardcap;
    }

    function changeFundWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Invalid parameters");
        fundReceiver = _wallet;
    }

    function changeUSDTToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero token address");
        USDT = IERC20Metadata(_newAddress);
    }

    function pausePresale(uint256 _id) external checkPresaleId(_id) onlyOwner {
        require(!paused[_id], "Already paused");
        paused[_id] = true;
        emit PresalePaused(_id, block.timestamp);
    }

    function unPausePresale(
        uint256 _id
    ) external checkPresaleId(_id) onlyOwner {
        require(paused[_id], "Not paused");
        paused[_id] = false;
        emit PresaleUnpaused(_id, block.timestamp);
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        price = (price * (10 ** 10));
        return uint256(price);
    }

    modifier checkPresaleId(uint256 _id) {
        require(_id > 0 && _id <= presaleId, "Invalid presale id");
        _;
    }

    modifier checkSaleState(uint256 _id, uint256 amount) {
        require(
            block.timestamp >= presale[_id].startTime &&
                presale[_id].Active == true,
            "Invalid time for buying"
        );
        require(
            amount > 0 &&
                amount <= presale[_id].tokensToSell - presale[_id].soldTokens,
            "Invalid sale amount"
        );
        _;
    }

    function buyWithUSDT(
        uint256 usdAmount
    )
        external
        checkPresaleId(presaleId)
        checkSaleState(presaleId, usdtToTokens(presaleId, usdAmount))
        nonReentrant
        returns (bool)
    {
        require(block.timestamp <= presale[presaleId].endTime,"presale Time is over");
        require(!paused[presaleId], "Presale paused");
        require(
            presale[presaleId].amountRaised + usdAmount <=
                presale[presaleId].UsdtHardcap,
            "Amount should be less than leftHardcap"
        );
        uint256 numberOfTokens = usdtToTokens(presaleId, usdAmount);
        require(
            presale[presaleId].soldTokens + numberOfTokens <=
                presale[presaleId].tokensToSell
        );
        presale[presaleId].soldTokens += numberOfTokens;
        presale[presaleId].amountRaised += usdAmount;
        if (userClaimData[_msgSender()].totalAmount > 0) {
            userClaimData[_msgSender()]
                .totalAmount += numberOfTokens;
        } else {
            userClaimData[_msgSender()] = ClaimData(
                0,
                numberOfTokens,
                0
            );
        }

        uint256 ourAllowance = USDT.allowance(
            _msgSender(),
            address(this)
        );
        require(usdAmount <= ourAllowance, "Make sure to add enough allowance");
        (bool success, ) = address(USDT).call(
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
            presaleId,
            address(USDT),
            numberOfTokens,
            usdAmount,
            block.timestamp
        );
        return true;
    }

    function buyWithEth()
        external
        payable
        checkPresaleId(presaleId)
        checkSaleState(presaleId, ethToTokens(presaleId, msg.value))
        nonReentrant
        returns (bool)
    {
        uint256 usdAmount = (msg.value * getLatestPrice() * USDT_MULTIPLIER) /
            (ETH_MULTIPLIER * ETH_MULTIPLIER);
        require(
            presale[presaleId].amountRaised + usdAmount <=
                presale[presaleId].UsdtHardcap,
            "Amount should be less than leftHardcap"
        );
        require(block.timestamp <= presale[presaleId].endTime,"presale Time is over");
        require(!paused[presaleId], "Presale paused");

        uint256 numberOfTokens = usdtToTokens(presaleId, usdAmount);
         require(
            presale[presaleId].soldTokens + numberOfTokens <=
                presale[presaleId].tokensToSell
        );
        presale[presaleId].soldTokens += numberOfTokens;
        presale[presaleId].amountRaised += usdAmount;

        if (userClaimData[_msgSender()].totalAmount > 0) {
            userClaimData[_msgSender()].totalAmount += numberOfTokens;
        } else {
            userClaimData[_msgSender()]= ClaimData(
                0, // Last claimed at
                numberOfTokens, // total tokens to be claimed
                0 // claimed amount
            );
        }

        sendValue(payable(fundReceiver), msg.value);
        emit TokensBought(
            _msgSender(),
            presaleId,
            address(0),
            numberOfTokens,
            msg.value,
            block.timestamp
        );
        return true;
    }

    function ethBuyHelper(
        uint256 _id,
        uint256 amount
    ) external view checkPresaleId(_id) returns (uint256 ethAmount) {
        uint256 usdPrice = (amount * presale[_id].price);
        ethAmount =
            (usdPrice * ETH_MULTIPLIER) /
            (getLatestPrice() * 10 ** IERC20Metadata(btcInu).decimals());
    }

    function usdtBuyHelper(
        uint256 _id,
        uint256 amount
    ) external view returns (uint256 usdPrice) {
        usdPrice =
            (amount * presale[_id].price) /
            10 ** IERC20Metadata(btcInu).decimals();
    }

    function ethToTokens(
        uint256 _id,
        uint256 amount
    ) public view returns (uint256 _tokens) {
        uint256 usdAmount = (amount * getLatestPrice() * USDT_MULTIPLIER) /
            (ETH_MULTIPLIER * ETH_MULTIPLIER);
        _tokens = usdtToTokens(_id, usdAmount);
    }

    function usdtToTokens(
        uint256 _id,
        uint256 amount
    ) public view returns (uint256 _tokens) {
        _tokens = (amount * presale[_id].price) / USDT_MULTIPLIER;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    function claimableAmount(
        address user
    ) public view  returns (uint256) {
        ClaimData memory _user = userClaimData[user];

        require(_user.totalAmount > 0, "Nothing to claim");
        uint256 amount = _user.totalAmount - _user.claimedAmount;
        require(amount > 0, "Already claimed");
        return amount;
    }

    function claimAmount(
    ) public  returns (bool) {
        uint256 amount = claimableAmount(msg.sender);

        require(amount > 0, "Zero claim amount");
        require(btcInu != address(0), "Presale token address not set");
        require(
            amount <= IERC20(btcInu).balanceOf(address(this)),
            "Not enough tokens in the contract"
        );

        userClaimData[msg.sender].claimAt = block.timestamp;

        userClaimData[msg.sender].claimedAmount += amount;

        bool status = IERC20(btcInu).transfer(msg.sender, amount);
        require(status, "Token transfer failed");
        emit TokensClaimed(msg.sender, amount, block.timestamp);

        return true;
    }

    function WithdrawTokens(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(fundReceiver, amount);
    }

    function WithdrawContractFunds(uint256 amount) external onlyOwner {
        sendValue(payable(fundReceiver), amount);
    }

    function ChangeTokenToSell(address _token) public onlyOwner {
        btcInu = _token;
    }
}