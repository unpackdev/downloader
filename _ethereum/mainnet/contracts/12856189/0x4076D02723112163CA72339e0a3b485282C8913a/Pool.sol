// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IPoolFactory.sol";

contract Pool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    enum PoolType {
        Private,
        Public
    }

    mapping(address => bool) public whitelistedAddresses;

    IERC20 public token; // address of token
    uint256 public tokenTarget; // total allocation of token
    uint256 public poolId;

    address public weiToken;

    uint256 public ratio;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimTime;

    uint256 public minWei; // min amount per wallet can purchase
    uint256 public maxWei; // max amount per wallet can purchase

    PoolType public poolType;

    string public meta;

    uint256 public totalOwed; // weiRaised * ratio
    mapping(address => uint256) public claimable;
    uint256 public weiRaised; // gathered ETH

    address public factory;

    event PoolInitialized(
        address token,
        address weiToken,
        uint256 tokenTarget,
        uint256 ratio,
        uint256 minWei,
        uint256 maxWei,
        uint256 poolId
    );

    event PoolBaseDataInitialized(
        Pool.PoolType poolType,
        uint256 startTime,
        uint256 endTime,
        uint256 claimTime,
        string meta,
        uint256 poolId
    );

    event MetaDataChanged(string meta, uint256 poolId);

    event PoolProgressChanged(
        address buyer,
        uint256 amount,
        uint256 totalOwed,
        uint256 weiRaised,
        uint256 poolId
    );

    constructor(
        address _factory,
        IERC20 _token,
        uint256 _tokenTarget,
        address _weiToken,
        uint256 _ratio,
        uint256 _minWei,
        uint256 _maxWei,
        uint256 _poolId
    ) {
        require(
            _factory != address(0),
            "zero address provided for factory address"
        );
        require(
            address(_token) != address(0),
            "zero address provided for token address"
        );

        poolId = _poolId;
        token = _token;
        tokenTarget = _tokenTarget;
        weiToken = _weiToken;
        ratio = _ratio;
        minWei = _minWei;
        maxWei = _maxWei;

        factory = _factory;

        emit PoolInitialized(
            address(token),
            weiToken,
            tokenTarget,
            ratio,
            minWei,
            maxWei,
            poolId
        );
    }

    function setBaseData(
        PoolType _poolType,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _claimTime,
        string memory _meta
    ) external onlyOwner {
        require(startTime == uint256(0), "BaseData is already set!");
        poolType = _poolType;
        meta = _meta;
        startTime = _startTime;
        endTime = _endTime;
        claimTime = _claimTime;

        emit PoolBaseDataInitialized(
            poolType,
            startTime,
            endTime,
            claimTime,
            meta,
            poolId
        );
    }

    function setMeta(string memory _meta) external onlyOwner {
        require(
            startTime == 0 || block.timestamp < startTime,
            "Pool already started!"
        );
        meta = _meta;

        emit MetaDataChanged(meta, poolId);
    }

    function addWhitelistedAddress(address _address) external onlyOwner {
        whitelistedAddresses[_address] = true;
    }

    function addMultipleWhitelistedAddresses(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistedAddresses[_addresses[i]] = true;
        }
    }

    function removeWhitelistedAddress(address _address) external onlyOwner {
        whitelistedAddresses[_address] = false;
    }

    function claimableAmount(address user) external view returns (uint256) {
        return claimable[user] * ratio;
    }

    function withdrawToken() external onlyOwner {
        require(block.timestamp > endTime, "Pool has not yet ended");
        token.safeTransfer(
            msg.sender,
            token.balanceOf(address(this)) - totalOwed
        );
    }

    function withdrawWei(uint256 amount) public payable onlyOwner nonReentrant {
        require(block.timestamp > endTime, "Pool has not yet ended");
        require(weiToken == address(0), "It's not eth-buy pool!");
        require(
            address(this).balance >= amount,
            "Can't withdraw more than you have."
        );
        (address feeRecipient, uint256 feePercent) = IPoolFactory(factory)
        .getFeeInfo();
        uint256 fee = (amount * feePercent) / 1000;
        uint256 restAmount = amount - fee;
        payable(feeRecipient).sendValue(fee);
        payable(msg.sender).sendValue(restAmount);
    }

    function withdrawWeiToken(uint256 amount) external onlyOwner {
        require(block.timestamp > endTime, "Pool has not yet ended");
        require(weiToken != address(0), "It's not token-buy pool!");
        require(
            IERC20(weiToken).balanceOf(address(this)) >= amount,
            "Can't withdraw more than you have."
        );
        (address feeRecipient, uint256 feePercent) = IPoolFactory(factory)
        .getFeeInfo();
        uint256 fee = (amount * feePercent) / 1000;
        uint256 restAmount = amount - fee;
        IERC20(weiToken).safeTransfer(feeRecipient, fee);
        IERC20(weiToken).safeTransfer(msg.sender, restAmount);
    }

    function claim() external {
        require(
            block.timestamp > claimTime && claimTime != 0,
            "claiming not allowed yet"
        );
        require(claimable[msg.sender] > 0, "nothing to claim");

        uint256 amount = claimable[msg.sender] * ratio;

        claimable[msg.sender] = 0;
        totalOwed -= amount;

        token.safeTransfer(msg.sender, amount);
    }

    function checkBeforeBuy() private view {
        require(
            startTime != 0 && block.timestamp > startTime,
            "Pool has not yet started"
        );
        require(
            endTime != 0 && block.timestamp < endTime,
            "Pool already ended"
        );

        if (poolType == PoolType.Private) {
            require(
                whitelistedAddresses[msg.sender],
                "you are not whitelisted"
            );
        } else if (poolType == PoolType.Public) {
            (IERC20 baseToken, uint256 baseAmount) = IPoolFactory(factory)
            .getBaseInfo();
            require(
                baseToken.balanceOf(msg.sender) >= baseAmount,
                "You don't have enough base TOKEN!"
            );
        }
    }

    function buyWithEth() public payable {
        require(weiToken == address(0), "It's not eth-buy pool!");
        checkBeforeBuy();
        require(msg.value >= minWei, "amount too low");
        uint256 amount = msg.value * ratio;
        require(
            totalOwed + amount <= token.balanceOf(address(this)),
            "sold out"
        );

        require(
            claimable[msg.sender] + msg.value <= maxWei,
            "maximum purchase cap hit"
        );

        claimable[msg.sender] += msg.value;
        totalOwed += amount;
        weiRaised += msg.value;

        emit PoolProgressChanged(
            msg.sender,
            msg.value,
            totalOwed,
            weiRaised,
            poolId
        );
    }

    function buy(uint256 weiAmount) public {
        require(weiToken != address(0), "It's not token-buy pool!");
        checkBeforeBuy();
        require(weiAmount >= minWei, "amount too low");

        uint256 amount = weiAmount * ratio;
        require(
            totalOwed + amount <= token.balanceOf(address(this)),
            "sold out"
        );

        require(
            claimable[msg.sender] + weiAmount <= maxWei,
            "maximum purchase cap hit"
        );

        IERC20(weiToken).safeTransferFrom(msg.sender, address(this), weiAmount);

        claimable[msg.sender] = claimable[msg.sender] + weiAmount;
        totalOwed += amount;
        weiRaised += weiAmount;

        emit PoolProgressChanged(
            msg.sender,
            weiAmount,
            totalOwed,
            weiRaised,
            poolId
        );
    }

    fallback() external payable {
        buyWithEth();
    }

    receive() external payable {
        buyWithEth();
    }
}
