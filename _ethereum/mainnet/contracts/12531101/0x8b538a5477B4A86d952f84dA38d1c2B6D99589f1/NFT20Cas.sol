//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./Ownable.sol";

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

contract NFT20Cas is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    address public DEX = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    INFT20Factory public NFT20 =
        INFT20Factory(0x0f4676178b5c53Ae0a655f1B19A96387E4b8B5f2);

    constructor() {}

    receive() external payable {}

    function setNFT20(address _registry) public onlyOwner {
        NFT20 = INFT20Factory(_registry);
    }

    function withdrawEth() public payable {
        address payable _to =
            payable(0x6fBa46974b2b1bEfefA034e236A32e1f10C5A148); //multisig
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    //buy
    function ethForNft(
        address _nft,
        uint256[] memory _toIds,
        uint256[] memory _toAmounts,
        address _receipient
    ) public payable {
        uint256 balance_before =
            address(this).balance > msg.value
                ? address(this).balance - msg.value
                : 0;

        // we get the token
        address token20 = NFT20.nftToToken(_nft);

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _toAmounts.length; i++) {
            totalAmount += _toAmounts[i];
        }

        // calls uniswap contract to swap eth to token20
        swapETHForExactERC20(token20, address(this), totalAmount * 100 ether);

        // withdraw nft by burning token20
        INFT20Pair(token20).withdraw(_toIds, _toAmounts, _receipient);

        uint256 balance_after = address(this).balance;

        uint256 dust = balance_after - balance_before;
        uint256 fees = ((msg.value - dust) * 5) / 100;

        if (dust - fees > 0) {
            // Return the change ETH back to the user.
            (bool success, ) = _receipient.call{value: dust - fees}("");
            require(success, "swapEthForERC721: ETH dust transfer failed.");
        }
    }

    // requires setApprovalForAll of NFT contract to this address
    function nftForEth(
        address _nft,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bool isErc721
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

        // swap the token 20 for eth and send to user
        swapERC20ForExactETH(
            token20,
            msg.sender,
            IERC20(token20).balanceOf(address(this))
        );
    }

    function swapERC20ForExactETH(
        address _from,
        address _recipient,
        uint256 amount
    ) internal returns (uint256[] memory amounts) {
        uint256 _bal = IERC20(_from).balanceOf(address(this));
        IERC20(_from).safeApprove(DEX, _bal);

        address[] memory _path = new address[](2);
        _path[0] = _from;
        _path[1] = WETH;

        uint256[] memory amts =
            Uni(DEX).swapExactTokensForETH(
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
        uint256 _amountOut /* returns (uint256[] memory amounts) */
    ) internal {
        address[] memory _path = new address[](2);
        _path[0] = WETH;
        _path[1] = _to;

        bytes memory _data =
            abi.encodeWithSelector(
                Uni(DEX).swapETHForExactTokens.selector,
                _amountOut,
                _path,
                _recipient,
                block.timestamp + 1800
            );

        (bool success, ) = DEX.call{value: msg.value}(_data);
        require(success, "_swapETHForExactERC20: uniswap swap failed.");
    }
}
