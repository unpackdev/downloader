// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./ERC721M.sol";

interface IMiyaMints {
    function deployVault(address _erc721, uint256 _vaultId) external returns (address);
    function ownershipChanged(address _oldOwner, address _newOwner) external;
}

contract ERC721Miya is ERC721M {
    address public miyaMints;

    constructor() payable {}

    // Initialize contract, should be called immediately after deployment, ideally by factory
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        uint40 _maxSupply,
        uint16 _royalty,
        uint16 _allocation,
        address _owner,
        address _alignedNft,
        uint80 _price,
        uint256 _vaultId
    ) external payable override initializer {
        // Confirm mint alignment allocation is within valid range
        if (_allocation < 500) revert NotAligned(); // Require allocation be >= 5%
        if (_allocation > 10000) revert Invalid(); // Require allocation be <= 100%
        allocation = _allocation;
        // Confirm royalty is <= 100%
        if (_royalty > 10000) revert Invalid(); // Prevent bad royalty fee >100%
        _setTokenRoyalty(0, _owner, uint96(_royalty));
        _setDefaultRoyalty(_owner, uint96(_royalty));
        // Initialize ownership
        _initializeOwner(_owner);
        // Set all values
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _contractURI = contractURI_;
        maxSupply = _maxSupply;
        alignedNft = _alignedNft;
        price = _price;
        miyaMints = msg.sender;
        // Deploy AlignmentVault
        address alignmentVault = IMiyaMints(msg.sender).deployVault(_alignedNft, _vaultId);
        vault = alignmentVault;
        // Send initialize payment (if any) to vault
        if (msg.value > 0) {
            (bool success,) = payable(alignmentVault).call{value: msg.value}("");
            if (!success) revert TransferFailed();
        }
    }

    // Overrides to tell MiyaMints.sol about ownership changes
    function transferOwnership(address _newOwner) public payable override onlyOwner {
        IMiyaMints(miyaMints).ownershipChanged(owner(), _newOwner);
        super.transferOwnership(_newOwner);
    }

    function renounceOwnership() public payable override onlyOwner {
        IMiyaMints(miyaMints).ownershipChanged(owner(), address(0));
        super.renounceOwnership();
    }

    // Overrides to eliminate vault asset controls, vaults will only be operated by MiyaMaker
    function alignNfts(uint256[] memory _tokenIds) external payable override {
        payable(vault).call{value: msg.value}("");
    }

    function alignTokens(uint256 _amount) external payable override {
        payable(vault).call{value: msg.value}("");
    }

    function alignMaxLiquidity() external payable override {
        payable(vault).call{value: msg.value}("");
    }

    function claimYield(address _to) external payable override {
        IAlignmentVault(vault).claimYield{value: msg.value}(_to);
    }

    // Overrides to eliminate rescue calls to the vault but still handle assets held here appropriately
    function rescueERC20(address _asset, address _to) external override onlyOwner {
        uint256 balance = IERC20(_asset).balanceOf(address(this));
        if (_asset == weth) {
            if (balance > 0) IERC20(_asset).transfer(vault, balance);
        } else {
            if (balance > 0) IERC20(_asset).transfer(_to, balance);
        }
    }

    function rescueERC721(address _asset, address _to, uint256 _tokenId) external override onlyOwner {
        if (_asset == alignedNft) {
            IERC721(_asset).safeTransferFrom(address(this), vault, _tokenId);
            return;
        } else {
            IERC721(_asset).transferFrom(address(this), _to, _tokenId);
            return;
        }
    }
}
