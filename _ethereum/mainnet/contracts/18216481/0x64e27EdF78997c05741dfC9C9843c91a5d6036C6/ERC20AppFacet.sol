// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AddressUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC721AStorage.sol";
import "./INiftyKitV3.sol";
import "./IERC173.sol";
import "./AppFacet.sol";
import "./BaseStorage.sol";
import "./DropStorage.sol";
import "./ERC20AppStorage.sol";

contract ERC20AppFacet is AppFacet {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    modifier onlyMintable(uint64 quantity) {
        DropStorage.Layout storage layout = DropStorage.layout();
        require(quantity > 0, "Quantity is 0");
        require(quantity <= layout._maxPerMint, "Exceeded max per mint");
        if (
            layout._maxAmount > 0 &&
            _totalSupply() + quantity > layout._maxAmount
        ) {
            revert("Exceeded max supply");
        }
        _;
    }

    function erc20SetActiveCoin(
        address tokenAddress
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        ERC20AppStorage.Layout storage layout = ERC20AppStorage.layout();
        if (
            address(layout._erc20ContractsByAddress[tokenAddress]) == address(0)
        ) {
            IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
            layout._erc20ContractsByAddress[tokenAddress] = token;
            layout._erc20ContractsByIndex[layout._erc20ContractsCount] = token;
            layout._erc20ContractsCount++;
        }
        layout._erc20ActiveContract = layout._erc20ContractsByAddress[
            tokenAddress
        ];
    }

    function erc20MintTo(
        address recipient,
        uint64 quantity
    ) external payable onlyMintable(quantity) {
        ERC20AppStorage.Layout storage layout = ERC20AppStorage.layout();
        require(!layout._erc20PresaleActive, "Presale active");
        require(layout._erc20SaleActive, "Sale not active");
        require(
            _getAux(recipient) + quantity <= DropStorage.layout()._maxPerWallet,
            "Exceeded max per wallet"
        );

        _erc20PurchaseMint(quantity, recipient);
    }

    function erc20PresaleMintTo(
        address recipient,
        uint64 quantity,
        uint256 allowed,
        bytes32[] calldata proof
    ) external payable onlyMintable(quantity) {
        DropStorage.Layout storage dropLayout = DropStorage.layout();
        ERC20AppStorage.Layout storage layout = ERC20AppStorage.layout();
        uint256 mintQuantity = _getAux(recipient) + quantity;
        require(layout._erc20PresaleActive, "Presale not active");
        require(dropLayout._merkleRoot != "", "Presale not set");
        require(
            mintQuantity <= dropLayout._maxPerWallet,
            "Exceeded max per wallet"
        );
        require(mintQuantity <= allowed, "Exceeded max per wallet");
        require(
            MerkleProofUpgradeable.verify(
                proof,
                dropLayout._merkleRoot,
                keccak256(abi.encodePacked(recipient, allowed))
            ),
            "Presale invalid"
        );

        _erc20PurchaseMint(quantity, recipient);
    }

    function erc20StartSale(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        ERC20AppStorage.Layout storage layout = ERC20AppStorage.layout();
        DropStorage.Layout storage dropLayout = DropStorage.layout();
        require(
            address(layout._erc20ActiveContract) != address(0),
            "Token Contract not set"
        );

        layout._erc20SaleActive = true;
        layout._erc20PresaleActive = presale;
        layout._erc20Price = newPrice;

        dropLayout._maxAmount = newMaxAmount;
        dropLayout._maxPerMint = newMaxPerMint;
        dropLayout._maxPerWallet = newMaxPerWallet;
    }

    function erc20StopSale()
        external
        onlyRolesOrOwner(BaseStorage.MANAGER_ROLE)
    {
        ERC20AppStorage.Layout storage layout = ERC20AppStorage.layout();
        layout._erc20SaleActive = false;
        layout._erc20PresaleActive = false;
    }

    function erc20ActiveCoin() external view returns (IERC20Upgradeable) {
        return ERC20AppStorage.layout()._erc20ActiveContract;
    }

    function erc20PresaleActive() external view returns (bool) {
        return ERC20AppStorage.layout()._erc20PresaleActive;
    }

    function erc20SaleActive() external view returns (bool) {
        return ERC20AppStorage.layout()._erc20SaleActive;
    }

    function erc20Price() external view returns (uint256) {
        return ERC20AppStorage.layout()._erc20Price;
    }

    function erc20Revenue(
        address tokenAddress
    ) external view returns (uint256) {
        return ERC20AppStorage.layout()._erc20Revenues[tokenAddress];
    }

    function erc20CoinsCount() external view returns (uint256) {
        return ERC20AppStorage.layout()._erc20ContractsCount;
    }

    function erc20CoinByIndex(
        uint256 index
    ) external view returns (IERC20Upgradeable) {
        return ERC20AppStorage.layout()._erc20ContractsByIndex[index];
    }

    function erc20MintFee() external view returns (uint256) {
        INiftyKitV3 niftyKit = BaseStorage.layout()._niftyKit;
        (uint256 mintFees, uint256 ownerPerks) = niftyKit.getFeesByQuantity(1);
        return mintFees + ownerPerks;
    }

    function erc20Withdraw(
        address tokenAddress
    ) external onlyRolesOrOwner(BaseStorage.ADMIN_ROLE) {
        ERC20AppStorage.Layout storage layout = ERC20AppStorage.layout();
        IERC20Upgradeable erc20Contract = layout._erc20ContractsByAddress[
            tokenAddress
        ];
        require(address(erc20Contract) != address(0), "Invalid contract");
        uint256 balance = erc20Contract.balanceOf(address(this));
        require(balance > 0, "0 balance");

        erc20Contract.safeTransfer(_msgSenderERC721A(), balance);
    }

    function _erc20PurchaseMint(uint64 quantity, address to) internal {
        ERC20AppStorage.Layout storage layout = ERC20AppStorage.layout();
        INiftyKitV3 niftyKit = BaseStorage.layout()._niftyKit;
        uint256 total = layout._erc20Price * quantity;

        (uint256 mintFees, uint256 ownerPerks) = niftyKit.getFeesByQuantity(
            quantity
        );
        require(mintFees + ownerPerks <= msg.value, "Value incorrect");

        AddressUpgradeable.sendValue(payable(address(niftyKit)), mintFees);
        if (ownerPerks > 0) {
            AddressUpgradeable.sendValue(
                payable(IERC173(address(this)).owner()),
                ownerPerks
            );
        }

        unchecked {
            layout._erc20Revenues[
                address(layout._erc20ActiveContract)
            ] += total;
        }

        layout._erc20ActiveContract.safeTransferFrom(to, address(this), total);
        _setAux(to, _getAux(to) + quantity);
        _mint(to, quantity);
    }
}
