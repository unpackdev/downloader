pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

import "./AddressUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./Initializable.sol";

import "./INFT20Pair.sol";
import "./INFT20Factory.sol";

interface Uni {
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface UniV3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    function refundETH() external payable;

    function unwrapWETH9(uint256 amountMinimum, address recipient)
        external
        payable;

    function multicall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);
}

interface weth {
    function withdraw(uint256 wad) external;
}

contract NFT20CasUpgreadableV1 is OwnableUpgradeable {
    using AddressUpgradeable for address;

    address public UNIV2;
    address public UNIV3;
    address public WETH;
    address public ETH;

    INFT20Factory public NFT20;

    function initialize() public initializer {
        __Ownable_init();
        UNIV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        UNIV3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        NFT20 = INFT20Factory(0x0f4676178b5c53Ae0a655f1B19A96387E4b8B5f2);
    }

    receive() external payable {}

    function setNFT20(address _registry) public onlyOwner {
        NFT20 = INFT20Factory(_registry);
    }

    function withdrawEth() public payable {
        address payable _to = payable(
            0x6fBa46974b2b1bEfefA034e236A32e1f10C5A148
        ); //multisig
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    //buy
    function ethForNft(
        address _nft,
        uint256[] memory _toIds,
        uint256[] memory _toAmounts,
        address _receipient,
        uint24 _fee,
        bool isV3
    ) public payable {
        uint256 balance_before = address(this).balance > msg.value
            ? address(this).balance - msg.value
            : 0;

        // we get the token
        address token20 = NFT20.nftToToken(_nft);

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _toAmounts.length; i++) {
            totalAmount += _toAmounts[i];
        }

        // calls uniswap contract to swap eth to token20

        if (isV3) {
            swapETHForExactERC20V3(token20, totalAmount * 100 ether, _fee);
        } else {
            swapETHForExactERC20(
                token20,
                address(this),
                totalAmount * 100 ether
            );
        }

        // withdraw nft by burning token20
        INFT20Pair(token20).withdraw(_toIds, _toAmounts, _receipient);

        uint256 balance_after = address(this).balance;

        uint256 dust = balance_after - balance_before;
        uint256 fees = ((msg.value - dust) * 5) / 100;

        if (dust - fees > 0) {
            (bool success, ) = _receipient.call{value: dust - fees}("");
            require(success, "swapEthForERC721: ETH dust transfer failed.");
        }
    }

    // requires setApprovalForAll of NFT contract to this address
    function nftForEth(
        address _nft,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bool isErc721,
        uint24 _fee,
        bool isV3
    ) external {
        address token20 = NFT20.nftToToken(_nft);

        if (isErc721) {
            for (uint256 i = 0; i < _ids.length; i++) {
                IERC721(_nft).safeTransferFrom(
                    msg.sender,
                    token20,
                    _ids[i],
                    abi.encodePacked(address(this))
                );
            }
        } else {
            if (_ids.length == 1) {
                IERC1155(_nft).safeTransferFrom(
                    msg.sender,
                    token20,
                    _ids[0],
                    _amounts[0],
                    abi.encodePacked(address(this))
                );
            } else {
                IERC1155(_nft).safeBatchTransferFrom(
                    msg.sender,
                    token20,
                    _ids,
                    _amounts,
                    abi.encodePacked(address(this))
                );
            }
        }

        if (isV3) {
            swapERC20ForExactETHV3(
                token20,
                msg.sender,
                IERC20(token20).balanceOf(address(this)),
                _fee
            );
        } else {
            // swap the token 20 for eth and send to user
            swapERC20ForExactETH(
                token20,
                msg.sender,
                IERC20(token20).balanceOf(address(this))
            );
        }
    }

    function swapERC20ForExactETH(
        address _from,
        address _recipient,
        uint256 amount
    ) internal returns (uint256[] memory amounts) {
        uint256 _bal = IERC20(_from).balanceOf(address(this));
        IERC20(_from).approve(UNIV2, _bal);

        address[] memory _path = new address[](2);
        _path[0] = _from;
        _path[1] = WETH;

        uint256[] memory amts = Uni(UNIV2).swapExactTokensForETH(
            amount,
            0,
            _path,
            address(this),
            block.timestamp + 1800
        );

        payable(_recipient).transfer((amts[1] * 95) / 100);
        return amts;
    }

    function swapETHForExactERC20(
        address _to,
        address _recipient,
        uint256 _amountOut
    ) internal {
        address[] memory _path = new address[](2);
        _path[0] = WETH;
        _path[1] = _to;

        bytes memory _data = abi.encodeWithSelector(
            Uni(UNIV2).swapETHForExactTokens.selector,
            _amountOut,
            _path,
            _recipient,
            block.timestamp + 1800
        );

        (bool success, ) = UNIV2.call{value: msg.value}(_data);
        require(success, "_swapETHForExactERC20: uniswap swap failed.");
    }

    function swapERC20ForExactETHV3(
        address _from,
        address _recipient,
        uint256 _amount,
        uint24 _fee
    ) internal returns (uint256 amount) {
        uint256 _bal = IERC20(_from).balanceOf(address(this));

        IERC20(_from).approve(UNIV3, _bal);

        UniV3.ExactInputSingleParams memory params;
        params.tokenIn = _from;
        params.tokenOut = WETH;
        params.fee = _fee;
        params.amountIn = _amount;
        params.amountOutMinimum = 0;
        params.sqrtPriceLimitX96 = 0;
        params.deadline = block.timestamp;
        params.recipient = address(this);

        // swap
        uint256 receivedEth = UniV3(UNIV3).exactInputSingle(params);

        weth(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));

        payable(_recipient).transfer((receivedEth * 95) / 100);

        return receivedEth;
    }

    function swapETHForExactERC20V3(
        address _to,
        uint256 _amountOut,
        uint24 _fee
    ) internal {
        UniV3.ExactOutputSingleParams memory params;
        params.tokenIn = WETH;
        params.tokenOut = _to;
        params.fee = _fee; // Need to pass the fees... :(
        params.amountOut = _amountOut;
        params.amountInMaximum = msg.value;
        params.sqrtPriceLimitX96 = 0;
        params.deadline = block.timestamp;
        params.recipient = address(this);
        UniV3(UNIV3).exactOutputSingle{value: msg.value}(params);
        UniV3(UNIV3).refundETH();
        // Needto make sure the swap worked
    }
}
