// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC1155.sol";
import "./IERC20.sol";

import "./IMultiSale.sol";
import "./IERC20Mint.sol";
import "./IERC721Mint.sol";
import "./IERC1155Mint.sol";

import "./InterfaceChecker.sol";
import "./Controllable.sol";
import "./Modifiers.sol";

import "./UInt256Set.sol";
import "./MultiSaleLib.sol";
import "./VariablePriceLib.sol";
import "./ERC721ALib.sol";

contract MultiSaleFacet is IMultiSale, Modifiers {

    using UInt256Set for UInt256Set.Set;
    using MultiSaleLib for MultiSaleContract;
    using VariablePriceLib for VariablePriceContract;
    using ERC721ALib for ERC721AContract;

    function initializeMultiSaleFacet() external {

    }

    /// @notice intialize the contract. should be called by overriding contract
    /// @param tokenSaleInit struct with tokensale data
    /// @return tokenSaleId the id of the tokensale
    function createTokenSale(MultiSaleSettings memory tokenSaleInit)
        external
        virtual
        onlyOwner
        returns (uint256 tokenSaleId) {

        tokenSaleId = MultiSaleLib._createTokenSale();

        MultiSaleLib.multiSaleStorage()._tokenSales[tokenSaleId].settings = tokenSaleInit;
        MultiSaleLib.multiSaleStorage()._tokenSales[tokenSaleId].settings.owner = tokenSaleInit.owner;
        MultiSaleLib.multiSaleStorage()._tokenSaleIds.push(tokenSaleId);
        // emit event
        emit MultiSaleCreated(tokenSaleId, tokenSaleInit);
    }
 
    /// @notice Updates the token sale settings
    /// @param settings - the token sake settings
    function updateTokenSaleSettings(
        uint256 tokenSaleId,
        MultiSaleSettings memory settings
    ) external {
        //TODO: RESTORE!
        // check token sale owner
        //require(msg.sender == MultiSaleLib.multiSaleStorage()._tokenSales[tokenSaleId].settings.owner, "notowner");
        MultiSaleLib.multiSaleStorage()._tokenSales[tokenSaleId].settings = settings;

        // emit event
        emit MultiSaleUpdated(tokenSaleId, settings);
    }

    /// @notice purchase a token, using a proof
    /// @param purchaseInfo struct with purchase data
    /// @param purchaseProofParam the proof of the purchase
    function purchaseProof(
        MultiSalePurchase memory purchaseInfo,
        MultiSaleProof memory purchaseProofParam,
        bytes memory data
    ) external payable returns (uint256[] memory ids) {

        //  get the token sale
        MultiSaleContract storage multiSaleContract  = MultiSaleLib
            .multiSaleStorage()
            ._tokenSales[purchaseInfo.multiSaleId];

        // if the purchaser isn't set then set it to the msg.sender
        if(purchaseInfo.purchaser == address(0)) {
            purchaseInfo.purchaser = msg.sender;
        }
        if(purchaseInfo.receiver == address(0)) {
            purchaseInfo.receiver = msg.sender;
        }
        // purchase token with proof
        multiSaleContract._purchaseToken(
            multiSaleContract.settings.price,
            purchaseInfo,
            purchaseProofParam,
            msg.value
        );

        //  mint the newly-purchased tokens
        ids = _mintPurchasedTokens(
            purchaseInfo.multiSaleId,
            purchaseInfo.receiver,
            purchaseInfo.quantity,
            data
        );
        // 4. update the token sale settings
        multiSaleContract.totalPurchased += purchaseInfo.quantity;
        multiSaleContract.purchased[purchaseInfo.receiver] += purchaseInfo.quantity;

        // emit an event
        emit MultiSaleSold(
            purchaseInfo.multiSaleId,
            purchaseInfo.purchaser,
            ids,
            data
        );
    }

    /// @notice purchase a token, without a proof
    function purchase(
        uint256 multiSaleId,
        address purchaser,
        address receiver,
        uint256 quantity,
        bytes memory data) external payable returns (uint256[] memory ids) {

        // get the token sale
        MultiSaleContract storage multiSaleContract = MultiSaleLib
            .multiSaleStorage()
            ._tokenSales[multiSaleId];
        // if the purchaser isn't set then set it to the msg.sender
        if(purchaser == address(0)) {
            purchaser = msg.sender;
        }
        if(receiver == address(0)) {
            receiver = msg.sender;
        }

        MultiSalePurchase memory purchaseInfo = MultiSalePurchase(
            multiSaleId,
            purchaser,
            receiver,
            quantity
        );

        // get the token sale    
        multiSaleContract._purchaseToken(
            multiSaleContract.settings.price,
            purchaseInfo, 
            msg.value);

        //  mint the tokens
        ids = _mintPurchasedTokens(
            multiSaleId,
            receiver,
            quantity,
            data
        );
        // 4. update the token sale settings
        multiSaleContract.totalPurchased += quantity;
        multiSaleContract.purchased[receiver] += quantity;

        // emit an event
        emit MultiSaleSold(
            multiSaleId,
            receiver,
            ids,
            data
        );
    }

    /// @notice mont the tokens purchased
    /// @param multiSaleId the id of the tokensale
    /// @param recipient the address of the receiver
    /// @param amount the quantity of tokens to mint
    function _mintPurchasedTokens(
        uint256 multiSaleId,
        address recipient,
        uint256 amount,
        bytes memory data
    ) internal returns (uint256[] memory tokenHash_) {
        
        // get the token sale
        MultiSaleContract storage multiSaleContract = MultiSaleLib
            .multiSaleStorage()
            ._tokenSales[multiSaleId];
        ERC721AStorage storage erc721AStorage = ERC721ALib.erc721aStorage();

        // if the minted token is erc1155, call the 1155 mint method
        if (multiSaleContract.settings.tokenType == TokenType.ERC1155) {

            IERC20Mint(multiSaleContract.settings.token).mintTo(recipient, amount);

        } else if (InterfaceChecker.isERC721(multiSaleContract.settings.token)) {
            tokenHash_ = new uint256[](amount);
            for (uint256 i = 0; i < amount; i++) {
                uint256 nextId = erc721AStorage.erc721Contract._currentIndex;
                IERC721Mint(address(this)).mintTo(recipient, amount, data);
                tokenHash_[i] = nextId;
            }

        } else if (InterfaceChecker.isERC1155(multiSaleContract.settings.token)) {
            tokenHash_ = new uint256[](1);
            tokenHash_[0] = multiSaleContract.nonce++;  // TODO
            IERC1155Mint(address(this)).mintTo(
                recipient,
                tokenHash_[0],
                amount,
                ""
            );
        } else {
            require(false, "Token not supported");
        }
    }

    /// @notice Get the token sale settings
    /// @param tokenSaleId - the token sale id
    function getTokenSaleSettings(uint256 tokenSaleId)
        external
        view
        virtual
        returns (MultiSaleSettings memory settings) {

        settings = MultiSaleLib
            .multiSaleStorage()
            ._tokenSales[tokenSaleId].settings;
    }

    /// @notice Get the token sale ids
    function getTokenSaleIds() external view returns (uint256[] memory) {
        return MultiSaleLib.multiSaleStorage()._tokenSaleIds;
    }
}
