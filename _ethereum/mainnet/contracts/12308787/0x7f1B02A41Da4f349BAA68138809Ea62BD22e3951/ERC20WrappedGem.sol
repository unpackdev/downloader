// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./SafeMath.sol";
import "./ERC20Constructorless.sol";
import "./Initializable.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./INFTGemPoolData.sol";
import "./IERC20WrappedGem.sol";
import "./INFTGemMultiToken.sol";

import "./ERC1155Holder.sol";

contract ERC20WrappedGem is ERC20Constructorless, ERC1155Holder, IERC20WrappedGem, Initializable {
    using SafeMath for uint256;

    address private token;
    address private pool;
    uint256 private rate;

    uint256[] private ids;
    uint256[] private amounts;

    function initialize(
        string memory name,
        string memory symbol,
        address gemPool,
        address gemToken,
        uint8 decimals
    ) external override initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        token = gemToken;
        pool = gemPool;
    }

    function _transferERC1155(
        address from,
        address to,
        uint256 quantity
    ) internal {
        uint256 tq = quantity;
        delete ids;
        delete amounts;

        uint256 i = INFTGemMultiToken(token).allHeldTokensLength(from);
        require(i > 0, "INSUFFICIENT_GEMS");

        for (; i >= 0 && tq > 0; i = i.sub(1)) {
            uint256 tokenHash = INFTGemMultiToken(token).allHeldTokens(from, i);
            if (INFTGemPoolData(pool).tokenType(tokenHash) == 2) {
                uint256 oq = IERC1155(token).balanceOf(from, tokenHash);
                uint256 toTransfer = oq > tq ? tq : oq;
                ids.push(tokenHash);
                amounts.push(toTransfer);
                tq = tq.sub(toTransfer);
            }
            if (i == 0) break;
        }

        require(tq == 0, "INSUFFICIENT_GEMS");

        IERC1155(token).safeBatchTransferFrom(from, to, ids, amounts, "");
    }

    function wrap(uint256 quantity) external override {
        require(quantity != 0, "ZERO_QUANTITY");

        _transferERC1155(msg.sender, address(this), quantity);
        _mint(msg.sender, quantity.mul(10**decimals()));
        emit Wrap(msg.sender, quantity);
    }

    function unwrap(uint256 quantity) external override {
        require(quantity != 0, "ZERO_QUANTITY");
        require(balanceOf(msg.sender).mul(10**decimals()) >= quantity, "INSUFFICIENT_QUANTITY");

        _transferERC1155(address(this), msg.sender, quantity);
        _burn(msg.sender, quantity.mul(10**decimals()));
        emit Unwrap(msg.sender, quantity);
    }
}
