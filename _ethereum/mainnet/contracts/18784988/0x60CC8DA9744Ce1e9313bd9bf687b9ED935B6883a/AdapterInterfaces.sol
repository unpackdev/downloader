// SPDX-License-Identifier: --DAO--

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

pragma solidity =0.8.21;

import "./IERC20.sol";

interface IChainLink {

    function decimals()
        external
        view
        returns (uint8);

    function latestAnswer()
        external
        view
        returns (uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answerdInRound
        );

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function phaseId()
        external
        view
        returns(
            uint16 phaseId
        );

    function aggregator()
        external
        view
        returns (address);

    function description()
        external
        view
        returns (string memory);
}

interface ITokenProfit {

    function redeemRewards(
        uint256 _burnAmount
    )
        external
        returns (
            uint256,
            uint256[] memory
        );

    function changeAdapter(
        address _newAdapter
    )
        external;

    function getAvailableMint()
        external
        view
        returns (uint256);

    function executeAdapterRequest(
        address _contractToCall,
        bytes memory _callBytes
    )
        external
        returns (bytes memory);

    function executeAdapterRequestWithValue(
        address _contractToCall,
        bytes memory _callBytes,
        uint256 _value
    )
        external
        returns (bytes memory);

    function totalSupply()
        external
        view
        returns (uint256);

    function adapter()
        external
        view
        returns (address);
}

interface ILiquidNFTsRouter {

    function depositFunds(
        uint256 _amount,
        address _pool
    )
        external;

    function withdrawFunds(
        uint256 _amount,
        address _pool
    )
        external;
}

interface ILiquidNFTsPool {

    function pseudoTotalTokensHeld()
        external
        view
        returns (uint256);

    function totalInternalShares()
        external
        view
        returns (uint256);

    function manualSyncPool()
        external;

    function internalShares(
        address _user
    )
        external
        view
        returns (uint256);

    function poolToken()
        external
        view
        returns (address);

    function chainLinkETH()
        external
        view
        returns (address);
}

interface IUniswapV2 {

    function swapExactETHForTokens(
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        payable
        returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        returns (uint256[] memory amounts);
}

interface IWETH is IERC20 {

    function deposit()
        payable
        external;

    function withdraw(
        uint256 _amount
    )
        external;
}

interface IWiseLending {

    function depositExactAmount(
        uint256 _nftId,
        address _underlyingToken,
        uint256 _depositAmount
    )
        external
        payable
        returns (uint256);

    function withdrawExactAmount(
        uint256 _nftId,
        address _underlyingToken,
        uint256 _withdrawAmount
    )
        external
        returns (uint256);

    function POSITION_NFT()
        external
        view
        returns (address);

    function WISE_SECURITY()
        external
        view
        returns (address);
}

interface IWiseSecurity {

    function getPositionLendingAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function maximumWithdrawToken(
        uint256 _nftId,
        address _poolToken,
        uint256 _interval,
        uint256 _solelyWithdrawAmount
    )
        external
        view
        returns (uint256);
}

interface IPositionNFTs {

    function mintPosition()
        external
        returns (uint256);

    function mintPositionForUser(
        address _user
    )
        external
        returns (uint256);

    function approve(
        address _to,
        uint256 _tokenId
    )
        external;

    function ownerOf(
        uint256 _nftId
    )
        external
        returns (address);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external;
}