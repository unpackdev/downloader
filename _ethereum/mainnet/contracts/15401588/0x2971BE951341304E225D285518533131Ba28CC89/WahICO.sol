// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./TransferHelper.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IWahICO.sol";
import "./OracleWrapper.sol";
import "./WahICOEvents.sol";

contract WahICO is Ownable, ReentrancyGuard, IWahICO, WahICOEvents {
    uint256 public override firstRangeTokenPrice;
    uint256 public override secondRangeTokenPrice;
    uint256 public override thirdRangeTokenPrice;
    IERC20 public USDTInstance;
    IERC20 public tokenInstance;
    uint128 public override firstRangeLimit;
    uint128 public override secondRangeLimit;
    uint256 public override tokenDecimals;
    uint256 public USDTDecimals;
    address public receiverAddress;
    address public override tokenAddress;
    address public USDTaddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public ETHtoUSD = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    constructor(address _tokenAddress, address _receiverAddress) {
        tokenAddress = _tokenAddress;
        receiverAddress = _receiverAddress;
        tokenInstance = IERC20(tokenAddress);
        tokenDecimals = 10**tokenInstance.decimals();
        USDTInstance = IERC20(USDTaddress);
        USDTDecimals = 10**USDTInstance.decimals();
        firstRangeTokenPrice = 9900; // $99
        secondRangeTokenPrice = 9000; // $90
        thirdRangeTokenPrice = 8000; // $80
        firstRangeLimit = 50_000 * uint128(USDTDecimals);
        secondRangeLimit = 100_000 * uint128(USDTDecimals);
    }

    function buyToken(uint8 _type, uint256 amount)
        public
        payable
        override
        nonReentrant
    {
        require(tokenInstance.balanceOf(address(this)) > 0, "No tokens left!");
        uint256 buyAmount;
        if (_type == 1) {
            //for ETH
            buyAmount = msg.value;
        } else {
            // for USDT
            buyAmount = amount;
            require(
                USDTInstance.balanceOf(msg.sender) >= buyAmount,
                "Not enough USDT balance"
            );
            require(
                USDTInstance.allowance(msg.sender, address(this)) >= buyAmount,
                "Allowance for such balance not provided"
            );
        }

        require(buyAmount > 0, "Buy amount should be greater than 0");

        (uint256 tokenAmount, uint256 tokenPrice) = calculateTokens(
            _type,
            buyAmount
        );

        if (_type == 1) {
            TransferHelper.safeTransferETH(receiverAddress, msg.value);
        } else {
            TransferHelper.safeTransferFrom(
                USDTaddress,
                msg.sender,
                receiverAddress,
                buyAmount
            );
        }
        require(
            tokenInstance.balanceOf(address(this)) > tokenAmount,
            "Not enough tokens in contract"
        );
        TransferHelper.safeTransfer(tokenAddress, msg.sender, tokenAmount);

        emit amountBought(
            _type,
            msg.sender,
            buyAmount,
            tokenAmount,
            tokenPrice,
            uint32(block.timestamp)
        );
    }

    receive() external payable {
        payable(receiverAddress).transfer(msg.value);
    }

    function _getUSDTvalue(uint8 _type, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        uint256 _finalUSDTvalue;

        if (_type == 1) {
            uint256 _amountToUSDT = ((OracleWrapper(ETHtoUSD).latestAnswer() *
                USDTDecimals) / 10**8);
            _finalUSDTvalue = (_amount * _amountToUSDT) / (10**18);
        } else {
            _finalUSDTvalue = _amount;
        }
        return _finalUSDTvalue;
    }

    function _getTokenPrice(uint256 amount) internal view returns (uint256) {
        //getting token price with respect to range of USDT
        // first range limit & second range limit is with USDT decimals
        if (amount > 0 && amount <= firstRangeLimit) {
            return firstRangeTokenPrice;
        } else if (amount > firstRangeLimit && amount <= secondRangeLimit) {
            return secondRangeTokenPrice;
        } else {
            return thirdRangeTokenPrice;
        }
    }

    function calculateTokens(uint8 _type, uint256 _amount)
        public
        view
        override
        returns (uint256, uint256)
    {
        uint256 amountInUSDT = _getUSDTvalue(_type, _amount);
        uint256 tokenPrice = _getTokenPrice(amountInUSDT);
        uint256 tokens = (amountInUSDT * 10**2 * tokenDecimals) / //10**2 set as general case for token price
            (tokenPrice * USDTDecimals);

        return (tokens, tokenPrice);
    }

    function getUnclaimedTokens() public onlyOwner nonReentrant {
        uint256 remainingContractBalance = IERC20(tokenAddress).balanceOf(
            address(this)
        );
        require(remainingContractBalance > 0, "All tokens claimed!");

        TransferHelper.safeTransfer(
            tokenAddress,
            receiverAddress,
            remainingContractBalance
        );
    }

    function setFirstRange(
        // range should be set along with USDT decimals
        uint128 _firstRange
    ) external onlyOwner {
        firstRangeLimit = _firstRange;
    }

    function setSecondRange(
        // range should be set along with USDT decimals
        uint128 _secondRange
    ) external onlyOwner {
        secondRangeLimit = _secondRange;
    }

    function setFirstRangeTokenPrice(uint256 _firstRangeTokenPrice)
        external
        onlyOwner
    {
        require(
            _firstRangeTokenPrice != firstRangeTokenPrice,
            "New token price is same as before"
        );

        firstRangeTokenPrice = _firstRangeTokenPrice;
    }

    function setSecondRangeTokenPrice(uint256 _secondRangeTokenPrice)
        external
        onlyOwner
    {
        require(
            _secondRangeTokenPrice != secondRangeTokenPrice,
            "New token price is same as before"
        );

        secondRangeTokenPrice = _secondRangeTokenPrice;
    }

    function setThirdRangeTokenPrice(uint256 _thirdRangeTokenPrice)
        external
        onlyOwner
    {
        require(
            _thirdRangeTokenPrice != thirdRangeTokenPrice,
            "New token price is same as before"
        );

        thirdRangeTokenPrice = _thirdRangeTokenPrice;
    }

    function setReceiverAddress(address _newReceiverAddress)
        external
        onlyOwner
    {
        require(
            _newReceiverAddress != address(0),
            "Zero address cannot be passed"
        );
        receiverAddress = _newReceiverAddress;
    }

    function setETHtoUSDaddress(address _ETHtoUSDaddress) external onlyOwner {
        require(
            _ETHtoUSDaddress != address(0),
            "Zero address cannot be passed"
        );
        ETHtoUSD = _ETHtoUSDaddress;
    }
}
