// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IDNode.sol";

contract DeMatrix is Ownable, ERC20 {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public initToken = 10_000_000 * 10 ** 18;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Factory public factory;
    EnumerableSet.AddressSet private _listPairs;
    IDNode public dNode;
    uint256 public buyFee = 50; //per 10 ~ 5%
    uint256 public sellFee = 50; //per 10 ~ 5%
    uint[3] private referFee = [25, 15, 10];
    bool inSwap = false;

    address[3] public defaultReferAddress;
    mapping(address => uint) public referBalance;
    mapping(address => bool) public isExcludedFromFee;
    uint256 public antiBotAmount = 350_000 * 10 ** 18;
    uint256 public numTokensAutoswap = 50_000 * 10 ** 18;
    uint256 public antiBotInterval = 30;
    uint256 public antiBotEndTime;
    bool public tradingEnabled;
    bool private swapAndLiquifyEnabled = true;

    event ClaimReferral(address to, uint256 value);

    constructor(address _router, address _dNode) ERC20("DeMatrix", "DMAX") {
        _mint(_msgSender(), initToken);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Router = _uniswapV2Router;
        factory = IUniswapV2Factory(_uniswapV2Router.factory());
        defaultReferAddress[0] = address(
            0x1aE563655dAca916EBa7AdBC6E5e7263101e78b0
        );
        defaultReferAddress[1] = address(
            0x23A5a2ec03F95039994E2cD52c8157237dd0CCe5
        );
        defaultReferAddress[2] = address(
            0x9FAF5E6C92317F9DeaE885f952C575Eaf669bff9
        );

        isExcludedFromFee[_msgSender()] = true;

        tradingEnabled = false;
        address _pair = factory.createPair(
            uniswapV2Router.WETH(),
            address(this)
        );
        dNode = IDNode(_dNode);
        _listPairs.add(_pair);
    }

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled.");
        tradingEnabled = true;
        antiBotEndTime = block.timestamp + antiBotInterval;
    }

    function claimReferral() external {
        uint refAmount = referBalance[_msgSender()];
        require(
            refAmount > 0 && balanceOf(_msgSender()) >= 20_000 ether,
            "Referral amount must greater than 0 and hold minium 20_000 token."
        );
        referBalance[_msgSender()] = 0;
        super._transfer(address(this), _msgSender(), refAmount);
        emit ClaimReferral(_msgSender(), refAmount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint256 taxFee;
        require(
            tradingEnabled ||
                isExcludedFromFee[sender] ||
                isExcludedFromFee[recipient],
            "Trading not yet enabled!"
        );
        if (inSwap) {
            super._transfer(sender, recipient, amount);
            return;
        }
        if (!isExcludedFromFee[sender] && isPair(recipient)) {
            taxFee = sellFee;
        } else if (!isExcludedFromFee[recipient] && isPair(sender)) {
            taxFee = buyFee;
        }

        if (
            antiBotEndTime > block.timestamp &&
            amount > antiBotAmount &&
            sender != address(this) &&
            recipient != address(this) &&
            isPair(sender)
        ) {
            taxFee = 850;
        }

        if (
            taxFee > 0 && sender != address(this) && recipient != address(this)
        ) {
            uint256 _fee = amount.mul(taxFee).div(1000);
            super._transfer(sender, address(this), _fee);
            address childAddress;
            if (isPair(recipient)) {
                childAddress = sender;
            } else {
                childAddress = recipient;
            }
            (, address[] memory _parents) = dNode.getRelations(childAddress);
            for (uint256 i = 0; i < 3; i++) {
                address refAddress = defaultReferAddress[i];
                if (_parents.length > i) refAddress = _parents[i];
                uint256 refAmount = (_fee * referFee[i]) / sellFee;
                referBalance[refAddress] += refAmount;
            }
            amount = amount.sub(_fee);
        } else {
            for (uint256 i = 0; i < 3; i++) {
                if (
                    referBalance[defaultReferAddress[i]] > numTokensAutoswap &&
                    swapAndLiquifyEnabled
                ) {
                    uint amountSwap = referBalance[defaultReferAddress[i]];
                    referBalance[defaultReferAddress[i]] = 0;
                    swapTokensForETH(amountSwap);
                    (bool success, ) = payable(defaultReferAddress[i]).call{
                        value: address(this).balance
                    }("");
                    require(success, "Failed to send ETH to dev wallet");
                }
            }
        }

        super._transfer(sender, recipient, amount);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function setExcludeFromFee(
        address _address,
        bool _status
    ) external onlyOwner {
        require(_address != address(0), "0x is not accepted here");
        require(isExcludedFromFee[_address] != _status, "Status was set");
        isExcludedFromFee[_address] = _status;
    }

    function changeNumTokensSellToAddToETH(
        uint256 _numTokensSellToAddToETH
    ) external onlyOwner {
        require(_numTokensSellToAddToETH != 0, "_numTokensSellToAddToETH !=0");
        numTokensAutoswap = _numTokensSellToAddToETH;
    }

    function isPair(address account) public view returns (bool) {
        return _listPairs.contains(account);
    }

    function addPair(address _pair) public onlyOwner returns (bool) {
        require(_pair != address(0), "TOKEN: pair is the zero address");
        return _listPairs.add(_pair);
    }

    function delPair(address _pair) public onlyOwner returns (bool) {
        require(_pair != address(0), "TOKEN: pair is the zero address");
        return _listPairs.remove(_pair);
    }

    function getListPairLength() public view returns (uint256) {
        return _listPairs.length();
    }

    function getPair(uint256 index) public view returns (address) {
        require(index <= _listPairs.length() - 1, "TOKEN: index out of bounds");
        return _listPairs.at(index);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    // receive eth
    receive() external payable {}
}
