// SPDX-License-Identifier: CC0
// Copyright (c) 2022 unReal Accelerator, LLC (https://unrealaccelerator.io)
pragma solidity ^0.8.19;

/**
 * @title PhoenixKingz
 * @dev A contract for minting Phoenix Kingz
 * @author jason@unrealaccelerator.io
 */

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract PhoenixKingz is ReentrancyGuard, Ownable, ERC721A {
    IERC20 public tokenContract; // ERC20 token contract for Shilling tokens

    enum MintPhase {
        paused,
        tokenSales,
        nativeSales
    }

    // mint controls
    MintPhase public phase = MintPhase.paused;
    uint256 public constant TOKEN_SUPPLY = 550;
    uint256 public tokenSalePrice = 18 * 10 ** 18;
    uint256 public nativeSalePrice = 1.32 ether;

    // metadata
    string public baseTokenURI; // set after deploy

    // security
    address public administrator;

    /////////  errors
    error NotAuthorized(); // Error thrown when caller is not authorized
    error NoBalanceToWithdraw(); // Error thrown when attempting to withdraw with no balance
    error InvalidAddress();
    error InvalidPhase();
    error MintingPaused();
    error MintPhaseAlreadySet(MintPhase phase);
    error WrongEtherAmount();
    error UnauthorizedSpend();
    error NotEnoughTokens();
    error InsufficentSupply();

    /////////  events

    event MintPhaseSet(MintPhase phase);

    /////////  modifiers

    /**
     * @dev Modifier to check for Admin or Owner role
     */
    modifier onlyAuthorized() {
        validateAuthorized();
        _;
    }

    /**
     * @dev Validate authorized addresses
     */
    function validateAuthorized() private view {
        if (_msgSender() != owner() && _msgSender() != administrator)
            revert NotAuthorized();
    }

    constructor(
        string memory name,
        string memory symbol,
        address tokenContract_,
        address administrator_
    ) ERC721A(name, symbol) {
        if (administrator_ == address(0)) revert InvalidAddress();
        administrator = administrator_;
        if (tokenContract_ == address(0)) revert InvalidAddress();
        tokenContract = IERC20(tokenContract_);
    }

    /**
     * @dev Fallback function to receive Ether.
     * This function is payable and allows the contract to receive ETH.
     */
    receive() external payable {}

    function mint(uint256 amount) public payable nonReentrant {
        if (phase == MintPhase.paused) revert MintingPaused();
        if (totalSupply() + amount > TOKEN_SUPPLY) revert InsufficentSupply();
        if (phase == MintPhase.tokenSales) {
            if (
                tokenContract.allowance(_msgSender(), address(this)) <
                (amount * tokenSalePrice)
            ) revert UnauthorizedSpend();
            if (
                tokenContract.balanceOf(_msgSender()) <
                (amount * tokenSalePrice)
            ) revert NotEnoughTokens();
            tokenContract.transferFrom(
                _msgSender(),
                address(this),
                amount * tokenSalePrice
            );
        } else if (phase == MintPhase.nativeSales) {
            if (nativeSalePrice * amount > msg.value) revert WrongEtherAmount();
        } else {
            // catch all
            revert InvalidPhase();
        }
        _mint(_msgSender(), amount);
    }

    /**
     * @dev Deactivate all minting
     */
    function setMintingPaused() external onlyAuthorized {
        if (phase == MintPhase.paused) revert MintPhaseAlreadySet(phase);
        phase = MintPhase.paused;
        emit MintPhaseSet(phase);
    }

    /**
     * @dev Activate token minting
     */
    function startTokenMinting() external onlyAuthorized {
        if (phase == MintPhase.tokenSales) revert MintPhaseAlreadySet(phase);
        phase = MintPhase.tokenSales;
        emit MintPhaseSet(phase);
    }

    /**
     * @dev Activate native minting
     */
    function startNativeMinting() external onlyAuthorized {
        if (phase == MintPhase.nativeSales) revert MintPhaseAlreadySet(phase);
        phase = MintPhase.nativeSales;
        emit MintPhaseSet(phase);
    }

    /**
     * @dev Set/update the token contract
     * Amount must be in wei
     * Only authorized addresses can call this function.
     */
    function setTokenContract(address tokenContract_) external onlyAuthorized {
        if (tokenContract_ == address(0)) revert InvalidAddress();
        tokenContract = IERC20(tokenContract_);
    }

    /**
     * @dev Set/update the token sale price
     * Amount must be in wei
     * Only authorized addresses can call this function.
     */
    function setTokenSalePrice(
        uint256 tokenSalePrice_
    ) external onlyAuthorized {
        tokenSalePrice = tokenSalePrice_;
    }

    /**
     * @dev Set/update the native sale price
     * Amount must be in wei
     * Only authorized addresses can call this function.
     */
    function setNativeSalePrice(
        uint256 nativeSalePrice_
    ) external onlyAuthorized {
        nativeSalePrice = nativeSalePrice_;
    }

    /**
     * @dev Sets the base token uri
     */
    function setBaseTokenURI(
        string calldata baseTokenURI_
    ) external onlyAuthorized {
        baseTokenURI = baseTokenURI_;
    }

    /**
     * @dev Sets the administrator address.
     */
    function setAdministrator(address administrator_) external onlyOwner {
        administrator = administrator_;
    }

    /**
     * @dev Internal function to return the base uri for all tokens
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /*
     * @dev Internal function to set the starting token id
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev Returns list of token ids owned by address
     */
    function walletOfOwner(
        address _owner
    ) external view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](balanceOf(_owner));
        uint256 k = 0;
        for (uint256 i = 1; i <= TOKEN_SUPPLY; i++) {
            if (_exists(i) && _owner == ownerOf(i)) {
                tokenIds[k] = i;
                k++;
            }
        }
        delete k;
        return tokenIds;
    }

    /**
     * @dev Admin function to withdraw unclaimed Shilling tokens after the claiming period.
     * Only authorized addresses can call this function.
     */
    function withdrawPaymentToken() external onlyAuthorized {
        uint256 amount = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner(), amount);
        delete amount;
    }

    /**
     * @dev Admin function to withdraw ETH from the contract.
     * Only authorized addresses can call this function.
     */
    function withdraw() external onlyAuthorized {
        uint256 balance = address(this).balance;
        if (balance <= 0) revert NoBalanceToWithdraw();

        address payable ownerAddress = payable(owner());
        ownerAddress.transfer(balance);
    }
}
