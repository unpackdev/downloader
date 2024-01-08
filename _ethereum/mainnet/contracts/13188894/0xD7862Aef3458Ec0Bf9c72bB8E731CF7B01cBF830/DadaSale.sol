pragma solidity >=0.6.0 <0.9.0;

import "./AccessControl.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
import "./IERC721.sol";

import "./console.sol";

interface IDadaNFT is IERC721 {}

interface IDadaReserve {
    function transfer(
        address to,
        uint256 drawingId,
        uint256 printIndex
    ) external;

    function offerCollectibleForSaleToAddress(
        uint256 drawingId,
        uint256 printIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function acceptBidForCollectible(
        uint256 drawingId,
        uint256 minPrice,
        uint256 printIndex
    ) external;

    function offerCollectibleForSale(
        uint256 drawingId,
        uint256 printIndex,
        uint256 minSalePriceInWei
    ) external;

    function withdrawOfferForCollectible(uint256 drawingId, uint256 printIndex)
        external;

    function withdraw() external;
}

interface IDadaCollectible {
    function drawingIdToCollectibles(uint256)
        external
        returns (
            uint256 drawingId,
            string memory checkSum,
            uint256 totalSupply,
            uint256 nextPrintIndexToAssign,
            bool allPrintsAssigned,
            uint256 initialPrice,
            uint256 initialPrintIndex,
            string memory collectionName,
            uint256 authorUId,
            string memory scarcity
        );

    function DrawingPrintToAddress(uint256) external returns (address);

    function alt_buyCollectible(uint256 drawingId, uint256 printIndex)
        external
        payable;

    function transfer(
        address to,
        uint256 drawingId,
        uint256 printIndex
    ) external returns (bool success);

