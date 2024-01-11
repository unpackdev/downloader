// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OrderBookI.sol";
import "./IMGD.sol";
import "./ISP.sol";
import "./IERC1155SupplyUpgradeable.sol";

contract OrderBook is OrderBookI, OwnableUpgradeable, ERC1155HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    uint256 public orderCounter;
    uint256 public mintFee;
    uint256 public listingFee;
    address payable public withdrawAddress;

    bool public openListings;

    IMGD public mgd;

    mapping(uint256 => Order) public orders;
    mapping(uint256 => bool) public listedBefore;
    mapping(uint256 => uint256) public primaryTracker;

    uint256 public collectorsFee;

    struct Order {
        uint256 tokenId;
        uint256 askingPrice;
        uint256 amount;
        address creator;
        address token;
        address nft;
        bool orderValid;
        bool lookingFor;
        bool splitPayable;
    }

    struct FulfillBuf {
        address payable nftReceiver;
        address payable paymentReceiver;
        address nftHolder;
        uint256 initialPrice;
        uint256 price;
        uint256 platformFee;
        uint256 fee;
        bool isPrimaryMarket;
        uint256 collectorsFee;
        uint256 numberOfIssues;
    }

      ISP public isp;

    function initialize(address _mgdContract, address payable _withdrawAddress)
        public
        initializer
    {
        OwnableUpgradeable.__Ownable_init();
        ERC1155HolderUpgradeable.__ERC1155Holder_init();
        mgd = IMGD(_mgdContract);
        openListings = false;
        require(
            _withdrawAddress != address(0),
            "Orderbook ERR: withdraw address cannot be zero"
        );
        withdrawAddress = _withdrawAddress;
        mintFee = 150000;
        listingFee = 50000;
        collectorsFee = 30000;
    }

    modifier notPaused() {
        require(!mgd.isPaused(), "Orderbook ERR: MGD platform is paused");
        _;
    }

    modifier onlyIGovernance(address _address) {
        require(mgd.isIGovernance(_address), "MGD ERR: No initialGovernance");
        _;
    }

    /**
  @notice createOrderExisting allows for the creation of a new order for an existing NFT
  @param _tokenId is the id of the NFT token being sold in the order
  @param _askingPrice is the asking price in 1e18
  @param _amount is the amount of tokens in the order
  @param _token is the address of the ERC20 token the NFT will be exchanged for(use 0x0 add for ETH)
  @param _nft is the address of the NFT contract for the NFT being added to the order
  @param _lookingFor is aa bool representing whether or not the asker owns the NFT
  */
    function createOrderExisting(
        uint256 _tokenId,
        uint256 _askingPrice,
        uint256 _amount,
        address _token,
        address _nft,
        bool _lookingFor
    ) public payable override notPaused returns (uint256) {
        IERC1155Upgradeable nft = IERC1155Upgradeable(_nft);
        if (!openListings) {
            require(_nft == address(mgd), "Orderbook ERR: wrong NFT contract");
        }
        if (!_lookingFor) {
            require(
                nft.balanceOf(_msgSender(), _tokenId) >= _amount,
                "Orderbook ERR: doesnt own this amount of NFTs"
            );
            nft.safeTransferFrom(
                _msgSender(),
                address(this),
                _tokenId,
                _amount,
                ""
            );
        } else if (_token != address(0)) {
            IERC20Upgradeable token = IERC20Upgradeable(_token);
            require(
                token.balanceOf(msg.sender) >= _askingPrice,
                "Orderbook ERR: not enough Token"
            );
            token.safeTransferFrom(_msgSender(), address(this), _askingPrice);
        } else {
            require(msg.value == _askingPrice, "Orderbook ERR: Not enough ETH");
        }

        orderCounter++;
        Order storage order = orders[orderCounter];
        order.tokenId = _tokenId;
        order.askingPrice = _askingPrice;
        order.creator = msg.sender;
        order.token = _token;
        order.nft = _nft;
        order.orderValid = true;
        order.amount = _amount;
        order.lookingFor = _lookingFor;

        emit OrderPlaced(
            order.tokenId,
            orderCounter,
            order.askingPrice,
            order.amount,
            msg.sender,
            order.token,
            order.lookingFor,
            true
        );
        return orderCounter;
    }

    /**
  @notice createOrderNew allows for the creation of a new order for new NFT
  @param _orgName string that represents the name of the organizastion the artist belongs to
  @param _metadataUri  is a string where the metadata URI for the NFT is stored
  @param _royaltyReceiver the address taht will receive the royalties when this NFT is traded on the platform
  @param _token is the address of the ERC20 token the NFT will be exchanged for(use 0x0 add for ETH)
  @param _for is the address of the artist the NFT(s) are being minted for
  @param _askingPrice is the asking price in 1e18
  @param _royalty the percentage value of the royalty?
  */
    function createOrderNew(
        string memory _orgName,
        string memory _metadataUri,
        address _royaltyReceiver,
        address _token,
        address _for,
        uint256 _askingPrice,
        uint256 _issues,
        uint24 _royalty,
        bool _splitPayable
    ) external override notPaused returns (uint256) {
        require(
            mgd.hasAuthorization(_for, _orgName),
            "Must have mint permissions"
        );

        uint256 id = mgd.mint(
            _orgName,
            _metadataUri,
            address(this),
            _royaltyReceiver,
            _for,
            _issues,
            _royalty,
            _splitPayable
        );

        orderCounter++;
        Order storage order = orders[orderCounter];
        order.tokenId = id;
        order.askingPrice = _askingPrice;
        order.creator = _for;
        order.token = _token;
        order.nft = address(mgd);
        order.orderValid = true;
        order.amount = _issues;
        order.splitPayable = _splitPayable;

        emit OrderPlaced(
            order.tokenId,
            orderCounter,
            order.askingPrice,
            _issues,
            _for,
            order.token,
            false,
            true
        );
        return orderCounter;
    }

    /**
  @notice fulfillOrder allows for the fulfillment of an order either when the order price is met
            OR when a counter offer has been accepted
  @param _orderId is the id of the order being fulfilled
  @dev this function will mint a new NFT to the fulfiller if the NFT does not yet exist
        this function transfers the funds from the purchaser to the artist/seller AND
        the NFT from the artist/owner
    */
    function fulfillOrder(uint256 _orderId, uint256 _numberOfIssues, bool _splitPayable)
        external
        payable
        override
        notPaused
    {
        Order storage order = orders[_orderId];
        FulfillBuf memory fulBuff;
        uint256 priceNet;
        uint256 priceFinal;
        
        order.splitPayable = _splitPayable;
        fulBuff.numberOfIssues = _numberOfIssues;

        fulBuff.initialPrice = fulBuff.numberOfIssues.mul(order.askingPrice);
        fulBuff.collectorsFee = ((fulBuff.initialPrice * collectorsFee) /
            1000000);

        IERC1155Upgradeable nft = IERC1155Upgradeable(order.nft);

        //check order is valid
        require(order.orderValid, "Orderbook ERR: order not valid");

        if (order.nft == address(mgd)) {
            if (!listedBefore[order.tokenId]) {
                listedBefore[order.tokenId] = true;
                IERC1155SupplyUpgradeable mgdSupply = IERC1155SupplyUpgradeable(
                    order.nft
                );
                primaryTracker[order.tokenId] = mgdSupply.totalSupply(
                    order.tokenId
                );
                fulBuff.fee = mintFee;
                fulBuff.isPrimaryMarket = true;
                primaryTracker[order.tokenId] = primaryTracker[order.tokenId]
                    .sub(fulBuff.numberOfIssues);
            } else if (primaryTracker[order.tokenId] > 0) {
                fulBuff.fee = mintFee;
                fulBuff.isPrimaryMarket = true;
                if (fulBuff.numberOfIssues >= primaryTracker[order.tokenId]) {
                    primaryTracker[order.tokenId] = 0;
                } else {
                    primaryTracker[order.tokenId] = primaryTracker[
                        order.tokenId
                    ].sub(fulBuff.numberOfIssues);
                }
            } else {
                fulBuff.fee = listingFee;
                fulBuff.isPrimaryMarket = false;
            }
        } else {
            fulBuff.fee = listingFee;
            fulBuff.isPrimaryMarket = false;
        }

        fulBuff.platformFee = ((fulBuff.initialPrice * fulBuff.fee) / 1000000);
        priceNet = fulBuff.initialPrice.sub(fulBuff.platformFee);
        //calculate royalties
        (address _receiver, uint256 _royaltyAmount) = mgd.royaltyInfo(
            order.tokenId,
            priceNet
        );
        priceFinal = (priceNet -_royaltyAmount);
        address payable artist = payable(_receiver);

        ///check if order is to buy or sell NFT
        if (!order.lookingFor) {
            //Listing

            //Artist
            fulBuff.paymentReceiver = payable(order.creator);

            //Collector
            fulBuff.nftReceiver = payable(msg.sender);

            //Orderbook
            fulBuff.nftHolder = address(this);
        } else {
            //Bids

            //Artist
            fulBuff.paymentReceiver = payable(msg.sender);

            //Collector
            fulBuff.nftReceiver = payable(order.creator);

            //artist
            fulBuff.nftHolder = msg.sender;
        }
        //transfer the money
        //if buying in ETH
        if (order.token == address(0)) {
            if (!order.lookingFor) {
                //if listing
                require(
                    msg.value == fulBuff.initialPrice + fulBuff.collectorsFee,
                    "OrderBook ERR: not enough ETH"
                );
            }
            (bool success, bytes memory returndata) = withdrawAddress.call{
                value: fulBuff.platformFee + fulBuff.collectorsFee,
                gas: 5000
            }("");
            require(success, string(returndata));
            if (order.splitPayable) {
              isp = ISP(_receiver);
              isp.splitPayment{value:priceFinal, gas: uint256(gasleft() / 2)}(
                  fulBuff.nftReceiver
              );
            } else {
                fulBuff.paymentReceiver.transfer(priceFinal);
            }
            (bool success2,) = artist.call{value: _royaltyAmount, gas: uint256(gasleft() / 2)}("");
            require(success2);
        } else if (!order.lookingFor) {
            //If buying list in token
            IERC20Upgradeable token = IERC20Upgradeable(order.token);
            token.safeTransferFrom(
                fulBuff.nftReceiver,
                withdrawAddress,
                fulBuff.platformFee + fulBuff.collectorsFee
            );
            if (order.splitPayable) {
                    isp.splitPaymentERC20(
                        fulBuff.nftReceiver,
                        order.token,
                        priceFinal
                    );
            } else {
                token.safeTransferFrom(
                    fulBuff.nftReceiver,
                    fulBuff.paymentReceiver,
                    (priceFinal)
                );
            }
            token.safeTransferFrom(fulBuff.nftReceiver, artist, _royaltyAmount);
        } else {
            //If fulfilling bid in token

            //Token Address
        IERC20Upgradeable token = IERC20Upgradeable(order.token);

        if(order.splitPayable) {
            isp.splitPaymentERC20(fulBuff.paymentReceiver, order.token,  priceFinal);

            //Platform fee: From Collector to withdraw address
            token.safeTransfer(
                withdrawAddress,
                fulBuff.platformFee + fulBuff.collectorsFee
            );

            //Royalty Amount: From Collector to artist.
            token.safeTransfer(artist, _royaltyAmount);
            token.safeTransfer(
                fulBuff.paymentReceiver,
                (priceFinal)
            );
        }
   }
        //transfer the NFT
        nft.safeTransferFrom(
            fulBuff.nftHolder,
            fulBuff.nftReceiver,
            order.tokenId,
            fulBuff.numberOfIssues,
            ""
        );

        order.amount = order.amount.sub(fulBuff.numberOfIssues);

        if (order.amount == 0) {
            order.orderValid = false;
        }

        emit OrderFulfilled(
            _orderId,
            fulBuff.initialPrice,
            fulBuff.platformFee,
            _royaltyAmount,
            fulBuff.paymentReceiver,
            fulBuff.numberOfIssues,
            fulBuff.isPrimaryMarket,
            msg.sender
        );
    }

    /**
  @notice cancelOrder allows for the cancleation of an order
  @param _orderId is the id of the order being fulfilled
*/
    function cancelOrder(uint256 _orderId) external override notPaused {
        Order storage order = orders[_orderId];
        require(
            msg.sender == order.creator,
            "OrderBook ERR: does not have permission to cancel order"
        );
        order.orderValid = false;
        if (!order.lookingFor) {
            IERC1155Upgradeable nft = IERC1155Upgradeable(order.nft);
            nft.safeTransferFrom(
                address(this),
                order.creator,
                order.tokenId,
                order.amount,
                ""
            );
        } else {
            if (order.token == address(0)) {
                address payable creator = payable(order.creator);
                creator.transfer(order.askingPrice);
            } else {
                IERC20Upgradeable token = IERC20Upgradeable(order.token);
                token.safeTransfer(order.creator, order.askingPrice);
            }
        }
        emit OrderCanceled(_orderId);
    }

    /**
    @notice unlockPlatform allows for owner of this contract to open up the platforms listings to
            non MGD NFT types
    */
    function unlockPlatform() external override onlyIGovernance(_msgSender()) {
        openListings = true;
    }

    /**
    @notice setMintFee allows the owner to set the fee for minting and listing through the orderbook
    @param _fee is the value representing the percentage of a sale taken as a platform fee
    */
    function setMintFee(uint256 _fee)
        external
        override
        onlyIGovernance(_msgSender())
    {
        mintFee = _fee;
    }

    /**
    @notice setListingFee allows the owner to set the fee for secondary listings through the orderbook
    @param _fee is the value representing the percentage of a sale taken as a platform fee
    */
    function setListingFee(uint256 _fee)
        external
        override
        onlyIGovernance(_msgSender())
    {
        listingFee = _fee;
    }

    /**
    @notice setCollectorsFee allows the owner to set a collectors fee (paid out to MGD)
    @param _fee is the value representing the percentage of a sale taken as a platform fee
    */
    function setCollectorsFee(uint256 _fee)
        external
        onlyIGovernance(_msgSender())
    {
        collectorsFee = _fee;
    }

    /**
    @notice setFeeAdd allows the owner to set the fee address
    @param _add is the address that will receive the fee's
    */
    function setFeeAdd(address _add)
        external
        override
        onlyIGovernance(_msgSender())
    {
        withdrawAddress = payable(_add);
    }
}
