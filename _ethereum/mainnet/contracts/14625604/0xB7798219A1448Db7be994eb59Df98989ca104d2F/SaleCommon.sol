// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./IStoryversePlot.sol";

contract SaleCommon is AccessControl, ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public plot;

    /// @notice Emitted when a new sale is added to the contract
    /// @param who Admin that created the sale
    /// @param saleId Sale ID, will be the current sale
    event SaleAdded(address who, uint256 saleId);

    /// @notice Emitted when the current sale is updated
    /// @param who Admin that updated the sale
    /// @param saleId Sale ID, will be the current sale
    event SaleUpdated(address who, uint256 saleId);

    /// @notice Emitted when new tokens are sold and minted
    /// @param who Purchaser (payer) for the tokens
    /// @param to Owner of the newly minted tokens
    /// @param quantity Quantity of tokens minted
    /// @param amount Amount paid in Wei
    event Minted(address who, address to, uint256 quantity, uint256 amount);

    /// @notice Emitted when funds are withdrawn from the contract
    /// @param to Recipient of the funds
    /// @param amount Amount sent in Wei
    event FundsWithdrawn(address to, uint256 amount);

    /// @notice Constructor
    /// @param _plot Storyverse Plot contract
    constructor(address _plot) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        plot = _plot;
    }

    function checkTokenParameters(
        uint256 _volume,
        uint256 _presale,
        uint256 _tokenIndex
    ) internal pure {
        require(_volume > 0 && _volume < 2**10, "invalid volume");
        require(_presale < 2**2, "invalid presale");
        require(_tokenIndex < 2**32, "invalid token index");
    }

    function buildTokenId(
        uint256 _volume,
        uint256 _presale,
        uint256 _tokenIndex
    ) public view returns (uint256 tokenId_) {
        checkTokenParameters(_volume, _presale, _tokenIndex);

        uint256 superSecretSpice = uint256(
            keccak256(
                abi.encodePacked(
                    (0x4574c8c75d6e88acd28f7e467dac97b5c60c3838d9dad993900bdf402152228e ^
                        uint256(blockhash(block.number - 1))) + _tokenIndex
                )
            )
        ) & 0xffffffff;

        tokenId_ = (_volume << 245) | (_presale << 243) | (superSecretSpice << 211) | _tokenIndex;

        return tokenId_;
    }

    /// @notice Decode a token ID into its component parts
    /// @param _tokenId Token ID
    /// @return volume_ Volume of the sale
    /// @return presale_ Presale of the sale
    /// @return superSecretSpice_ Super secret spice
    /// @return tokenIndex_ Token index
    function decodeTokenId(uint256 _tokenId)
        external
        pure
        returns (
            uint256 volume_,
            uint256 presale_,
            uint256 superSecretSpice_,
            uint256 tokenIndex_
        )
    {
        volume_ = (_tokenId >> 245) & 0x3ff;
        presale_ = (_tokenId >> 243) & 0x3;
        superSecretSpice_ = (_tokenId >> 211) & 0xffffffff;
        tokenIndex_ = _tokenId & 0xffffffff;

        return (volume_, presale_, superSecretSpice_, tokenIndex_);
    }

    /// @notice Withdraw funds from the contract
    /// @param _to Recipient of the funds
    /// @param _amount Amount sent, in Wei
    function withdrawFunds(address payable _to, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(_amount <= address(this).balance, "not enough funds");
        _to.transfer(_amount);
        emit FundsWithdrawn(_to, _amount);
    }
}
