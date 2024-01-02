// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./IUniswapV2Router02.sol";
import "./Rewards.sol";

interface ISwapFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

contract QBEE is ERC20, ERC20Burnable, Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) private liquidityPool;
    mapping(address => bool) private whitelistTax;

    mapping(address => address) public inviters;

    //configs
    bool private AUTOSELL = true;
    bool private CREATEPAIR = true;

    uint256 private nftTax;
    uint256 private foundationTax;
    uint256 private burnTax;
    // uint8 private tradeCooldown;
    uint256 private airdropThreshold;
    uint256 private airdropNums;
    address private foundation;
    address public uniswapRouter;
    address public uniswapPair;
    address public weth;
    address public usdt;
    address public autoSellToken;

    SignatureRewards public nftRewardsPool;

    event changeAutoSell(bool status);
    event changeAutoSellToken(address token);
    event changeTax(uint256 _nftTax, uint256 _foundationTax, uint256 _burnTax);
    event changeAirdropThreshold(uint256 _t);
    // event changeCooldown(uint8 tradeCooldown);
    event changeLiquidityPoolStatus(address lpAddress, bool status);
    event changeWhitelistTax(address _address, bool status);
    event changeNftRewardsPool(address nftRewardsPool);
    event changeFoundation(address nftRewardsPool);
    event changeUniswapRouter(address uniswapRouter);
    event changeUniswapPair(address uniswapPair);

    constructor() ERC20("QBEE", "QBEE") {
        nftTax = 30;
        foundationTax = 100;
        burnTax = 20;
        airdropThreshold = 100 * 10 ** 18;
        airdropNums = 1;

        foundation = 0x9DaeFBA6D70f0eA86598b07912230947e5e5e838;
        uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        weth = IUniswapV2Router02(uniswapRouter).WETH();

        address signer = 0x46D7581bd24AfBDBa1F49ED1fE74A1d196aDa640;

        _approve(address(this), uniswapRouter, type(uint256).max);
        whitelistTax[address(0)] = true;
        whitelistTax[address(this)] = true;
        whitelistTax[msg.sender] = true;
        whitelistTax[foundation] = true;
        liquidityPool[uniswapRouter] = true;

        nftRewardsPool = new SignatureRewards(signer, payable(this));
        nftRewardsPool.transferOwnership(msg.sender);
        whitelistTax[address(nftRewardsPool)] = true;

        _mint(msg.sender, 1_000_000_000 * 10 ** decimals());

        if (CREATEPAIR) {
            autoSellToken = weth;
            ISwapFactory swapFactory = ISwapFactory(
                IUniswapV2Router02(uniswapRouter).factory()
            );
            uniswapPair = swapFactory.createPair(payable(this), autoSellToken);
            liquidityPool[uniswapPair] = true;
        }
    }

    receive() external payable {}

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function setAirdropNums(uint256 n) public onlyOwner {
        airdropNums = n;
    }

    function setAutoSell(bool _status) external onlyOwner {
        AUTOSELL = _status;
        emit changeAutoSell(_status);
    }

    function setAutoSellToken(address _token) external onlyOwner {
        autoSellToken = _token;
        emit changeAutoSellToken(_token);
    }

    function setTaxes(
        uint256 _nftTax,
        uint256 _foundationTax,
        uint256 _burnTax
    ) external onlyOwner {
        nftTax = _nftTax;
        foundationTax = _foundationTax;
        burnTax = _burnTax;
        emit changeTax(_nftTax, _foundationTax, _burnTax);
    }

    function setAirdropThreshold(uint256 _t) external onlyOwner {
        airdropThreshold = _t;
        emit changeAirdropThreshold(_t);
    }

    function getTaxes()
        external
        pure
        returns (uint8 _nftTax, uint8 _foundationTax, uint8 _burnTax)
    {
        return (_nftTax, _foundationTax, _burnTax);
    }

    function setLiquidityPoolStatus(
        address _lpAddress,
        bool _status
    ) external onlyOwner {
        liquidityPool[_lpAddress] = _status;
        emit changeLiquidityPoolStatus(_lpAddress, _status);
    }

    function setWhitelist(address _address, bool _status) external onlyOwner {
        whitelistTax[_address] = _status;
        emit changeWhitelistTax(_address, _status);
    }

    function setRewardsPool(address _nftRewardsPool) external onlyOwner {
        nftRewardsPool = SignatureRewards(_nftRewardsPool);
        emit changeNftRewardsPool(_nftRewardsPool);
    }

    function setFoundation(address _foundation) external onlyOwner {
        foundation = _foundation;
        emit changeFoundation(_foundation);
    }

    function setUniswapRouter(address _uniswapRouter) external onlyOwner {
        uniswapRouter = _uniswapRouter;
        IERC20(address(this)).approve(_uniswapRouter, type(uint256).max);
        liquidityPool[_uniswapRouter] = true;
        emit changeUniswapRouter(_uniswapRouter);
    }

    function setUniswapPair(address _uniswapPair) external onlyOwner {
        uniswapPair = _uniswapPair;
        liquidityPool[_uniswapPair] = true;
        emit changeUniswapPair(_uniswapPair);
    }

    function getMinimumAirdropAmount() private view returns (uint256) {
        return 0;
    }

    function getInviter(
        address who,
        uint256 n
    ) public view returns (address[] memory) {
        address[] memory inviters_ = new address[](n);
        address temp = who;

        for (uint256 index = 0; index < n; index++) {
            temp = inviters[temp];
            inviters_[index] = temp == who ? address(0) : temp;
        }

        return inviters_;
    }

    function _transfer(
        address sender,
        address receiver,
        uint256 amount
    ) internal virtual override {
        if (balanceOf(sender) == amount) amount -= 1; //keep 1wei
        _keep1andRandomAirdrop(sender);
        amount -= airdropNums;

        uint256 taxAmount0 = 0;
        uint256 taxAmount1 = 0;
        uint256 taxAmount2 = 0;

        if (liquidityPool[receiver] == true || liquidityPool[sender] == true) {
            //buy or sell
            taxAmount0 = (amount * nftTax) / 10000;
            taxAmount1 = (amount * foundationTax) / 10000;
            taxAmount2 = (amount * burnTax) / 10000;
        }

        //It's an LP Pair and it's a sell

        if (whitelistTax[sender] || whitelistTax[receiver]) {
            taxAmount0 = 0;
            taxAmount1 = 0;
            taxAmount2 = 0;
        }

        if (liquidityPool[sender] == true && liquidityPool[receiver] == true) {
            taxAmount0 = 0;
            taxAmount1 = 0;
            taxAmount2 = 0;
        }

        if (taxAmount0 > 0) {
            super._transfer(sender, address(nftRewardsPool), taxAmount0);
        }
        if (taxAmount1 > 0) {
            if (liquidityPool[sender] == true) {
                //buy
                super._transfer(sender, foundation, taxAmount1);
            } else {
                // sell
                if (AUTOSELL) {
                    super._transfer(sender, address(this), taxAmount1);
                    IUniswapV2Router02(uniswapRouter)
                        .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                            taxAmount1,
                            0,
                            getPathForTokenToToken(
                                address(this),
                                autoSellToken
                            ),
                            foundation,
                            block.timestamp + 1 days
                        ); //swapExactTokensForTokens
                } else {
                    super._transfer(sender, foundation, taxAmount1);
                }
            }
        }

        if (taxAmount2 > 0) {
            _burn(sender, taxAmount2);
        }

        super._transfer(
            sender,
            receiver,
            amount - taxAmount0 - taxAmount1 - taxAmount2
        );
    }

    function _keep1andRandomAirdrop(address sender) internal {
        if (airdropNums > 0) {
            for (uint256 a = 0; a < airdropNums; a++) {
                super._transfer(
                    sender,
                    address(
                        uint160(
                            uint256(
                                keccak256(
                                    abi.encodePacked(
                                        a,
                                        block.number,
                                        block.difficulty,
                                        block.timestamp
                                    )
                                )
                            )
                        )
                    ),
                    1
                );
            }
        }
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        if (
            inviters[_to] == address(0) &&
            !liquidityPool[_from] &&
            !liquidityPool[_to] &&
            !whitelistTax[_from] &&
            !whitelistTax[_to] &&
            _amount >= getMinimumAirdropAmount()
        ) inviters[_to] = _from;
        super._beforeTokenTransfer(_from, _to, _amount);
    }

    function getPathForTokenToToken(
        address _tokenIn,
        address _tokenOut
    ) private pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        return path;
    }

    function rescure() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function rescure(address token) public onlyOwner {
        IERC20(token).safeTransfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }
}
