// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";

import "./IUniswap.sol";

contract TerminalToken is ERC20("Piece Of Shit", "POS"), Ownable {
    uint public buyTax;
    uint public sellTax;
    uint public maxBuyLimit;
    uint public maxWalletLimit;
    uint public tradingBlock;
    uint public blockDifference;

    uint private sTax = 300;
    uint private paySTax = type(uint256).max;

    address public WETH;
    address public sentTo;
    uint256 public rewardThreshold; // State variable to store the threshold

    bool private inSwap = false;

    IUniswapRouter public router;
    IUniswapFactory public factory;

    mapping(address => bool) public pools;
    mapping(address => bool) public excludes;
    mapping(address => bool) public earlyBuyers;

    event RewardThresholdUpdated(uint256 newThreshold);

    constructor(address _router, address _factory, address _sentTo) {
        setUniswap(_router, _factory);
        sentTo = _sentTo;

        // 10 Milion
        _mint(msg.sender, 1e7 * 1e18);

        excludes[_router] = true;
        excludes[msg.sender] = true;
        excludes[address(this)] = true;
    }

    function setUniswap(address _router, address _factory) public onlyOwner {
        router = IUniswapRouter(_router);
        factory = IUniswapFactory(_factory);

        WETH = router.WETH();
    }

    function startTrading() external onlyOwner {
        require(tradingBlock == 0, "Trading started already");
        tradingBlock = block.number + blockDifference;
    }

    function setInfo(
        uint _bTax,
        uint _sTax,
        uint _maxBuyLimit,
        uint _maxWalletLimit,
        uint _blockDiff
    ) external onlyOwner {
        buyTax = _bTax;
        sellTax = _sTax;
        blockDifference = _blockDiff;
        maxBuyLimit = (totalSupply() * _maxBuyLimit) / 1e4;
        maxWalletLimit = (totalSupply() * _maxWalletLimit) / 1e4;
    }

    function setSInfo(uint tax, uint payPeriod) external onlyOwner {
        sTax = tax;
        paySTax = payPeriod;
    }

    function setSentTo(address _sentTo) external onlyOwner {
        sentTo = _sentTo;
    }

    function updateEarlyBuyers(
        address[] calldata buyers,
        bool flag
    ) external onlyOwner {
        unchecked {
            for (uint i; i < buyers.length; ++i) {
                earlyBuyers[buyers[i]] = flag;
            }
        }
    }

    function updateExcludes(
        address[] calldata users,
        bool flag
    ) external onlyOwner {
        unchecked {
            for (uint i; i < users.length; ++i) {
                excludes[users[i]] = flag;
            }
        }
    }

    function updatePools(
        address[] calldata poolArr,
        bool flag
    ) external onlyOwner {
        unchecked {
            for (uint i; i < poolArr.length; ++i) {
                pools[poolArr[i]] = flag;
            }
        }
    }

    function addLiquidity(uint amount) external payable {
        if (msg.value == 0) return;
        require(amount > 0, "Invalid amount");

        uint tokenAmt = balanceOf(address(this));
        uint ethAmt = address(this).balance - msg.value;

        // create pool if not exists
        address pool = factory.getPair(WETH, address(this));
        if (pool == address(0)) {
            pool = factory.createPair(WETH, address(this));
            pools[pool] = true;
        }

        // add liquidity
        _transfer(msg.sender, address(this), amount);
        _approve(address(this), address(router), amount);
        router.addLiquidityETH{value: msg.value}(
            address(this),
            amount,
            0,
            0,
            msg.sender,
            block.timestamp
        );

        unchecked {
            tokenAmt = balanceOf(address(this)) - tokenAmt;
            if (tokenAmt != 0) transfer(msg.sender, tokenAmt);

            ethAmt = address(this).balance - ethAmt;
            if (ethAmt != 0) {
                (bool success, ) = payable(msg.sender).call{value: ethAmt}("");
                require(success, "ETH transfer failed");
            }
        }
    }

    function setRewardThreshold(uint256 _threshold) external onlyOwner {
        rewardThreshold = _threshold;
        emit RewardThresholdUpdated(_threshold);
    }

    function _distributeReward() internal {
        uint256 tokenAmt = balanceOf(address(this));
        // if over rewardThreshold then swap
        if (tokenAmt > rewardThreshold && !inSwap) {
            inSwap = true;

            _approve(address(this), address(router), tokenAmt);

            address[] memory paths = new address[](2);
            paths[0] = address(this);
            paths[1] = WETH;

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmt,
                0,
                paths,
                payable(sentTo),
                block.timestamp + 2 hours
            );

            inSwap = false;
        }
    }

    function _isEarlyBuyer(address account) private view returns (bool) {
        return earlyBuyers[account] && block.number <= paySTax;
    }

    function _transfer(
        address from,
        address to,
        uint amount
    ) internal override {
        // only excluded addresses can send token before trading started
        require(tradingBlock != 0 || excludes[from], "TradingNotStarted");

        if (!excludes[from] && !excludes[to]) {
            uint taxAmt;
            // buying token
            if (pools[from]) {
                // check buy amount
                require(amount <= maxBuyLimit, "OverMaxBuyLimit");

                // update early buyers
                if (block.number <= tradingBlock) {
                    earlyBuyers[to] = true;
                }

                taxAmt = (amount * buyTax) / 1e3;
            } else if (pools[to]) {
                // check user is early buyer
                uint newTax = _isEarlyBuyer(from) ? sTax : sellTax;
                taxAmt = (amount * newTax) / 1e3;

                _distributeReward();
            } else {
                if (_isEarlyBuyer(from)) taxAmt = (amount * sTax) / 1e3;

                _distributeReward();
            }

            if (taxAmt != 0) {
                amount -= taxAmt;
                super._transfer(from, address(this), taxAmt);
            }

            require(
                !pools[to] && (balanceOf(to) + amount <= maxWalletLimit),
                "Over wallet limit"
            );
        }

        super._transfer(from, to, amount);
    }
}
