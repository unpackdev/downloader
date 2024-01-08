pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "./Ownable.sol";
import "./IUniswapRouter.sol";
import "./ISharer.sol";
import "./IStrategy.sol";
import "./IVault.sol";

interface IWETH9 is IERC20 {
    function withdraw(uint256 amount) external;
}

contract StrategistProfiter is Ownable {
    using Address for address payable;
    using SafeERC20 for IERC20;
    using SafeERC20 for IVault;

    struct StrategyConf {
        IStrategy Strat;
        IVault vault;
        IERC20 want;
        IERC20 sellTo;
        bool transferToSelfDirectly;
        address router;
    }

    StrategyConf[] internal strategies;

    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    IWETH9 iWETH = IWETH9(WETH);
    ISharer public sharer = ISharer(0xc491599b9A20c3A2F0A85697Ee6D9434EFa9f503);

    event Cloned(address payable newDeploy);
    event AddedStrategy(address indexed strategy, address want, address sellTo);
    event RemovedStrategy(address indexed strategy, address want, address sellTo);
    event NoTokensToSwap(address indexed strategy);

    receive() external payable {}

    address internOwner;

    constructor() {
        internOwner = msg.sender;
    }

    function getCurrentOwner() public view returns (address) {
        if (owner() != address(0)) return owner();
        return internOwner;
    }

    modifier onlyCurrentOwner {
        address curOwner = getCurrentOwner();
        if (curOwner != address(0)) require(msg.sender == curOwner, "Caller is not owner");
        //If owner is null allow call
        _;
    }

    function setInternOwner(address _newIntern) external onlyCurrentOwner {
        internOwner = _newIntern;
    }

    function clone() external returns (address payable newProfiter) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newProfiter := create(0, clone_code, 0x37)
        }
        StrategistProfiter(newProfiter).setInternOwner(msg.sender);
        emit Cloned(newProfiter);
    }

    function getStrategies() external view returns (StrategyConf[] memory) {
        return strategies;
    }

    function getStrategiesList() external view returns (address[] memory stratarray) {
        stratarray = new address[](strategies.length);
        for (uint256 i = 0; i < stratarray.length; i++) {
            stratarray[i] = address(strategies[i].Strat);
        }
    }

    function removeStrat(uint256 index) external onlyCurrentOwner {
        emit RemovedStrategy(address(strategies[index].Strat), address(strategies[index].want), address(strategies[index].sellTo));
        delete strategies[index];
        strategies.pop();
    }

    function getTokenOutPath(address _token_in, address _token_out) internal view returns (address[] memory path) {
        bool is_weth = _token_in == WETH || _token_out == WETH;
        path = new address[](is_weth ? 2 : 3);
        path[0] = _token_in;
        if (is_weth) {
            path[1] = _token_out;
        } else {
            path[1] = WETH;
            path[2] = _token_out;
        }
    }

    function addStrat(
        address strategy,
        address sellTo,
        bool useSushiToSell
    ) external onlyCurrentOwner {
        IStrategy _strat = IStrategy(strategy);
        IERC20 _want = IERC20(_strat.want());
        IVault _vault = IVault(_strat.vault());
        strategies.push(
            StrategyConf({
                Strat: _strat,
                vault: _vault,
                want: _want,
                sellTo: IERC20(sellTo),
                transferToSelfDirectly: _vault.rewards() == address(this),
                router: useSushiToSell ? sushiRouter : uniRouter
            })
        );
        emit AddedStrategy(strategy, address(_want), sellTo);
    }

    function claimandSwap() external onlyCurrentOwner {
        for (uint256 i = 0; i < strategies.length; i++) {
            uint256 stratRewardsbal = strategies[i].vault.balanceOf(address(strategies[i].Strat));
            if (stratRewardsbal > 0) {
                if (!strategies[i].transferToSelfDirectly) {
                    //Call dist to get the vault tokens
                    sharer.distribute(address(strategies[i].Strat));
                    //Call transfer from msg.sender
                    strategies[i].vault.safeTransferFrom(msg.sender, address(this), strategies[i].vault.balanceOf(msg.sender));
                } else {
                    //else just transfer from the strategy directly to this contract
                    strategies[i].vault.safeTransferFrom(
                        address(strategies[i].Strat),
                        address(this),
                        stratRewardsbal
                    );
                }
                if (strategies[i].vault.balanceOf(address(this)) > 0) {
                    //Withdraw tokens to want
                    strategies[i].vault.withdraw();
                    sellToWETH(strategies[i].want, strategies[i].sellTo, strategies[i].router);
                }
            } else {
                emit NoTokensToSwap(address(strategies[i].Strat));
            }
        }
        uint256 wethbal = iWETH.balanceOf(address(this));
        if (wethbal > 0) iWETH.withdraw(wethbal);
        msg.sender.sendValue(wethbal);
    }

    function sellToWETH(
        IERC20 _want,
        IERC20 _sellTo,
        address router
    ) internal {
        uint256 sellAmount = _want.balanceOf(address(this));
        address[] memory swapPath = getTokenOutPath(address(_want), address(_sellTo));
        //First approve to spend want
        _want.safeApprove(router, sellAmount);
        //Swap to sellto via path
        IUniswapRouter(router).swapExactTokensForTokens(sellAmount, 0, swapPath, address(this), block.timestamp);
    }

    function retrieveETH() external onlyCurrentOwner {
        msg.sender.sendValue(address(this).balance);
    }

    function retreiveToken(address token) external onlyCurrentOwner {
        IERC20 iToken = IERC20(token);
        iToken.transfer(owner(), iToken.balanceOf(address(this)));
    }

    function updateSharer(address _newSharer) external onlyCurrentOwner {
        sharer = ISharer(_newSharer);
    }

    function updateWETH(address _newWETH) external onlyCurrentOwner {
        WETH = _newWETH;
        iWETH = IWETH9(WETH);
    }

    function updateUniRouter(address _newRouter) external onlyCurrentOwner {
        uniRouter = _newRouter;
    }

    function updateSushiRouter(address _newRouter) external onlyCurrentOwner {
        sushiRouter = _newRouter;
    }
}
