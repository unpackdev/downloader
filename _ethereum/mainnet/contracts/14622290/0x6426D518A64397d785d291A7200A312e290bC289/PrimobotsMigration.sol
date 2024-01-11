// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Primobots

// .______   .______       __  .___  ___.   ______   .______     ______   .___________.    _______.
// |   _  \  |   _  \     |  | |   \/   |  /  __  \  |   _  \   /  __  \  |           |   /       |
// |  |_)  | |  |_)  |    |  | |  \  /  | |  |  |  | |  |_)  | |  |  |  | `---|  |----`  |   (----`
// |   ___/  |      /     |  | |  |\/|  | |  |  |  | |   _  <  |  |  |  |     |  |        \   \
// |  |      |  |\  \----.|  | |  |  |  | |  `--'  | |  |_)  | |  `--'  |     |  |    .----)   |
// | _|      | _| `._____||__| |__|  |__|  \______/  |______/   \______/      |__|    |_______/

pragma solidity 0.8.13;

import "./Primobots.sol";
import "./IERC721Receiver.sol";

/// @title PrimobotsMigration Smart Contract
/// @author Primobots Team
/// @notice This smart contract will fulfill the need of PrimobotsMigration Collection drop with low price
contract PrimobotsMigration is Ownable, Pausable, IERC721Receiver {
    /// @notice Price of each Primobot during main sale
    /// @return MINTING_PRICE uint256 price per Primobot
    uint256 public constant MINTING_PRICE = 0.044 ether;

    /// @notice Maximum number of Primobots allowed to buy per wallet and per transaction
    /// @return MAX_LIMIT uint256 Maximum number of Primobots allowed to buy per wallet and per transaction
    uint256 public constant MAX_LIMIT = 10;

    /// @notice counter fo token ID to be sold
    /// @return startingId ID of the current token that will be minted
    uint256 public startingId;

    /// @notice Primobots contract instance
    /// @return primobots address of Primobots contract
    Primobots public primobots;

    /// @notice address of Primobots vault
    /// @dev it will be a multisig wallet Gnosis Safe
    /// @return vault_address address of Primobots vault
    address public vault_address;

    /// @notice Mapping of address and tokens minted by that address
    /// @return amountMinted uint8 number of tokens minted
    mapping(address => uint256) public minted;

    /// @notice contructor that will be invoked when the contract is deployed
    /// @param _vaultAddress address of vault
    /// @param _primobots address of primobots contract
    constructor(address _vaultAddress, Primobots _primobots) {
        vault_address = _vaultAddress;
        primobots = _primobots;
    }

    /// @notice pause Primobot sale (main sale and presale)
    /// @dev uses Openzeppelin's Pausable.sol
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpause Primobot sale (main sale and presale)
    /// @dev uses Openzeppelin's Pausable.sol
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice sets new primobots contract address
    /// @dev primobots contract address cannot be zero address
    /// @param _primobots address of primobots
    function setPrimobotAddress(Primobots _primobots) external onlyOwner {
        require(address(_primobots) != address(0), "Cannot be zero address");
        primobots = _primobots;
    }

    /// @notice sets new vault address
    /// @dev vault address cannot be zero address
    /// @param _vaultAddress new vault address
    function setVaultAddress(address _vaultAddress) external onlyOwner {
        require(_vaultAddress != address(0), "Vault cannot be zero address");
        vault_address = _vaultAddress;
    }

    /// @notice airdrops tokens to list of receivers starting
    /// @dev transfers tokens in sequential order starting from specified token ID
    /// @param _receivers list of addresses that will receive airdrop
    /// @param _startTokenId token ID from where the token transfer will begin
    function airdrop(address[] memory _receivers, uint256 _startTokenId)
        external
        onlyOwner
    {
        startingId = _startTokenId + _receivers.length;
        uint256 startId = _startTokenId;
        for (uint256 i; i < _receivers.length; i++) {
            primobots.safeTransferFrom(
                address(this),
                _receivers[i],
                startId++
            );
        }
    }

    /// @notice method to buy from main sale
    /// @param _quantity number of tokens to be bought
    function buy(uint256 _quantity) external payable whenNotPaused {
        require(
            primobots.minted(msg.sender) + minted[msg.sender] + _quantity <=
                MAX_LIMIT,
            "out of buying limit"
        );
        uint256 price = MINTING_PRICE;
        require(msg.value == price * _quantity, "incorrect value supplied");
        require(_quantity >= 1, "usless transaction to mint zero");
        uint256 remaining = primobots.balanceOf(address(this));
        require(_quantity <= remaining, "low balance");
        minted[_msgSender()] += uint8(_quantity);
        _mint(msg.sender, _quantity);
    }

    /// @notice withdraws all balance of this contract to vault address
    /// @dev uses OpenZeppelin's Address.sol library to handle fund transfer
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(vault_address != address(0) && balance > 0, "Can't withdraw");
        Address.sendValue(payable(vault_address), balance);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _mint(address _receiver, uint256 _quantity) private {
        uint256 startId = startingId;
        startingId += _quantity;
        for (uint256 i; i < _quantity; i++) {
            primobots.safeTransferFrom(address(this), _receiver, startId);
            startId++;
        }
    }
}
