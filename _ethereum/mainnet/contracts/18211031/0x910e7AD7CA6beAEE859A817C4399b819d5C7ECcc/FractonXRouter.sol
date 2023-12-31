// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IAccessControlUpgradeable.sol";

import "./IFractonXRouter.sol";
import "./IFractonXFactory.sol";
import "./IFractonXERC20.sol";

contract FractonXRouter is IFractonXRouter, Initializable {

    uint256 constant TEN_THOUSAND = 10000;

    address public factory;

    function initialize(address factory_) public initializer {
        factory = factory_;
    }

    function swapERC20ToERC721(address erc20Addr, uint256 amountERC20) external {
        IERC20Upgradeable(erc20Addr).transferFrom(msg.sender, factory, amountERC20);
        IFractonXFactory(factory).swapERC20ToERC721(erc20Addr, msg.sender);
    }

    function swapERC721ToERC20(address erc721Addr, uint256 tokenId) external {
        require(isWhitelistUser(msg.sender, erc721Addr) ||
            IFractonXFactory(factory).closeSwap721To20() == 2, "INVALID CALLER");
        IERC721Upgradeable(erc721Addr).safeTransferFrom(msg.sender, factory, tokenId);
        IFractonXFactory(factory).swapERC721ToERC20(erc721Addr, tokenId, msg.sender);
    }

    function isWhitelistUser(address user, address erc721Addr) public view returns(bool) {
        bytes32 salt = keccak256(abi.encode(erc721Addr));
        return IAccessControlUpgradeable(factory).hasRole(salt, user);
    }

    function getAmountERC20(address erc20Addr) external view returns(uint256 amountERC20) {
        IFractonXFactory.ERC20Info memory erc20Info = IFractonXFactory(factory).getERC20Info(erc20Addr);
        uint256 swapFeeRate = IFractonXFactory(factory).swapFeeRate();
        uint256 fee = swapFeeRate * 1 * erc20Info.swapRatio / TEN_THOUSAND;
        return fee + erc20Info.swapRatio;
    }

    function erc20TransferFeeRate(address erc20Addr) external view returns(uint256) {
        return IFractonXERC20(erc20Addr).erc20TransferFeerate();
    }
}

