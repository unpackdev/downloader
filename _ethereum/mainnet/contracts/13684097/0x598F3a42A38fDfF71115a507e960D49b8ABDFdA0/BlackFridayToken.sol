pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Factory.sol";



//
// $BFRY - BlackFriday token for the Crypto Space
//
//      << Because in the crypto space, black friday is everyday! >>
//
// Find out more on https://bfry.io
//


contract BlackFridayToken is Context, ERC20, Ownable {
    using Address for address;

    uint maxSupply = 10 * 10**9 * 10**18;
    uint public creationTimestamp = 0;
    uint vestingForLPClaim = 45;
    uint feePerc = 8;

    mapping (address => uint) public liquidityMinted;
    mapping (address => bool) public excluded;
    mapping (address => bool) public pauseManagers;

    address public immutable uniswapV2Pair;
    IUniswapV2Router01 public immutable uniswapV2Router;
    address treasury;

    bool feePaused = false;
    bool LPTreasuryBulkClaimed = false;

    constructor(address _treasury) ERC20("Black Friday", "BFRY") {
        // create uniswap pair
        IUniswapV2Router01 _uniswapV2Router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        // set creation data
        creationTimestamp = block.timestamp;
        treasury = _treasury;
        excluded[address(this)] = true;
        pauseManagers[address(this)] = true;
    }

    modifier onlyPauseManagers {
        require(pauseManagers[msg.sender], "Only pauseManagers can call this method");
        _;
    }

    function mint() public payable {
        require(msg.value >= 0.05 ether, "At least 0.05 Ether are required to mint");
        uint amount = (maxSupply / 2) * msg.value / 100 ether;
        require(totalSupply() + (amount*2) <= maxSupply, "No more tokens can be minted");
        _mint(msg.sender, amount);
        _mint(address(this), amount);
        _approve(address(this), address(uniswapV2Router), amount);
        feePaused = true;
        (uint amountToken, uint amountETH, uint liquidity) = uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this), amount, 0,  0, address(this), block.timestamp
        );
        if (balanceOf(address(this))>0)
            _transfer(address(this), treasury, balanceOf(address(this)));
        liquidityMinted[msg.sender] += liquidity;
        feePaused = false;
    }

    function claimLP() public {
        require(block.timestamp - 60*60*24*vestingForLPClaim > creationTimestamp, "You need to wait 45 days before claiming the LP tokens you own");
        require(liquidityMinted[msg.sender] > 0, "You haven't minted any liquidity");
        uint halfLiquidity = liquidityMinted[msg.sender] / 2;
        ERC20 pairV2 = ERC20(uniswapV2Pair);
        pairV2.transfer(msg.sender, halfLiquidity);
        if (!LPTreasuryBulkClaimed)
            pairV2.transfer(treasury, liquidityMinted[msg.sender] - halfLiquidity);
        liquidityMinted[msg.sender] = 0;
    }

    // transfer sending the fee to the treasury
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (feePaused || excluded[sender]) {
            super._transfer(sender, recipient, amount);
        } else {
            uint fee = amount * feePerc / 100;
            uint remain = amount - fee;
            super._transfer(sender, recipient, remain);
            super._transfer(sender, treasury, fee);
        }
    }

    function toggleExcludedAddress (address a, bool state) public onlyOwner {
        excluded[a] = state;
    }

    function pauseFee (bool status) external onlyPauseManagers {
        feePaused = status;
    }

    function claimLPBulk () public onlyOwner {
        require(block.timestamp - 60*60*24*vestingForLPClaim > creationTimestamp, "You need to wait 45 days before claiming the LP tokens you own");
        ERC20 pairV2 = ERC20(uniswapV2Pair);
        uint balance = pairV2.balanceOf(address(this));
        pairV2.transfer(owner(), (balance/2) - 1);
        LPTreasuryBulkClaimed = true;
    }

    function setPauseManager (address a, bool state) public onlyOwner {
        pauseManagers[a] = state;
    }

    function setFeePerc (uint _newFee) public onlyOwner {
        require(_newFee < 15, "Fee too high");
        feePerc = _newFee;
    }


}