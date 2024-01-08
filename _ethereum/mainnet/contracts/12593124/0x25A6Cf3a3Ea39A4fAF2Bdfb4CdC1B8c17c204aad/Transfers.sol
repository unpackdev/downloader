pragma solidity >=0.5.17 <=0.8.0;


import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./OneSplitAudit.sol";
import "./Uni.sol";

contract Transfers {
    using SafeERC20 for IERC20;

    address constant onesplit = address(0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E);
//    address constant onesplit = address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
    address constant uni = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /**
     * [
     *   "Uniswap",
     *   "Kyber",
     *   "Bancor",
     *   "Oasis",
     *   "CurveCompound",
     *   "CurveUsdt",
     *   "CurveY",
     *   "Binance",
     *   "Synthetix",
     *   "UniswapCompound",
     *   "UniswapChai",
     *   "UniswapAave"
     * ]
     *   @param _fromToken will be swaped token
     *   @param _destToken you want token
     *   @param _amount will be swaped token amount
     **/
    function swap(
        address _fromToken,
        address _destToken,
        uint256 _amount,
        uint256 _miniReturn
    ) public returns (uint256) {
        if (_amount <= 0) {
            return 0;
        }
        uint256 _parts = 1;
        //拆包，最大拆100个，最小为1个
        uint256 decimals = ERC20(_fromToken).decimals();




        if (_amount / (10**decimals) / 1000 > 0) {
            _parts = 10;
        }

        // IERC20(_fromToken).safeApprove(onesplit, 0);
        // IERC20(_fromToken).safeApprove(onesplit, _amount);
        uint256[] memory _distribution;
        uint256 _expected;

        //setp 1：到交易所查询可兑换目标币的数量
        (_expected, _distribution) = OneSplitAudit(onesplit).getExpectedReturn(
            _fromToken,
            _destToken,
            _amount,
            _parts,
            0
        );

        require(_expected >= _miniReturn,"Slippage limit exceeded!");
        if (_expected == 0) {
            return 0;
        }


        // //setp 2：把sender的源代币转入到当前地址
        // IERC20(_fromToken).safeTransferFrom(msg.sender, address(this), _amount);

        IERC20(_fromToken).safeApprove(onesplit, 0);
        IERC20(_fromToken).safeApprove(onesplit, _amount);

        //setp 3：把源代币转换为目标代币
        OneSplitAudit(onesplit).swap(_fromToken, _destToken, _amount, _expected, _distribution, 0);


        //setp 4: 把目标代币转给sender
        // IERC20(_destToken).safeTransfer(msg.sender, _expected);
        return _expected;
    }

    /**
     * @param _path 要兑换币的路由，第一个元素是输入的代币，最后一个元素是输出的代币，该数组长度至少大于等于2，
     *              如果有直接兑换的交易对的话，那就长度为2，如果没有直接兑换的交易对，需要中间代币转换的，
     *              那么长度就是大于2 。中间的元素就是需要转换的到输出代币的路由
     * @param _amount 输入代币的数量
     */
    function uniSwap(address[] calldata _path, uint256 _amount) external returns (uint256 returnAmount) {
        require(_path.length >= 2, 'path.length>=2');
        if (_amount <= 0) {
            return 0;
        }
        IERC20(_path[0]).safeApprove(uni, 0);
        IERC20(_path[0]).safeApprove(uni, _amount);
        Uni(uni).swapExactTokensForTokens(_amount, uint256(0), _path, address(this), block.timestamp + 1800);
        uint256 _wantAmount = IERC20(_path[_path.length - 1]).balanceOf(address(this));


        return _wantAmount;
    }

    /*
     * 获取预期能兑换到目标代币的数量
     */
    function getExpectedAmount(
        address _fromToken,
        address _destToken,
        uint256 _amount
    ) public view returns (uint256) {
        if (_amount <= 0) {
            return 0;
        }
        uint256 _parts = 1;
        //拆包，最大拆100个，最小为1个
        if (_amount / 100 > 0) {
            _parts = 100;
        } else if (_amount / 10 > 0) {
            _parts = 10;
        }
        uint256[] memory _distribution;
        uint256 _expected;
        (_expected, _distribution) = OneSplitAudit(onesplit).getExpectedReturn(
            _fromToken,
            _destToken,
            _amount,
            _parts,
            0
        );
        return _expected;
    }
}
