pragma solidity >=0.5.17 <0.8.4;

import "./IERC20.sol";

interface ICurveFi {
    /**
     * 返回一个lpToken对应的价值
     * return：一个lpToken的价值，单位是DAI，精度为1e18
     **/
    function get_virtual_price() external view returns (uint256);

    /**
     * 增加流动性接口
     * amounts：是一个数组，代表要投入的币种组合，amounts[0]是EURS的数量，amounts[1]是SEUR的数量
     * min_mint_amount：最小铸币数量，期望得到的最小lpToken数量
     * return：返回投资凭证数
     **/
    function add_liquidity(
        // EURs
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // sBTC pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    /**
     * 移除流动性接口,提款金额基于活期存款比率
     * _amount：需要提取的lpToken数量
     * min_amounts：期望返回的最小代币数，min_amounts[0]是EURS的数量，min_amounts[1]是SEUR的数量
     * return：实际返回的代币数量
     **/
    function remove_liquidity(uint256 _amount, uint256[2] calldata min_amounts) external returns (uint256[2] memory);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function exchange(
        int128 from, //源币索引
        int128 to, //目标币索引
        uint256 _from_amount, //源币数量
        uint256 _min_to_amount //期望的最少目标币数量
    ) external;

    /**
     * 余额查询
     * index：0-EURS,1-SEUR
     * return：余额
     **/
    function balances(uint256) external view returns (uint256);
}
