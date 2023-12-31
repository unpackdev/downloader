// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./ERC721SeaDrop.sol";
import "./IReplicatorController.sol";
import "./IKaijuMartRedeemable.sol";

error Replicator_NotAllowed();
error Replicator_Soulbound();
error Replicator_TokenDoesNotExist();

/**
                        .             :++-
                       *##-          +####*          -##+
                       *####-      :%######%.      -%###*
                       *######:   =##########=   .######*
                       *#######*-#############*-*#######*
                       *################################*
                       *################################*
                       *################################*
                       *################################*
                       *################################*
                       :*******************************+.

                .:.
               *###%*=:
              .##########+-.
              +###############=:
              %##################%+
             =######################
             -######################++++++++++++++++++=-:
              =###########################################*:
               =#############################################.
  +####%#*+=-:. -#############################################:
  %############################################################=
  %##############################################################
  %##############################################################%=----::.
  %#######################################################################%:
  %##########################################+:    :+%#######################:
  *########################################*          *#######################
   -%######################################            %######################
     -%###################################%            #######################
       =###################################-          :#######################
     ....+##################################*.      .+########################
  +###########################################%*++*%##########################
  %#########################################################################*.
  %#######################################################################+
  ########################################################################-
  *#######################################################################-
  .######################################################################%.
     :+#################################################################-
         :=#####################################################:.....
             :--:.:##############################################+
   ::             +###############################################%-
  ####%+-.        %##################################################.
  %#######%*-.   :###################################################%
  %###########%*=*####################################################=
  %####################################################################
  %####################################################################+
  %#####################################################################.
  %#####################################################################%
  %######################################################################-
  .+*********************************************************************.
 * @title KAIJU ORIGINS: The Journals of Stod - Replicator
 * @notice See https://origins.kaijukingz.io/ for more details.
 * @author Augminted Labs, LLC
 */
contract Replicator is ERC721SeaDrop, IKaijuMartRedeemable {
    IReplicatorController public replicatorController;
    address public kmart;

    constructor(
        address _replicatorController,
        address _kmart,
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    )
        ERC721SeaDrop(name, symbol, allowedSeaDrop)
    {
        replicatorController = IReplicatorController(_replicatorController);
        kmart = _kmart;
    }

    /**
     * @notice Modifier requiring a replicator to be unused
     * @param _replicatorId Replicator being transferred
     */
    modifier notSoulbound(uint256 _replicatorId) {
        if (pagesMinted(_replicatorId) != 0) revert Replicator_Soulbound();
        _;
    }

    /**
     * @notice Returns the number of pages minted by a specified replicator
     * @param _replicatorId Replicator to return the number of minted pages for
     */
    function pagesMinted(uint256 _replicatorId) public view returns (uint256) {
        return replicatorController.pagesMinted(_replicatorId);
    }

    /**
     * @inheritdoc ERC721SeaDrop
     */
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721SeaDrop)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert Replicator_TokenDoesNotExist();

        return bytes(_baseURI()).length > 0 ?
            string(abi.encodePacked(_baseURI(), _toString(pagesMinted(tokenId)))) :
            "";
    }

    /*
     * @notice Estimate the cost of performing a specified cross-chain function on a token
     * @param _functionType Cross-chain function to perform
     * @param _dstChainId Destination chain's LayerZero ID
     * @param _toAddress Address to receive the tokens
     * @param _replicatorId Replicator to use to mint
     * @param _amount Amount of pages to mint
     * @param _useZro Flag indicating whether to use $ZRO for payment
     * @param _adapterParams Parameters for custom functionality
     */
    function estimateFee(
        uint16 _functionType,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _replicatorId,
        uint256 _amount,
        bool _useZro,
        bytes memory _adapterParams
    ) public view returns (uint256 nativeFee, uint256 zroFee) {
        return replicatorController.estimateFee(
            _functionType,
            _dstChainId,
            _toAddress,
            _replicatorId,
            _amount,
            _useZro,
            _adapterParams
        );
    }

    /*
     * @notice Estimate the cost of performing a specified cross-chain function on a batch of tokens
     * @param _functionType Cross-chain function to perform
     * @param _dstChainId Destination chain's LayerZero ID
     * @param _toAddress Address to receive the tokens
     * @param _replicatorIds Replicators to use to mint
     * @param _amounts Amounts of pages to mint
     * @param _useZro Flag indicating whether to use $ZRO for payment
     * @param _adapterParams Parameters for custom functionality
     */
    function estimateBatchFee(
        uint16 _functionType,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bool _useZro,
        bytes memory _adapterParams
    ) public view returns (uint256 nativeFee, uint256 zroFee) {
        return replicatorController.estimateBatchFee(
            _functionType,
            _dstChainId,
            _toAddress,
            _tokenIds,
            _amounts,
            _useZro,
            _adapterParams
        );
    }

    /**
     * @notice Set the address of the replicator controller contract
     * @param _replicatorController Address of the replicator controller contract
     */
    function setReplicatorController(address _replicatorController) public onlyOwner {
        replicatorController = IReplicatorController(_replicatorController);
    }

    /**
     * @notice Set the address of the kmart contract
     * @param _kmart Address of the kmart contract
     */
    function setKmart(address _kmart) public onlyOwner {
        kmart = _kmart;
    }

    /**
     * @notice Mint a specified number of replicators from a kmart lot
     * @param _amount Amount of replicators to mint
     * @param _to Address receiving the replicators
     */
    function kmartRedeem(uint256, uint32 _amount, address _to) public {
        if (msg.sender != kmart) revert Replicator_NotAllowed();

        _mint(_to, _amount);
    }

    /**
     * @notice Mint a specified amount of next pages in the series using a replicator
     * @param _replicatorId Replicator to use to mint the next pages in the series
     * @param _amount Amount of next pages in the series to mint
     */
    function replicate(uint256 _replicatorId, uint256 _amount) public {
        if (ownerOf(_replicatorId) != msg.sender) revert Replicator_NotAllowed();

        replicatorController.replicate(_replicatorId, _amount);
    }

    /**
     * @notice Mint a specified amount of the next pages in the series to a destination chain using a replicator
     * @dev For more details see https://layerzero.gitbook.io/docs/evm-guides/master
     * @param _replicatorId Replicator to use to mint the next pages in the series from
     * @param _amount Amount of next pages in the series to mint
     * @param _dstChainId Destination chain's LayerZero ID
     * @param _toAddress Address to receive the tokens
     * @param _refundAddress Address to send refund to if transaction is cheaper than expected
     * @param _zroPaymentAddress Address of $ZRO token holder that will pay for the transaction
     * @param _adapterParams Parameters for custom functionality
     */
    function replicateFrom(
        uint256 _replicatorId,
        uint256 _amount,
        uint16 _dstChainId,
        bytes memory _toAddress,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) public payable {
        if (ownerOf(_replicatorId) != msg.sender) revert Replicator_NotAllowed();

        replicatorController.replicateFrom{value: msg.value}(
            _replicatorId,
            _amount,
            _dstChainId,
            _toAddress,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    /**
     * @dev Replicators are soulbound after first use
     * @inheritdoc ERC721SeaDrop
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721SeaDrop)
        notSoulbound(tokenId)
    {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Replicators are soulbound after first use
     * @inheritdoc ERC721SeaDrop
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721SeaDrop)
        notSoulbound(tokenId)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Replicators are soulbound after first use
     * @inheritdoc ERC721SeaDrop
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721SeaDrop)
        notSoulbound(tokenId)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}