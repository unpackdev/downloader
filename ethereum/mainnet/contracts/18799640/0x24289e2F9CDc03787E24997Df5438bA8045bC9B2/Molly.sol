// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./SafeMath.sol";
import "./IERC20Metadata.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable2Step.sol";
/**
 * @title Molly ERC20 Contract
 */

pragma solidity ^0.8.19;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Molly is ERC20, Ownable2Step {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address private controllerWallet;

    uint256 private accumalatedFees;

    uint256 public swapTokensAtAmount;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    address public whiteBrick =
        address(0xA2c27b1244313E9fB6ADA0F7083145c67EbBA0Ed);

    address public blackManOne =
        address(0x1Fe3bc7288F644b686D258139b323DbA98A8661a);

    address public titaniumB =
        address(0x81080a6c8ED0FdD53fE63d21D81EeF8B6ed22b1b);

    address public nakedB = address(0x65849de03776Ef05A9C88E367B395314999826ed);

    address public purpleGrandma =
        address(0xE3A4Bd737045Ba0ceC4202765d7dBe6C91cd993e);

    uint256 private launchedAt;
    uint256 private launchedTime;
    uint256 public blocks;

    uint256 public buyFees = 700;

    uint256 public sellFees = 700;

    bytes32 public merkleRoot =
        0x5449e79551c379b8359c3b4cf19ac96575201500845c913e8beb22c581838d83;

    bytes32 public verifyRoot =
        0xf687a5540fdd5e021d407d0269f23ed4fd4294f44e4ce908b407701c6af5bbe2;

    bytes32 public privateMerkleRoot =
        0x96555cdb7fd2c4ffaefcc762fe1ce2d96c035f2e33b6e370bcc74099416fac07;

    uint256 public startDate = block.timestamp;
    uint256 public initialFee = 80 * 10 ** 2; // Multiply by 100 to get two decimal places
    uint256 public dailyDecrease = initialFee / 90;

    uint256 public angelInitialFee = 90 * 10 ** 2; // Multiply by 100 to get two decimal places

    uint256 public angelDailyDecrease = angelInitialFee / 120;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    mapping(address => bool) public automatedMarketMakerPairs;

    mapping(uint256 => uint256) private blockSwaps;

    mapping(address => bool) public isAngelBuyer;

    mapping(address => bool) public isPrivateSaleBuyer;

    mapping(address => bool) public isVerified;

    mapping(address => bool) public privateClaimed;

    mapping(address => bool) public AngelClaimed;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event controllerWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("Molly", "MOLLY") Ownable(msg.sender) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        // 100 Billion Tokens
        uint256 totalSupply = 100_000_000_000 * 1e18;

        swapTokensAtAmount = 1_000_000 * 1e18;

        controllerWallet = nakedB;

        uint256 amountLP = 1_160_000_000 * 1e18;
        uint256 amountPrivate = 5_640_000_000 * 1e18;
        uint256 amountUnAccounted = 3_200_000_000 * 1e18;
        uint256 amountAngel = totalSupply.mul(10).div(100);
        uint256 amountWhiteBrick = totalSupply.mul(25).div(100);
        uint256 amountBlackManOne = totalSupply.mul(25).div(100);
        uint256 amountTitaniumB = totalSupply.mul(30).div(100);

        _mint(address(this), amountLP);
        _mint(address(this), amountAngel);
        _mint(address(this), amountPrivate);
        _mint(whiteBrick, amountWhiteBrick);
        _mint(blackManOne, amountBlackManOne);
        _mint(titaniumB, amountTitaniumB);
        _mint(purpleGrandma, amountUnAccounted);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(whiteBrick, true);
        excludeFromFees(blackManOne, true);
        excludeFromFees(titaniumB, true);
        excludeFromFees(purpleGrandma, true);
    }

    receive() external payable {}

    /**
     * @notice Open trading on Uniswap by providing initial liquidity.
     * @dev Only callable by the contract owner. Approves Uniswap router and adds liquidity using contract's balance.
     */
    function openTrade(uint256 _amount) external payable onlyOwner {
        _approve(address(this), address(uniswapV2Router), totalSupply());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            _amount,
            0,
            0,
            owner(),
            block.timestamp
        );

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

        blocks = 10;
        tradingActive = true;
        swapEnabled = true;
        launchedAt = block.number;
        launchedTime = block.timestamp;
    }

    /**
     * @notice Remove trading limits set by the contract.
     * @dev Function to disable limits post-launch, ensuring free trading. Only callable by the contract owner.
     */
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }

    /**
     * @notice Update the minimum token amount required before swapped for ETH.
     * @dev Only callable by the contract owner. Sets the threshold amount that triggers swap and liquify.
     * @param newAmount The new threshold amount in tokens.
     */
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        swapTokensAtAmount = newAmount * (10 ** 18);
    }

    /**
     * @notice Whitelist a contract from max transaction amount and fees.
     * @dev Only callable by the contract owner. Useful for whitelisting other smart contracts like presale or staking.
     * @param _whitelist The address of the contract to whitelist.
     * @param isWL Boolean value to set the whitelisting status.
     */
    function whitelistContract(address _whitelist, bool isWL) public onlyOwner {
        _isExcludedMaxTransactionAmount[_whitelist] = isWL;

        _isExcludedFromFees[_whitelist] = isWL;
    }

    /**
     * @notice Verify a user using MerkleProof verification.
     * @dev Verifies that the user's data is a valid MerkleProof. Marks user as verified if successful.
     * @param _merkleProof The Data to verify.
     */

    function verifyUser(bytes32[] calldata _merkleProof) external {
        require(!isVerified[msg.sender], "Already verified");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, verifyRoot, leaf),
            "Invalid proof!"
        );

        isVerified[msg.sender] = true;
    }

    /**
     * @notice Claim tokens allocated for Angel Sale participants.
     * @dev Requires user to be verified and to provide a valid merkle proof. Transfers the specified amount of tokens.
     * @param _amount The amount of tokens to claim.
     * @param _merkleProof The merkle proof proving the allocation.
     */
    function claimAngelSale(
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external {
        require(merkleRoot != 0, "Merkleroot not set");
        require(isVerified[msg.sender], "Not verified");
        bytes32 leaf = keccak256(abi.encodePacked((msg.sender), _amount));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );
        require(!AngelClaimed[msg.sender], "Already claimed");
        AngelClaimed[msg.sender] = true;
        isAngelBuyer[msg.sender] = true;
        _transfer(address(this), msg.sender, _amount);
    }

    /**
     * @notice Claim tokens allocated for Private Sale participants.
     * @dev Similar to claimAngelSale but for Private Sale allocations.
     * @param _amount The amount of tokens to claim.
     * @param _merkleProof The merkle proof proving the allocation.
     */
    function claimPrivateSale(
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external {
        require(privateMerkleRoot != 0, "Merkleroot not set");
        require(isVerified[msg.sender], "Not verified");
        bytes32 leaf = keccak256(abi.encodePacked((msg.sender), _amount));
        require(
            MerkleProof.verify(_merkleProof, privateMerkleRoot, leaf),
            "Invalid proof!"
        );
        require(!privateClaimed[msg.sender], "Already claimed");
        privateClaimed[msg.sender] = true;
        isPrivateSaleBuyer[msg.sender] = true;
        _transfer(address(this), msg.sender, _amount);
    }

    /**
     * @notice Exclude an address from the maximum transaction amount.
     * @dev Only callable by the contract owner. Useful for excluding certain addresses from transaction limits.
     * @param updAds The address to update.
     * @param isEx Boolean to indicate if the address should be excluded.
     */
    function excludeFromMaxTransaction(
        address updAds,
        bool isEx
    ) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    /**
     * @notice Update the state of swap functionality.
     * @dev Emergency function to enable/disable contract's ability to swap. Only callable by the contract owner.
     * @param enabled Boolean to enable or disable swapping.
     */
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    /**
     * @notice Exclude an address from paying transaction fees.
     * @dev Only callable by the contract owner. Can be used to exclude certain addresses like presale contracts from fees.
     * @param account The address to exclude.
     * @param excluded Boolean to indicate if the address should be excluded.
     */
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    /**
     * @notice Allows the owner to manually swap tokens for ETH.
     * @dev Only callable by the controller wallet. Swaps specified token amount for ETH.
     * @param amount The amount of tokens to swap.
     */
    function manualswap(uint256 amount) external onlyOwner {
        require(_msgSender() == controllerWallet);
        require(
            amount <= balanceOf(address(this)) && amount > 0,
            "Wrong amount"
        );
        swapTokensForEth(amount);
    }

    /**
     * @notice Manually transfer ETH from contract to controller wallet.
     * @dev Function to send all ETH balance of the contract to the controller wallet. Only callable by the owner.
     */
    function manualsend() external onlyOwner {
        bool success;
        (success, ) = address(controllerWallet).call{
            value: address(this).balance
        }("");
    }

    /**
     * @notice Set or unset a pair as an Automated Market Maker pair.
     * @dev Only callable by the contract owner. Useful for adding/removing liquidity pools.
     * @param pair The address of the pair to update.
     * @param value Boolean to set the pair as AMM pair or not.
     */
    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setVerifyRoot(bytes32 _verifyRoot) external onlyOwner {
        verifyRoot = _verifyRoot;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrivateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        privateMerkleRoot = _merkleRoot;
    }

    /**
     * @notice Update buy and sell fees for transactions.
     * @dev Only callable by the contract owner. Sets fees for buy and sell transactions.
     * @param _fee The fee percentage to set for both buy and sell transactions.
     */
    function updateFees(uint256 _fee) external onlyOwner {
        buyFees = _fee;
        sellFees = _fee;
    }

    function updateBuyFees(uint256 _fee) external onlyOwner {
        buyFees = _fee;
    }

    function updateSellFees(uint256 _fee) external onlyOwner {
        sellFees = _fee;
    }

    function updatecontrollerWallet(
        address newcontrollerWallet
    ) external onlyOwner {
        emit controllerWalletUpdated(newcontrollerWallet, controllerWallet);
        controllerWallet = newcontrollerWallet;
    }

    /**
     * @notice Airdrop tokens to multiple addresses.
     * @dev Distributes specified amounts of tokens to a list of addresses. Only callable by the owner.
     * @param addresses Array of addresses to receive tokens.
     * @param amounts Array of token amounts corresponding to the addresses.
     */
    function airdrop(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(addresses.length > 0 && amounts.length == addresses.length);
        address from = msg.sender;

        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(from, addresses[i], amounts[i] * (10 ** 18));
        }
    }

    /**
     * @notice Internal transfer function with additional checks and fee handling.
     * @dev Overrides ERC20's _transfer. Handles trading limits, fees, and swap-and-liquify mechanism.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param amount The amount of tokens to transfer.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if ((launchedAt + blocks) >= block.number) {
                    // Starting Taxes
                    sellFees = 700;
                    buyFees = 700;
                }

                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }
            }
        }
        uint256 contractTokenBalance = accumalatedFees;

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            // Limit swaps per block
            if (blockSwaps[block.number] < 3) {
                swapping = true;

                swapBack();

                swapping = false;

                blockSwaps[block.number] = blockSwaps[block.number] + 1;
            }
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellFees > 0) {
                if (isAngelBuyer[from]) {
                    uint256 currentFee = getCurrentAngelFee();

                    fees = amount.mul(currentFee + sellFees).div(100 * 10 ** 2);
                } else if (isPrivateSaleBuyer[from]) {
                    uint256 currentFee = getCurrentFee();
                    fees = amount.mul(currentFee + sellFees).div(100 * 10 ** 2);
                } else {
                    fees = amount.mul(sellFees).div(100 * 10 ** 2);
                }
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyFees > 0) {
                if (isAngelBuyer[to]) {
                    uint256 currentFee = getCurrentAngelFee();

                    fees = amount.mul(currentFee + buyFees).div(100 * 10 ** 2);
                } else if (isPrivateSaleBuyer[to]) {
                    uint256 currentFee = getCurrentFee();

                    fees = amount.mul(currentFee + buyFees).div(100 * 10 ** 2);
                } else {
                    fees = amount.mul(buyFees).div(100 * 10 ** 2);
                }
            }

            if (fees > 0) {
                accumalatedFees += fees;
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }
        if (isAngelBuyer[from] && !automatedMarketMakerPairs[to]) {
            isAngelBuyer[to] = true;
        } else if (isPrivateSaleBuyer[from] && !automatedMarketMakerPairs[to]) {
            isPrivateSaleBuyer[to] = true;
        }
        super._transfer(from, to, amount);
    }

    /**
     * @notice View function to get the current dynamic fee for private sale buyers.
     * @dev Calculates the fee based on the time elapsed since start date. Fee decreases daily.
     * @return uint256 The current fee percentage.
     */
    function getCurrentFee() public view returns (uint256) {
        uint256 daysPassed = (block.timestamp - startDate) / 60 / 60 / 24;

        // Check if the fee would go negative and return 0 in that case
        if (daysPassed * dailyDecrease >= initialFee) {
            return 0;
        }

        // Calculate the current fee, knowing now it won't underflow
        uint256 currentFee = initialFee - (daysPassed * dailyDecrease);

        return currentFee;
    }

    function adminVerify(address _address, bool _state) external onlyOwner {
        isVerified[_address] = _state;
    }

    function adminAngelBuyer(address _address, bool _state) external onlyOwner {
        isAngelBuyer[_address] = _state;
    }

    function adminPrivateBuyer(
        address _address,
        bool _state
    ) external onlyOwner {
        isPrivateSaleBuyer[_address] = _state;
    }

    /**
     * @notice View function to get the current dynamic fee for angel investors.
     * @dev Similar to getCurrentFee but with different parameters for angel investors.
     * @return uint256 The current fee percentage.
     */
    function getCurrentAngelFee() public view returns (uint256) {
        uint256 daysPassed = (block.timestamp - startDate) / 60 / 60 / 24;

        // Check if the fee would go negative and return 0 in that case
        if (daysPassed * angelDailyDecrease >= angelInitialFee) {
            return 0;
        }

        // Calculate the current fee, knowing now it won't underflow
        uint256 currentFee = angelInitialFee -
            (daysPassed * angelDailyDecrease);

        return currentFee;
    }

    /**
     * @notice Swap tokens in contract for ETH and send to controller wallet.
     * @dev Private function to swap contract's token balance for ETH. Used in swapBack mechanism.
     * @param tokenAmount The amount of tokens to swap.
     */
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @notice Swap contract's tokens for ETH and handle liquidity and controller wallet transfers.
     * @dev Private function to facilitate swap and liquify. Called within _transfer when conditions are met.
     */
    function swapBack() private {
        uint256 contractBalance = accumalatedFees;
        bool success;

        if (contractBalance == 0) {
            return;
        }

        uint256 amountToSwapForETH = contractBalance;

        swapTokensForEth(amountToSwapForETH);

        uint256 totalETH = address(this).balance;
        accumalatedFees = 0;
        (success, ) = address(controllerWallet).call{value: totalETH}("");
    }
}