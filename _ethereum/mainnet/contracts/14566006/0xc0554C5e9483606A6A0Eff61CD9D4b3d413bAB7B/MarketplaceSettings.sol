// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./IMarketplaceSettings.sol";
import "./IERC721Creator.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./IERC721.sol";

contract MarketplaceSettings is Ownable, AccessControl, IMarketplaceSettings {
    using SafeMath for uint256;

    bytes32 public constant TOKEN_MARK_ROLE = keccak256("TOKEN_MARK_ROLE");
    bytes32 public constant PRIMARY_FEE_SETTER_ROLE =
        keccak256("PRIMARY_FEE_SETTER_ROLE");

    IMarketplaceSettings private oldMarketplaceSettings;

    uint256 private maxValue;
    uint256 private minValue;

    uint8 private marketplaceFeePercentage;

    constructor(address newOwner, address oldSettings) {
        maxValue = 2**254;
        minValue = 1000;
        marketplaceFeePercentage = 3;

        require(
            newOwner != address(0),
            "constructor::New owner address cannot be null"
        );

        require(
            oldSettings != address(0),
            "constructor::Old Marketplace Settings address cannot be null"
        );

        _setupRole(AccessControl.DEFAULT_ADMIN_ROLE, newOwner);
        _setupRole(TOKEN_MARK_ROLE, newOwner);
        _setupRole(PRIMARY_FEE_SETTER_ROLE, newOwner);
        transferOwnership(newOwner);

        oldMarketplaceSettings = IMarketplaceSettings(oldSettings);
    }

    function grantMarketplaceAccess(address _account) external {
        require(
            hasRole(AccessControl.DEFAULT_ADMIN_ROLE, _msgSender()),
            "grantMarketplaceAccess::Must be admin to call method"
        );
        grantRole(TOKEN_MARK_ROLE, _account);
    }

    function getMarketplaceMaxValue() external view override returns (uint256) {
        return maxValue;
    }

    function setMarketplaceMaxValue(uint256 _maxValue) external onlyOwner {
        maxValue = _maxValue;
    }

    function getMarketplaceMinValue() external view override returns (uint256) {
        return minValue;
    }

    function setMarketplaceMinValue(uint256 _minValue) external onlyOwner {
        minValue = _minValue;
    }

    function getMarketplaceFeePercentage()
        external
        view
        override
        returns (uint8)
    {
        return marketplaceFeePercentage;
    }

    function setMarketplaceFeePercentage(uint8 _percentage) external onlyOwner {
        require(
            _percentage <= 100,
            "setMarketplaceFeePercentage::_percentage must be <= 100"
        );
        marketplaceFeePercentage = _percentage;
    }

    function calculateMarketplaceFee(uint256 _amount)
        external
        view
        override
        returns (uint256)
    {
        return _amount.mul(marketplaceFeePercentage).div(100);
    }

    function getERC721ContractPrimarySaleFeePercentage(address)
        external
        pure
        override
        returns (uint8)
    {
        return 15;
    }

    function setERC721ContractPrimarySaleFeePercentage(
        address _contractAddress,
        uint8 _percentage
    ) external override {}

    function calculatePrimarySaleFee(address, uint256 _amount)
        external
        pure
        override
        returns (uint256)
    {
        return _amount.mul(15).div(100);
    }

    function hasERC721TokenSold(address _contractAddress, uint256 _tokenId)
        external
        view
        override
        returns (bool)
    {
        bool hasSoldOnSR = oldMarketplaceSettings.hasERC721TokenSold(
            _contractAddress,
            _tokenId
        );

        if (hasSoldOnSR) return true;

        bool creatorOwnsToken = true;

        try IERC721Creator(_contractAddress).tokenCreator(_tokenId) returns (
            address payable creator
        ) {
            creatorOwnsToken =
                creator == IERC721(_contractAddress).ownerOf(_tokenId);
        } catch {
            try Ownable(_contractAddress).owner() returns (
                address contractOwner
            ) {
                creatorOwnsToken =
                    contractOwner ==
                    IERC721(_contractAddress).ownerOf(_tokenId);
            } catch {}
        }

        return !creatorOwnsToken;
    }

    function markERC721Token(
        address _contractAddress,
        uint256 _tokenId,
        bool _hasSold
    ) public override {
        require(
            hasRole(TOKEN_MARK_ROLE, msg.sender),
            "markERC721Token::Must have TOKEN_MARK_ROLE role to call method"
        );
        oldMarketplaceSettings.markERC721Token(
            _contractAddress,
            _tokenId,
            _hasSold
        );
    }

    function markTokensAsSold(
        address _originContract,
        uint256[] calldata _tokenIds
    ) external {
        require(
            hasRole(TOKEN_MARK_ROLE, msg.sender),
            "markERC721Token::Must have TOKEN_MARK_ROLE role to call method"
        );
        // limit to batches of 2000
        require(
            _tokenIds.length <= 2000,
            "markTokensAsSold::Attempted to mark more than 2000 tokens as sold"
        );

        // Mark provided tokens as sold.
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            markERC721Token(_originContract, _tokenIds[i], true);
        }
    }
}
