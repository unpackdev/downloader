// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner_) public virtual override onlyOwner {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner_);
        _owner = newOwner_;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract KIDO is Ownable, ReentrancyGuard {
    address public token;
    uint256 public price = 12_500; //0.01E=800b  0.01*1e18=8*1e11
    uint256 public startTime;
    uint256 public endTime;
    uint256 public minAmountE = 10_000_000_000_000_000; // 0.01 ETH
    uint256 public maxAmountE = 200_000_000_000_000_000; // 0.2 ETH
    uint256 public totalIDOAmountE;

    mapping(address => uint256) public IDOAmountE;

    function setConfig(address _token, uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime >= block.timestamp && _endTime >= _startTime, "error");

        token = _token;
        startTime = _startTime;
        endTime = _endTime;
    }

    function setTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime >= block.timestamp, "_WithListOneStartTime error");
        require(_endTime >= _startTime, "_WithListOneEndTime error");
        startTime = _startTime;
        endTime = _endTime;
    }

    function setLimit(uint256 _minAmount, uint256 _maxAmount) external onlyOwner {
        require(_minAmount > 0, "minAmount error");
        require(_maxAmount > _minAmount, "maxAmount error");
        minAmountE = _minAmount;
        maxAmountE = _maxAmount;
    }

    function setPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "price error");
        price = _price;
    }

    function buy() public payable nonReentrant {
        require(block.timestamp > startTime && block.timestamp < endTime, "error1");
        uint256 amount = msg.value;
        IDOAmountE[msg.sender] += amount;
        require(IDOAmountE[msg.sender] >= minAmountE , "< 0.01E");
        require(IDOAmountE[msg.sender] <= maxAmountE, "> 0.2E");

        uint256 outAmount = amount * 1e8 / price;
        IERC20(token).transfer(msg.sender, outAmount);
        totalIDOAmountE += amount;
    }

    function withdraw(address _erc20, address _to, uint256 _val) external onlyOwner {
        IERC20(_erc20).transfer(_to, _val);
    }

    function withdrawETH(address payable recipient) external onlyOwner {
        (bool success,) = recipient.call{ value: address(this).balance }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
