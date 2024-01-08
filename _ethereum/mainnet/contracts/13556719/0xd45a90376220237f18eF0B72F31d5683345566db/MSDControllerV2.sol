// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./EnumerableSetUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./MSD.sol";

/**
 * @dev Interface for Minters, minters now can be iMSD and MSDS
 */
interface IMinter {
    function totalMint() external returns (uint256);
}

/**
 * @title dForce's Multi-currency Stable Debt Token Controller
 * @author dForce
 */

contract MSDControllerV2 is Initializable, Ownable {
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @dev EnumerableSet of all msdTokens
    EnumerableSetUpgradeable.AddressSet internal msdTokens;

    // @notice Mapping of msd tokens to corresponding minters
    mapping(address => EnumerableSetUpgradeable.AddressSet) internal msdMinters;

    struct TokenData {
        // System earning from borrow interest
        uint256 earning;
        // System debt from saving interest
        uint256 debt;
    }

    // @notice Mapping of msd tokens to corresponding TokenData
    mapping(address => TokenData) public msdTokenData;

    // @notice Mapping of msd minters to corresponding msd token mintage cap
    // @dev Each minter now typically iMSD can only mint 1 msd token
    /*
     *  The mint cap of the msd minter, will be checked in mintMSD()
     *  -1 means there is no limit on the cap
     *  0 means the msd token can not be mint any more
     */
    mapping(address => mapping(address => uint256)) public mintCaps;

    /**
     * @dev Emitted when `token` is added into msdTokens.
     */
    event MSDAdded(address token);

    /**
     * @dev Emitted when `minter` is added into `tokens`'s minters.
     */
    event MinterAdded(address token, address minter);

    /**
     * @dev Emitted when `minter` is removed from `tokens`'s minters.
     */
    event MinterRemoved(address token, address minter);

    /**
     * @dev Emitted when reserve is withdrawn from `token`.
     */
    event ReservesWithdrawn(
        address owner,
        address token,
        uint256 amount,
        uint256 oldTotalReserves,
        uint256 newTotalReserves
    );

    /// @dev Emitted when msd token minter's mint cap is changed
    event NewMintCap(
        address token,
        address minter,
        uint256 oldMintCap,
        uint256 newMintCap
    );

    /**
     * @notice Expects to call only once to initialize the MSD controller.
     */
    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @notice Ensure this is a MSD Controller contract.
     */
    function isMSDController() external pure returns (bool) {
        return true;
    }

    /**
     * @dev Throws if token is not in msdTokens
     */
    function _checkMSD(address _token) internal view {
        require(hasMSD(_token), "token is not a valid MSD token");
    }

    /**
     * @dev Throws if token is not a valid MSD token.
     */
    modifier onlyMSD(address _token) {
        _checkMSD(_token);
        _;
    }

    /**
     * @dev Throws if called by any account other than the _token's minters.
     */
    modifier onlyMSDMinter(address _token, address caller) {
        _checkMSD(_token);

        require(
            msdMinters[_token].contains(caller),
            "onlyMinter: caller is not the token's minter"
        );

        _;
    }

    function _addMSDInternal(address _token) internal {
        require(_token != address(0), "MSD token cannot be a zero address");
        if (msdTokens.add(_token)) {
            emit MSDAdded(_token);
        }
    }

    function _addMinterInternal(address _token, address _minter) internal {
        require(_minter != address(0), "minter cannot be a zero address");

        if (msdMinters[_token].add(_minter)) {
            emit MinterAdded(_token, _minter);
        }
    }

    function _removeMinterInternal(address _token, address _minter) internal {
        require(_minter != address(0), "minter cannot be a zero address");

        if (msdMinters[_token].remove(_minter)) {
            emit MinterRemoved(_token, _minter);
        }
    }

    function _setMintCapInternal(
        address _token,
        address _minter,
        uint256 _newMintCap
    ) internal {
        uint256 oldMintCap = mintCaps[_token][_minter];

        if (oldMintCap != _newMintCap) {
            mintCaps[_token][_minter] = _newMintCap;
            emit NewMintCap(_token, _minter, oldMintCap, _newMintCap);
        }
    }

    function _addMintersInternal(
        address _token,
        address[] calldata _minters,
        uint256[] calldata _mintCaps
    ) internal {
        require(
            _minters.length == _mintCaps.length,
            "Length of _minters and _mintCaps mismatch"
        );

        uint256 _len = _minters.length;
        for (uint256 i = 0; i < _len; i++) {
            _addMinterInternal(_token, _minters[i]);
            _setMintCapInternal(_token, _minters[i], _mintCaps[i]);
        }
    }

    /**
     * @notice Add `_token` into msdTokens, and add `_minters` into minters along with `_mintCaps`.
     * If `_token` have not been in msdTokens, emits a `MSDTokenAdded` event.
     * If _minter in `_minters` have not been in msd Token's minters, emits a `MinterAdded` event.
     * If cap in `_mintCaps` has changed, emits a `NewMintCap` event.
     *
     * @param _token The msd token to add
     * @param _minters The addresses to add as msd token's minters
     * @param _mintCaps The mint caps to set for minters
     *
     * Requirements:
     * - the caller must be `owner`.
     */
    function _addMSD(
        address _token,
        address[] calldata _minters,
        uint256[] calldata _mintCaps
    ) external onlyOwner {
        _addMSDInternal(_token);
        _addMintersInternal(_token, _minters, _mintCaps);
    }

    /**
     * @notice Add `_minters` into minters along with `_mintCaps`.
     * If _minter in `_minters` have not been in msd Token's minters, emits a `MinterAdded` event.
     * If cap in `_mintCaps` has changed, emits a `NewMintCap` event.
     *
     * @param _token The msd token to add minters
     * @param _minters The addresses to add as msd token's minters
     * @param _mintCaps The mint caps to set for minters
     *
     * Requirements:
     * - the caller must be `owner`.
     */
    function _addMinters(
        address _token,
        address[] calldata _minters,
        uint256[] calldata _mintCaps
    ) external onlyOwner onlyMSD(_token) {
        _addMintersInternal(_token, _minters, _mintCaps);
    }

    /**
     * @notice Remove `minters` from minters and reset mint cap to 0.
     * If `minter` is minters, emits a `MinterRemoved` event.
     *
     * @param _minters The minters to remove
     *
     * Requirements:
     * - the caller must be `owner`, `_token` must be a MSD Token.
     */
    function _removeMinters(address _token, address[] calldata _minters)
        external
        onlyOwner
        onlyMSD(_token)
    {
        uint256 _len = _minters.length;
        for (uint256 i = 0; i < _len; i++) {
            _removeMinterInternal(_token, _minters[i]);
            _setMintCapInternal(_token, _minters[i], 0);
        }
    }

    /**
     * @notice set `_mintCaps` for `_token`'s `_minters`, emits a `NewMintCap` event.
     *
     * @param _token The msd token to set
     * @param _minters The msd token's minters' addresses to set
     * @param _mintCaps The mint caps to set for minters
     *
     * Requirements:
     * - the caller must be `owner`.
     */
    function _setMintCaps(
        address _token,
        address[] calldata _minters,
        uint256[] calldata _mintCaps
    ) external onlyOwner onlyMSD(_token) {
        require(
            _minters.length == _mintCaps.length,
            "Length of _minters and _mintCaps mismatch"
        );

        uint256 _len = _minters.length;
        for (uint256 i = 0; i < _len; i++) {
            require(
                msdMinters[_token].contains(_minters[i]),
                "minter is not the token's minter"
            );
            _setMintCapInternal(_token, _minters[i], _mintCaps[i]);
        }
    }

    /**
     * @notice Withdraw the reserve of `_token`.
     * @param _token The MSD token to withdraw
     * @param _amount The amount of token to withdraw
     *
     * Requirements:
     * - the caller must be `owner`, `_token` must be a MSD Token.
     */
    function _withdrawReserves(address _token, uint256 _amount)
        external
        onlyOwner
        onlyMSD(_token)
    {
        (uint256 _equity, ) = calcEquity(_token);

        require(_equity >= _amount, "Token do not have enough reserve");

        // Increase the token debt
        msdTokenData[_token].debt = msdTokenData[_token].debt.add(_amount);

        // Directly mint the token to owner
        MSD(_token).mint(owner, _amount);

        emit ReservesWithdrawn(
            owner,
            _token,
            _amount,
            _equity,
            _equity.sub(_amount)
        );
    }

    /**
     * @notice Mint `amount` of `_token` to `_to`.
     * @param _token The MSD token to mint
     * @param _to The account to mint to
     * @param _amount The amount of token to mint
     *
     * Requirements:
     * - the caller must be `minter` of `_token`.
     */
    function mintMSD(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyMSDMinter(_token, msg.sender) {
        _beforeMint(_token, msg.sender, _to, _amount);

        MSD(_token).mint(_to, _amount);
    }

    function _beforeMint(
        address _token,
        address _minter,
        address _to,
        uint256 _amount
    ) internal virtual {
        // Check minter's mint cap, -1 means no limit
        // _amount has been taken account into totalMint/totalBorrows
        require(
            IMinter(_minter).totalMint() <= mintCaps[_token][_minter],
            "Minter mint capacity reached"
        );

        _to;
        _amount;
    }

    /*********************************/
    /******** MSD Token Equity *******/
    /*********************************/

    /**
     * @notice Get the MSD token equity
     * @param _token The MSD token to query
     * @return token equity, token debt, will call `updateInterest()` on its minters
     *
     * Requirements:
     * - `_token` must be a MSD Token.
     *
     */
    function calcEquity(address _token)
        public
        view
        onlyMSD(_token)
        returns (uint256, uint256)
    {
        TokenData storage _tokenData = msdTokenData[_token];

        return
            _tokenData.earning > _tokenData.debt
                ? (_tokenData.earning.sub(_tokenData.debt), uint256(0))
                : (uint256(0), _tokenData.debt.sub(_tokenData.earning));
    }

    /*********************************/
    /****** General Information ******/
    /*********************************/

    /**
     * @notice Return all of the MSD tokens
     * @return _allMSDs The list of MSD token addresses
     */
    function getAllMSDs() public view returns (address[] memory _allMSDs) {
        EnumerableSetUpgradeable.AddressSet storage _msdTokens = msdTokens;

        uint256 _len = _msdTokens.length();
        _allMSDs = new address[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _allMSDs[i] = _msdTokens.at(i);
        }
    }

    /**
     * @notice Check whether a address is a valid MSD
     * @param _token The token address to check for
     * @return true if the _token is a valid MSD otherwise false
     */
    function hasMSD(address _token) public view returns (bool) {
        return msdTokens.contains(_token);
    }

    /**
     * @notice Return all minter of a MSD token
     * @param _token The MSD token address to get minters for
     * @return _minters The list of MSD token minter addresses
     * Will retuen empty if `_token` is not a valid MSD token
     */
    function getMSDMinters(address _token)
        public
        view
        returns (address[] memory _minters)
    {
        EnumerableSetUpgradeable.AddressSet storage _msdMinters =
            msdMinters[_token];

        uint256 _len = _msdMinters.length();
        _minters = new address[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _minters[i] = _msdMinters.at(i);
        }
    }
}
