// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "./IBLXMTreasuryManager.sol";
import "./BLXMMultiOwnable.sol";

import "./ITreasury.sol";
import "./IRatioAdmin.sol";
import "./BLXMLibrary.sol";
import "./Math.sol";


contract BLXMTreasuryManager is BLXMMultiOwnable, IBLXMTreasuryManager {

    using SafeMath for uint;

    // token => treasury
    mapping(address => address) internal treasuries;
    // rewards token or black list
    mapping(address => bool) internal exclude;
    // ratio admin address
    address public ratioAdmin;


    function putTreasury(address token, address treasury) external override onlyOwner {
        _validateToken(token);
        BLXMLibrary.validateAddress(treasury);

        address oldTreasury = treasuries[token];
        treasuries[token] = treasury;
        emit TreasuryPut(msg.sender, oldTreasury, treasury, token);
    }

    function getTreasury(address token) public view override returns (address treasury) {
        _validateToken(token);
        BLXMLibrary.validateAddress(treasury = treasuries[token]);
    }

    function getReserves(address token) public view override returns (uint reserveBlxm, uint reserveToken) {
        (reserveBlxm, reserveToken,,,,) = ITreasury(getTreasury(token)).get_total_amounts();
    }

    function updateRatioAdmin(address _ratioAdmin) external override onlyOwner {
        BLXMLibrary.validateAddress(_ratioAdmin);
        ratioAdmin = _ratioAdmin;
    }

    function getRatio(address token) public view override returns (uint ratio) {
        getTreasury(token);
        ratio = IRatioAdmin(ratioAdmin).getRatio(token);
        assert(ratio != 0);
    }

    function _withdraw(address token, uint rewards, uint liquidity, address to) internal returns (uint amountBlxm, uint amountToken) {
        uint _ratio = getRatio(token);

        // Liquidity must be multiplied by sqrt(10 ** 18) == 10 ** 9,
        // because the decimal of sqrt(ratio) will be 10 ** 9
        amountToken = liquidity.mul(10 ** 9) / Math.sqrt(_ratio);
        amountBlxm = amountToken.wmul(_ratio);

        ITreasury(getTreasury(token)).get_tokens(rewards, amountBlxm, amountToken, to);
    }

    function _notify(address token, uint amountBlxm, uint amountToken, address to) internal {
        ITreasury(getTreasury(token)).add_liquidity(amountBlxm, amountToken, to);
    }

    function _validateToken(address token) internal view {
        require(!exclude[token], 'INVALID_TOKEN');
        BLXMLibrary.validateAddress(token);
    }

    /**
    * This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}