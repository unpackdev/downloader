// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./IOFTMintable.sol";
import "./OFT.sol";

/**
 * @title OFTMintable
 * @notice OFT token with minting and burning logic.
 */
contract OFTMintable is OFT, IOFTMintable {
    /// @notice Minter addresses.
    mapping(address => bool) public minters;

    /// @notice Status of minting.
    /// @dev Can be kill-switched by the owner.
    bool public mintingEnabled = true;

    /**
     * @notice Event emitted when minter role is set.
     * @param account Address with minter role.
     * @param isMinter Status of minter role.
     */
    event SetMinter(address indexed account, bool isMinter);

    /**
     * @notice Event emitted when minting is disabled.
     * @dev After this event is emitted, minting is disabled forever.
     */
    event MintingDisabled();

    /**
     * @notice Constructor.
     * @param _layerZeroEndpoint Address of layerzero endpoint.
     * @param _name Token name.
     * @param _symbol Token symbol.
     */
    constructor(
        address _layerZeroEndpoint,
        string memory _name,
        string memory _symbol
    ) OFT(_name, _symbol, _layerZeroEndpoint) {}

    ///////////////////////
    /// User Functions  ///
    ///////////////////////

    /**
     * @inheritdoc IOFTMintable
     */
    function mint(address _account, uint256 _amount) external {
        require(mintingEnabled, "Minting disabled");
        require(minters[msg.sender], "Invalid minter");
        _mint(_account, _amount);
    }

    /**
     * @notice Burn tokens.
     * @dev It burns tokens of the msg.sender.
     * @param _amount Amount of tokens to burn.
     */
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

    ///////////////////////
    /// Owner Functions ///
    ///////////////////////

    /**
     * @notice Disable minting.
     * @dev Can be only called by the owner, effectively only once.
     * @dev It only affects minting, on single chain.
     */
    function disableMinting() external onlyOwner {
        mintingEnabled = false;
        emit MintingDisabled();
    }

    /**
     * @inheritdoc IOFTMintable
     */
    function setMinter(address _minter, bool _isMinter) external onlyOwner {
        minters[_minter] = _isMinter;
        emit SetMinter(_minter, _isMinter);
    }
}
