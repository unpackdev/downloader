// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./console.sol";

import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./ERC721AOperatorFilterUpgradeable.sol";
import "./OnlyDevMultiSigUpgradeable.sol";
import "./Awakening.sol";
import "./Refund.sol";
import "./TakrutSale.sol";

contract Takrut is
    ReentrancyGuardUpgradeable,
    OnlyDevMultiSigUpgradeable,
    ERC721AOperatorFilterUpgradeable,
    ERC2981Upgradeable,
    Awakening,
    Refund,
    TakrutSale
{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;
    string private baseURI;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address devMultiSigWallet_,
        uint96 royalty_,
        SaleConfigCreate calldata allySaleConfig,
        SaleConfigCreate calldata privateSaleConfig,
        SaleConfigCreate calldata publicRaffleSaleConfig,
        PuclicSaleConfigCreate calldata publicSaleConfig,
        address _freeMintSignerAddress
    ) public initializerERC721A initializer {
        MAX_SUPPLY = 10000; // total supply
        DEV_RESERVE = 250; // total dev will reserve
        MAX_FREE_SUPPLY = 50;

        __OnlyDevMultiSig_init(devMultiSigWallet_);
        __ERC721A_init(_name, _symbol);
        __Ownable_init();
        __ReentrancyGuard_init();

        _devMultiSigWallet = devMultiSigWallet_;
        setBaseURI(_initBaseURI);
        _setDefaultRoyalty(devMultiSigWallet_, royalty_);

        setFreeMintValidator(_freeMintSignerAddress);

        // ally round
        setSaleConfig(
            allySaleConfig.saleId,
            allySaleConfig.maxPerWallet,
            allySaleConfig.maxPerTransaction,
            allySaleConfig.unitPrice,
            allySaleConfig.signerAddress,
            allySaleConfig.maxPerRound
        );

        // private round
        setSaleConfig(
            privateSaleConfig.saleId,
            privateSaleConfig.maxPerWallet,
            privateSaleConfig.maxPerTransaction,
            privateSaleConfig.unitPrice,
            privateSaleConfig.signerAddress,
            privateSaleConfig.maxPerRound
        );

        // public raffle round
        setSaleConfig(
            publicRaffleSaleConfig.saleId,
            publicRaffleSaleConfig.maxPerWallet,
            publicRaffleSaleConfig.maxPerTransaction,
            publicRaffleSaleConfig.unitPrice,
            publicRaffleSaleConfig.signerAddress,
            publicRaffleSaleConfig.maxPerRound
        );

        // public round
        setPublicSaleConfig(
            publicSaleConfig.maxPerTransaction,
            publicSaleConfig.unitPrice
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNewSupply(uint256 _newMaxSupply) public onlyOwner {
        MAX_SUPPLY = _newMaxSupply;
    }

    function setNewMaxFreeSupply(uint256 _newMaxFreeSupply) public onlyOwner {
        MAX_FREE_SUPPLY = _newMaxFreeSupply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "NOT_EXISTS");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);

        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        require(
            index < balanceOf(owner),
            "ERC721AUpgradeable: owner index out of bounds"
        );
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);

        for (uint256 i = 0; i < numMintedSoFar; i++) {
            TokenOwnership memory ownership = _ownershipOf(i);
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("ERC721AUpgradeable: unable to get token of owner by index");
    }

    /* 
        BACK OFFICE
    */
    function setDevMultiSigAddress(address payable _address)
        external
        onlyDevMultiSig
    {
        _devMultiSigWallet = _address;
        updateDevMultiSigWallet(_address);
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyDevMultiSig
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function withdrawTokensToDev(IERC20Upgradeable token)
        public
        onlyDevMultiSig
    {
        uint256 funds = token.balanceOf(address(this));
        require(funds > 0, "No token left");
        token.transfer(address(_devMultiSigWallet), funds);
    }

    function withdrawETHBalanceToDev() public onlyDevMultiSig {
        require(address(this).balance > 0, "No ETH left");

        (bool success, ) = address(_devMultiSigWallet).call{
            value: address(this).balance
        }("");

        require(success, "Transfer failed.");
    }
}
