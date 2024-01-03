/*
 * Capital DEX
 *
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Managed.sol";
import "./Pausable.sol";
import "./ICarTokenController.sol";

/**
 * @title DexWhitelist
 *
 * @dev The contract stores a whitelist of users (investors) and allows to
 * manage it. The contract also provides for a separate whitelist for tokens addresses.
 * It is possible to check the whitelisted status of users from the whitelist
 * located in the separate CarTokenController contract (part of security token contracts).
 * All user/tokens checks can be disabled by owner.
 *
 * CarTokenController contract source: https://github.com/CurioTeam/security-token-contracts/blob/dd5c82e566d24d0e87639316a9420afdb9b30e71/contracts/CarTokenController.sol
 */
contract DexWhitelist is Initializable, Managed, Pausable {
    ICarTokenController public controller;

    struct Investor {
        address addr;
        bool active;
    }

    /**
     * @dev Whitelist of users (investors)
     */
    mapping(bytes32 => Investor) public investors;
    mapping(address => bytes32) public keyOfInvestor;

    /**
     * @dev Whitelist of tokens
     */
    mapping(address => bool) public tokens;

    /**
     * @dev Enable/disable whitelist's statuses for several groups of operations.
     *
     * 'liquidity wl' - for operations with liquidity pools
     * 'swap wl' - for operations with swap mechanism
     * 'farm wl' - for operations with farming mechanism
     * 'token wl' - for whitelist of supported tokens
     */
    bool public isLiquidityWlActive;
    bool public isSwapWlActive;
    bool public isFarmWlActive;
    bool public isTokenWlActive;

    event SetController(address indexed controller);

    event AddNewInvestor(bytes32 indexed key, address indexed addr);
    event SetInvestorActive(bytes32 indexed key, bool active);
    event ChangeInvestorAddress(
        address indexed sender,
        bytes32 indexed key,
        address indexed oldAddr,
        address newAddr
    );

    event SetLiquidityWlActive(bool active);
    event SetSwapWlActive(bool active);
    event SetFarmWlActive(bool active);
    event SetTokenWlActive(bool active);

    event SetTokenAddressActive(address indexed token, bool active);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @dev Checks if an investor's account is whitelisted. Check is done
     * in the whitelist of the contract and also in the CarTokenController.
     *
     * @param _addr The address of investor's account to check.
     */
    function isInvestorAddressActive(address _addr) public view returns (bool) {
        return
            investors[keyOfInvestor[_addr]].active ||
            (
                address(controller) != address(0)
                    ? controller.isInvestorAddressActive(_addr)
                    : false
            );
    }

    /**
     * @dev Returns true if address is in investor's whitelist
     * or liquidity whitelist is not active.
     *
     * @param _addr The address of investor's account to check.
     */
    function isLiquidityAddressActive(address _addr)
        public
        view
        returns (bool)
    {
        return !isLiquidityWlActive || isInvestorAddressActive(_addr);
    }

    /**
     * @dev Returns true if address is in investor's whitelist
     * or swap whitelist is not active.
     *
     * @param _addr The address of investor's account to check.
     */
    function isSwapAddressActive(address _addr) public view returns (bool) {
        return !isSwapWlActive || isInvestorAddressActive(_addr);
    }

    /**
     * @dev Returns true if address is in investor's whitelist
     * or farm whitelist is not active.
     *
     * @param _addr The address of investor's account to check.
     */
    function isFarmAddressActive(address _addr) public view returns (bool) {
        return !isFarmWlActive || isInvestorAddressActive(_addr);
    }

    /**
     * @dev Returns true if address is in token's whitelist
     * or token's whitelist is not active.
     *
     * @param _addr The address of token to check.
     */
    function isTokenAddressActive(address _addr) public view returns (bool) {
        return !isTokenWlActive || tokens[_addr];
    }

    /**
     * @dev Allows the msg.sender change your address in whitelist.
     *
     * Requirements:
     * - the contract must not be paused.
     *
     * @param _investorKey The key of investor.
     * @param _newAddr The address of investor's account.
     */
    function changeMyAddress(bytes32 _investorKey, address _newAddr)
        external
        whenNotPaused
    {
        require(
            investors[_investorKey].addr == msg.sender,
            "Investor address and msg.sender does not match"
        );

        _changeInvestorAddress(_investorKey, _newAddr);
    }

    /**
     * @dev Allows the admin or manager to add new investors
     * to whitelist.
     *
     * Requirements:
     * - lengths of keys and address arrays should be equal.
     *
     * @param _keys The keys of investors.
     * @param _addrs The addresses of investors accounts.
     */
    function addNewInvestors(
        bytes32[] calldata _keys,
        address[] calldata _addrs
    ) external onlyAdminOrManager {
        uint256 len = _keys.length;
        require(
            len == _addrs.length,
            "Lengths of keys and address does not match"
        );

        for (uint256 i = 0; i < len; i++) {
            _setInvestorAddress(_keys[i], _addrs[i]);

            emit AddNewInvestor(_keys[i], _addrs[i]);
        }
    }

    /**
     * @dev Allows the admin or manager to change investor's
     * whitelisted status.
     *
     * Emits a {SetInvestorActive} event with investor's key and new status.
     *
     * Requirements:
     * - the investor must be added to whitelist.
     *
     * @param _key The keys of investor.
     * @param _active The new status of investor's account.
     */
    function setInvestorActive(bytes32 _key, bool _active)
        external
        onlyAdminOrManager
    {
        require(investors[_key].addr != address(0), "Investor does not exists");
        investors[_key].active = _active;

        emit SetInvestorActive(_key, _active);
    }

    /**
     * @dev Allows the admin to change investor's address.
     *
     * @param _investorKey The keys of investor.
     * @param _newAddr The new address of investor's account.
     */
    function changeInvestorAddress(bytes32 _investorKey, address _newAddr)
        external
        onlyAdmin
    {
        _changeInvestorAddress(_investorKey, _newAddr);
    }

    /**
     * @dev Allows the admin to set token's whitelisted status.
     *
     * @param _token The address of token.
     * @param _active The token status.
     */
    function setTokenAddressActive(address _token, bool _active)
        external
        onlyAdmin
    {
        _setTokenAddressActive(_token, _active);
    }

    /**
     * @dev Allows the admin to set tokens as whitelisted or not.
     *
     * Requirements:
     * - lengths of tokens and statuses arrays should be equal.
     *
     * @param _tokens The addresses of tokens.
     * @param _active The tokens statuses.
     */
    function setTokenAddressesActive(
        address[] calldata _tokens,
        bool[] calldata _active
    ) external onlyAdmin {
        uint256 len = _tokens.length;
        require(
            len == _active.length,
            "Lengths of tokens and active does not match"
        );

        for (uint256 i = 0; i < len; i++) {
            _setTokenAddressActive(_tokens[i], _active[i]);
        }
    }

    /**
     * @dev Allows the owner to set CarTokenController contract.
     *
     * Emits a {SetController} event with `controller` set to
     * CarTokenController contract's address.
     *
     * @param _controller The address of CarTokenController contract.
     */
    function setController(ICarTokenController _controller) external onlyOwner {
        controller = _controller;
        emit SetController(address(_controller));
    }

    /**
     * @dev Allows the owner to enable/disable investors whitelist functionality
     * for operations with liquidity pools.
     *
     * @param _active Investors whitelist check status.
     */
    function setLiquidityWlActive(bool _active) external onlyOwner {
        _setLiquidityWlActive(_active);
    }

    /**
     * @dev Allows the owner to enable/disable investors whitelist functionality
     * for operations with swap.
     *
     * @param _active Investors whitelist check status.
     */
    function setSwapWlActive(bool _active) external onlyOwner {
        _setSwapWlActive(_active);
    }

    /**
     * @dev Allows the owner to enable/disable investors whitelist functionality
     * for operations with farming mechanism.
     *
     * @param _active Investors whitelist check status.
     */
    function setFarmWlActive(bool _active) external onlyOwner {
        _setFarmWlActive(_active);
    }

    /**
     * @dev Allows the owner to enable/disable tokens whitelist functionality.
     *
     * @param _active Tokens whitelist check status.
     */
    function setTokenWlActive(bool _active) external onlyOwner {
        _setTokenWlActive(_active);
    }

    /**
     * @dev Allows the owner to enable/disable investors and tokens whitelist
     * for all groups of operations in single transaction.
     *
     * @param _liquidityWlActive Investors whitelist check status for liquidity pools operations.
     * @param _swapWlActive Investors whitelist check status for swap operations.
     * @param _farmWlActive Investors whitelist check status for farming operations.
     * @param _tokenWlActive Tokens whitelist check status.
     */
    function setWlActive(
        bool _liquidityWlActive,
        bool _swapWlActive,
        bool _farmWlActive,
        bool _tokenWlActive
    ) external onlyOwner {
        _setLiquidityWlActive(_liquidityWlActive);
        _setSwapWlActive(_swapWlActive);
        _setFarmWlActive(_farmWlActive);
        _setTokenWlActive(_tokenWlActive);
    }


    /**
     * @dev Saves the investor's key and address and sets the status as whitelisted.
     *
     * Requirements:
     * - key and address must be empty.
     *
     * @param _key The key of investor.
     * @param _addr The address of investor.
     */
    function _setInvestorAddress(bytes32 _key, address _addr) internal {
        require(investors[_key].addr == address(0), "Investor already exists");
        require(keyOfInvestor[_addr] == bytes32(0), "Address already claimed");

        investors[_key] = Investor(_addr, true);
        keyOfInvestor[_addr] = _key;
    }

    /**
     * @dev Changes the address of the investor with the given key.
     *
     * Emits a {ChangeInvestorAddress} event with parameters: `sender` as msg.sender,
     * `key`, `oldAddr`, `newAddr`.
     *
     * Requirements:
     * - the new address must be different from the old one.
     *
     * @param _investorKey The key of investor.
     * @param _newAddr The new address of investor.
     */
    function _changeInvestorAddress(bytes32 _investorKey, address _newAddr)
        internal
    {
        address oldAddress = investors[_investorKey].addr;
        require(oldAddress != _newAddr, "Old address and new address the same");

        keyOfInvestor[investors[_investorKey].addr] = bytes32(0);
        investors[_investorKey] = Investor(address(0), false);

        _setInvestorAddress(_investorKey, _newAddr);

        emit ChangeInvestorAddress(
            msg.sender,
            _investorKey,
            oldAddress,
            _newAddr
        );
    }

    /**
     * @dev Sets token's whitelisted status.
     *
     * Emits a {SetTokenAddressActive} event token's address and new status.
     *
     * @param _token The address of token.
     * @param _active Token's whitelisted status.
     */
    function _setTokenAddressActive(address _token, bool _active) internal {
        tokens[_token] = _active;
        emit SetTokenAddressActive(_token, _active);
    }

    /**
     * @dev Sets status of enable/disable of investors whitelist
     * for operations with liquidity pools.
     *
     * Emits a {SetLiquidityWlActive} event with new status.
     *
     * @param _active Investors whitelist check status.
     */
    function _setLiquidityWlActive(bool _active) internal {
        isLiquidityWlActive = _active;
        emit SetLiquidityWlActive(_active);
    }

    /**
     * @dev Sets status of enable/disable of investors whitelist
     * for operations with swap.
     *
     * Emits a {SetSwapWlActive} event with new status.
     *
     * @param _active Investors whitelist check status.
     */
    function _setSwapWlActive(bool _active) internal {
        isSwapWlActive = _active;
        emit SetSwapWlActive(_active);
    }

    /**
     * @dev Sets status of enable/disable of investors whitelist
     * for operations with farming.
     *
     * Emits a {SetFarmWlActive} event with new status.
     *
     * @param _active Investors whitelist check status.
     */
    function _setFarmWlActive(bool _active) internal {
        isFarmWlActive = _active;
        emit SetFarmWlActive(_active);
    }

    /**
     * @dev Sets status of enable/disable of tokens whitelist.
     *
     * Emits a {SetTokenWlActive} event with new status.
     *
     * @param _active Tokens whitelist check status.
     */
    function _setTokenWlActive(bool _active) internal {
        isTokenWlActive = _active;
        emit SetTokenWlActive(_active);
    }
}
