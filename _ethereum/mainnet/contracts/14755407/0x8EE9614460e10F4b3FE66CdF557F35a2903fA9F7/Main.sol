// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

import "./AppType.sol";
import "./Batch.sol";
import "./App.sol";

contract GalleryChosunCollection is ERC1155, ERC1155Burnable, ERC1155Supply {
    using App for AppType.State;
    using BatchFactory for AppType.State;

    AppType.State state;

    constructor() ERC1155("https://mint.valores.cc/nft/{id}/minted") {
        state.initialize();
    }

    function setURI(string memory newuri) external {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.ADMIN],
            "E001"
        );
        _setURI(newuri);
    }

    function safeMint(
        AppType.NFT calldata nft,
        uint256 nftAmount,
        bytes memory data,
        bytes32[] calldata proof
    ) external payable {
        uint256 newTokenId = state.authorizeMint(nft, nftAmount, proof);
        _mint(msg.sender, newTokenId, nftAmount, data);
    }

    function createBatch(
        uint256 isOpenAt,
        bool disabled,
        bytes32 root
    ) external {
        state.createBatch(isOpenAt, disabled, root);
    }

    function updateBatch(
        uint256 batchId,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root
    ) external {
        state.updateBatch(batchId, isOpenAt, disabled, root);
    }

    function setTierSwapAmount(
        uint256 tierId,
        address swapToken,
        uint256 swapAmount
    ) external {
        state.setTierSwapAmount(tierId, swapToken, swapAmount);
    }

    function readBatch(uint256 batchId)
        external
        view
        returns (
            uint256 isOpenAt,
            bool disabled,
            bytes32 root
        )
    {
        return state.readBatch(batchId);
    }

    function changeConfig(
        AppType.IConfigKey calldata key,
        AppType.IConfigValue calldata value
    ) external {
        state.changeConfig(key, value);
    }

    function getConfig(
        AppType.AddressConfig addressConfig,
        AppType.UintConfig uintConfig,
        AppType.BoolConfig boolConfig,
        AppType.StringConfig stringConfig
    )
        external
        view
        returns (
            address addressValue,
            uint256 uintValue,
            bool boolValue,
            string memory stringValue
        )
    {
        return
            state.getConfig(
                addressConfig,
                uintConfig,
                boolConfig,
                stringConfig
            );
    }

    function excludeNFTLeaf(AppType.NFT memory nft, bool isExcluded) external {
        state.excludeNFTLeaf(nft, isExcluded);
    }

    function name() public view returns (string memory) {
        return state.config.strings[AppType.StringConfig.APP_NAME];
    }

    function withdrawAdmin(address token, uint256 amount) external {
        state.safeWithdraw(token, amount);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// Error Codes
// E001: Only Admin can perform this action
// E002: Batch not found
// E003: NFT Batch is not available
// E004: NFT is not found
// E005: NFT is not available
// E006: SwapToken not Allowed
// E007: Insufficient Funds sent to swap
// E008: Cannot set admin address to 0
// E009: Cannot withdraw from non-admin account
// E010: FEE_WALLET is not set
// E011: Minting is Paused