    function makeCollectibleUnavailableToSale(
        address to,
        uint256 drawingId,
        uint256 printIndex,
        uint256 lastSellValue
    ) external;
}

/// @title DadaSale - Sale contract that interfaces with Reserve contract
/// @dev DadaSale must be granted Owner role on the reserve to transfer tokens
/// @author Isaac Patka
contract DadaSale is AccessControl {
    // Roles
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Reserve contract holding collectibles
    IDadaReserve dadaReserve;

    // Modified ERC20 contract
    IDadaCollectible dadaCollectible;

    // NFT interface for token swaps
    IERC721 dadaNFT;

    // Dada Multisig
    address public dadaNftReceiver;

    // Contract State
    // 0: Swap
    // 1: Purchase round 1
    // 2: Purchase round 2, ...
    mapping(uint256 => bool) public state;

    // Swap data structures
    struct Drawing {
        uint256 DrawingId;
        uint256 PrintIndex;
    }

    mapping(uint256 => Drawing) public swapList; // tokenId => drawingId
    mapping(uint256 => bool) public swapReserved; // print => isReserved

    // Sale data structures

    // Mapping to keep track of max drawings that can be purchased per address in a round
    mapping(uint256 => mapping(uint256 => uint256)) public capsPerDrawing;

    // Mapping to keep track of prices per round
    mapping(uint256 => mapping(uint256 => uint256)) public priceLists;

    // Mapping to keep track of drawings purchased by an address in a round
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        public purchases;

    // Mapping to keep track of addresses allowed for per round
    mapping(uint256 => mapping(address => bool)) public allowList;

    /// @dev constructor sets the interfaces to external contracts and grants admin and operator roles to deployer
    /// @param _dadaReserveAddress Contract holding the collectibles purchased from the ERC20 DadaCollectible contract
    /// @param _dadaCollectibleAddress ERC20 DadaCollectible contract
    /// @param _dadaNftAddress ERC721 DadaCollectible contract
    /// @param _dadaNftReceiverAddress Dada managed multisig
    constructor(
        address _dadaReserveAddress,
        address _dadaCollectibleAddress,
        address _dadaNftAddress,
        address _dadaNftReceiverAddress
    ) {
        dadaReserve = IDadaReserve(_dadaReserveAddress);
        dadaCollectible = IDadaCollectible(_dadaCollectibleAddress);
        dadaNFT = IERC721(_dadaNftAddress);
        dadaNftReceiver = _dadaNftReceiverAddress;
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Prevent ETH from getting stuck here
    receive() external payable {}

    // Operator role functions

    /// @dev Withdraw allows operator to retrieve ETH from the sale or sent directly to contract
    /// @param _to Address to receive the ETH
    function withdraw(address payable _to) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "!operator");
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "!transfer");
    }

    /// @dev Set the current active contract state
    ///  0: Swap Operator functions & NFT to ERC20 swaps enabled
    ///  1: Discount: Operator functions & round 1 purchases enabled
    ///  2: Discount: Operator functions & round 2 purchases enabled
    ///  ...
    /// @param _stateEnabled bool array to enable different features: [swap, discount, whitelist]
    function setContractState(bool[] calldata _stateEnabled) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "!operator");
        for (uint256 index = 0; index < _stateEnabled.length; index++) {
            state[index] = _stateEnabled[index];
        }
    }
    
    /// @dev Set the destination for swapped NFTs
    /// @param _dadaNftReceiverAddress bool array to enable different features: [swap, discount, whitelist]
    function setNftReceiver(address _dadaNftReceiverAddress) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "!operator");
        require(_dadaNftReceiverAddress != address(0), "!0-address");
        dadaNftReceiver = _dadaNftReceiverAddress;
    }

    /// @dev Set the list of NFTs that can be swapped for specific prints
    ///  Reserved prints can not be purchased
    ///  Requires that the reserve contract has the print specified. Reverts if not
    /// @param _tokenDrawingPrint 2D array with [NFT tokenId, ERC20 DrawingId, ERC20 PrintIndex]
    function setSwapList(uint256[3][] calldata _tokenDrawingPrint, bool enabled)
        external
    {
        require(hasRole(OPERATOR_ROLE, msg.sender), "!operator");
        for (uint256 index = 0; index < _tokenDrawingPrint.length; index++) {
            if (enabled) {
                swapReserved[_tokenDrawingPrint[index][2]] = true;
                swapList[_tokenDrawingPrint[index][0]] = Drawing(
                    _tokenDrawingPrint[index][1],
                    _tokenDrawingPrint[index][2]
                );
            } else {
                swapReserved[_tokenDrawingPrint[index][2]] = false;
                delete swapList[_tokenDrawingPrint[index][0]];
            }
        }
    }

    /// @dev Set the caps per drawing per round
    /// @param _round ID of the round
    /// @param _drawingCap Max purchases allowed per drawing - 0 means unlimited
    function setDrawingCap(uint256 _round, uint256[2][] calldata _drawingCap)
        external
    {
        require(hasRole(OPERATOR_ROLE, msg.sender), "!operator");
        for (uint256 index = 0; index < _drawingCap.length; index++) {
            capsPerDrawing[_round][_drawingCap[index][0]] = _drawingCap[index][
                1
            ];
        }
    }

    /// @dev Set the price list for the discounted round by drawingId
    /// @param _round ID of the round
    /// @param _drawingPrice 2D array with [ERC20 DrawingId, Price in ETH]
    function setPriceList(uint256 _round, uint256[2][] calldata _drawingPrice)
        external
    {
        require(hasRole(OPERATOR_ROLE, msg.sender), "!operator");
        // Round 0 is the swap round which does not have a price list
        require(_round > 0, "invalid-round");
        for (uint256 index = 0; index < _drawingPrice.length; index++) {
            priceLists[_round][_drawingPrice[index][0]] = _drawingPrice[index][
                1
            ];
        }
    }

    /// @dev Set the allowList status for specific buyers
    /// @param _buyers Array of buyer addresses
    /// @param _allowed State that applies to all buyers in this contract call
    function setAllowList(
        uint256 _round,
        address[] calldata _buyers,
        bool _allowed
    ) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "!operator");
        // Round 0 is the swap round which does not have an allow list
        require(_round > 0, "invalid-round");
        for (uint256 index = 0; index < _buyers.length; index++) {
            allowList[_round][_buyers[index]] = _allowed;
        }
    }

    /// @dev Purchase a discounted drawing by a buyer on whitelist, during the whitelist phase
    /// @param _round Round ID to purchase
    /// @param _drawingId ERC20 drawing ID to purchase
    /// @param _printIndex ERC20 print index to purchase
    function purchase(
        uint256 _round,
        uint256 _drawingId,
        uint256 _printIndex
    ) external payable {
        // Round must be active
        require(state[_round], "!round-state");

        // Sender must send exact price
        require(msg.value == priceLists[_round][_drawingId], "!value");

        // Sender must be on allowList
        require(allowList[_round][msg.sender], "!allowList");

        // Prints that are reserved for swaps cannot be purchased by anyone
        require(!swapReserved[_printIndex], "reserved");

        // Require the cap is not reached per drawing if enabled
        require(
            purchases[_round][msg.sender][_drawingId] <
                capsPerDrawing[_round][_drawingId] ||
                capsPerDrawing[_round][_drawingId] == 0,
            "!cap"
        );

        // Track how many of this drawing the address has purchased
        purchases[_round][msg.sender][_drawingId]++;

        // Manually set the last purchase price and seller in the ERC20 contract
        dadaReserve.transfer(address(this), _drawingId, _printIndex);
        dadaCollectible.makeCollectibleUnavailableToSale(
            address(this),
            _drawingId,
            _printIndex,
            priceLists[_round][_drawingId]
        );
        dadaCollectible.transfer(msg.sender, _drawingId, _printIndex);
    }

    /// @dev Swap an NFT for an ERC20, during the swap phase
    /// @param _tokenId ERC721 tokenID to swap
    function swapToken(uint256 _tokenId) external {
        require(state[0], "!swap-state");

        // Retrieve specific drawingId and Print to swap
        uint256 drawingId = swapList[_tokenId].DrawingId;
        uint256 printIndex = swapList[_tokenId].PrintIndex;

        // Ensure there is a reserved print
        require(swapReserved[printIndex], "!swap-eligible");

        // Ensure the reserve still owns this print
        require(
            dadaCollectible.DrawingPrintToAddress(printIndex) ==
                address(dadaReserve),
            "!available"
        );

        // Remove from the swap list
        delete swapList[_tokenId];
        swapReserved[printIndex] = false;

        // Transfer NFT to multisig
        dadaNFT.transferFrom(msg.sender, dadaNftReceiver, _tokenId);

        // Transfer ERC20 from reserve to swapper
        dadaReserve.transfer(msg.sender, drawingId, printIndex);
    }
}
