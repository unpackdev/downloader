// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Managed.sol";
import "./PausableOwnable.sol";
import "./IWlController.sol";

/**
 * @title AssetWhitelist
 *
 * @dev The contract stores a whitelist of users (investors) and allows to
 * manage it. It is possible to check the whitelisted status of users from
 * the whitelist located in the separate CarTokenController contract.
 * All users checks can be disabled by owner.
 *
 * CarTokenController contract source: https://github.com/CurioTeam/security-token-contracts/blob/dd5c82e566d24d0e87639316a9420afdb9b30e71/contracts/CarTokenController.sol
 */
contract AssetWhitelist is Initializable, Managed, PausableOwnable {

    /// @notice CarTokenController contract
    IWlController public controller;

    struct Investor {
        address addr;
        bool active;
    }

    /// @notice Investor by key
    mapping(bytes32 => Investor) public investors;

    /// @notice Investor address to key
    mapping(address => bytes32) public keyOfInvestor;

    /// @notice Whitelist status: enabled/disabled
    bool public isWlActive;

    event SetController(address indexed controller);
    event SetWlActive(bool active);

    event AddNewInvestor(bytes32 indexed key, address indexed addr);
    event SetInvestorActive(bytes32 indexed key, bool active);
    event ChangeInvestorAddress(
        address indexed sender,
        bytes32 indexed key,
        address indexed oldAddr,
        address newAddr
    );


    /**
     * @dev Initializes the contract setting the deployer as the initial owner
     * and in unpaused and WL active state.
     */
    function __AssetWhitelist_init() external initializer {
        __Ownable_init();
        __Pausable_init();

        isWlActive = true;
    }


    /**
     * @dev Checks if an investor's account is whitelisted. Check is done
     * in the whitelist of the contract and also in the CarTokenController.
     *
     * @param _addr The address of investor's account to check.
     */
    function isInvestorAddressActive(address _addr)
        external
        view
        returns (bool)
    {
        return
            !isWlActive ||
            investors[keyOfInvestor[_addr]].active ||
            (
                address(controller) != address(0)
                    ? controller.isInvestorAddressActive(_addr)
                    : false
            );
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


    // ** ADMIN/MANAGER/OWNER role functions **

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
     * @dev Allows the owner to set CarTokenController contract.
     *
     * Emits a {SetController} event with `controller` set to
     * CarTokenController contract's address.
     *
     * @param _controller The address of CarTokenController contract.
     */
    function setController(IWlController _controller) external onlyOwner {
        controller = _controller;
        emit SetController(address(_controller));
    }

    /**
     * @dev Allows the owner to set enabled/disabled status of investor whitelist.
     *
     * Emits a {SetWlActive} event with a new status.
     *
     * @param _active Investor whitelist status.
     */
    function setWlActive(bool _active) external onlyOwner {
        isWlActive = _active;
        emit SetWlActive(_active);
    }


    // ** INTERNAL functions **

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
}
