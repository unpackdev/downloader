// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// @title:      Bored Cat
// @twitter:    https://twitter.com/Bcatnft
// @url:        https://boredcatnft.com/
// @dev:        smartcontract@nejdouma.com
//       
//         ____    ____    ____    ______  ____       ______  ___    ______
//        / __ )  / __ \  / __ \  / ____/ / __ \     / ____/ /   |  /_  __/
//       / __  | / / / / / /_/ / / __/   / / / /    / /     / /| |   / /   
//      / /_/ / / /_/ / / _, _/ / /___  / /_/ /    / /___  / ___ |  / /    
//     /_____/  \____/ /_/ |_| /_____/ /_____/     \____/ /_/  |_| /_/     
//
//     F I R S T   N F T   P F P    C O L L E C T I O N    I N    S P A C E         
//                                                                                                  
//     ▄▄▄                                                               ▄▄▄
//    ▐██████▄,                                                     ,▄██████▌
//    ╟██████████▄                                               ▄██████████▌
//    █████████████▓                                          ,▓█████████████
//    ████████████████µ                                     ,████████████████
//    ██████████████████                                   ▓█████████████████
//    ███████████████████                                 ███████████████████
//    ██████████████▓▄▀▀▀`                                ▀▀▀,▓██████████████
//    ╫████████████▀W                                        ─ª▀████████████▌
//    ▐██████████▌¬                                             ─▀██████████▌
//     ████████▀─                                                  ▀████████─
//     ███████─                                                      ███████
//     ╟████▀                                                         ╙████▌
//      ███                                                             ███
//      ╙▀                                                               ▀▀
// 
// 
// 
// 
// 
// 
//          ╙████████████▌▐██████¬               ^████████████▌▐██████▀
//            ▀████████████████▀        ╓▄╓        ▀████████████████▀─
//              ╙▀██████████▀╙        ███████        ╙▀██████████▀▀
//                   └└└└              └╙▀╙└              └└└└
//
//

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

contract BoredCatOrigins is ERC721A, Ownable, ReentrancyGuard {

    using Address for address;
    using MerkleProof for bytes32[];

    // ================================================== //
    //              *** MULTIVERSE STORAGE ***
    // ================================================== //
    
    // @notice The address of the contract permitted to mint multiverse Bored Cats.
    address public portalGunContract;

    uint256 public secondMultiverseDimensionSupply;
    uint256 public thirdMultiverseDimensionSupply;
    uint256 public fourthMultiverseDimensionSupply;
    uint256 public fifthMultiverseDimensionSupply;

    bool public secondMultiverseMintPaused = true;
    bool public thirdMultiverseMintPaused = true;
    bool public fourthMultiverseMintPaused = true;
    bool public fifthMultiverseMintPaused = true;

    
    // ================================================== //
    //              *** PRESALE STORAGE ***
    // ================================================== //

    uint256 public presaleMintPrice = 0.2 ether;
    uint256 public presaleMintMaxSupply;
    bool public presaleMintPaused = true;

    // ================================================== //
    //       *** AUTO BURN DUTCH AUCTION STORAGE ***
    // ================================================== //

    uint256 public auctionStartPrice = 1 ether;
    uint256 public auctionEndPrice = 0.4 ether;
    uint256 public auctionPriceCurveLength = 330 minutes;
    uint256 public auctionDropInterval = 30 minutes;
    uint256 public auctionDropPerStep =
                (auctionStartPrice - auctionEndPrice)
                    / (auctionPriceCurveLength / auctionDropInterval);
    uint256 public auctionSaleStartTime;
    uint256 public auctionSaleEndTime;
    uint256 public lastAuctionSupplyBurnTime;

    // ================================================== //
    //          *** COLLECTION PARAMS STORAGE ***
    // ================================================== //

    uint256 public collectionSize = 8842;
    uint256 public reservedSize;
    uint256 public maxItemsPerWallet = 5;
    uint256 public maxItemsPerTx = 5;
    uint64 public publicMintPrice = 1 ether;
    bool public publicMintPaused = true;
    bytes32 public eligibleMerkleRoot;
    string public baseTokenURI;

    // ================================================== //
    //                 *** CONSTRUCTOR ***
    // ================================================== //

    constructor() ERC721A("Bored Cat Origins", "BCO", 10) {}

    // ================================================== //
    //                  *** MODIFIER ***
    // ================================================== //

    function _onlySender() private view {
        require(msg.sender == tx.origin);
    }

    modifier onlySender {
        _onlySender();
        _;
    }

    // ================================================== //
    //      *** COMMUNITY SUSTAINABILITY RESERVES ***
    // ================================================== //
    
    // @notice Mint reserved token for sustainable community development: marketing etc
    function communityMint(uint256 amount) external onlySender onlyOwner {
        require(amount <= reservedSize, "Minting amount exceeds reserved size");
        require((totalSupply() + amount) <= collectionSize, "Sold out!");
        require(
            amount % maxBatchSize == 0,
            "Can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = amount / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
        reservedSize -= amount;
    }

    // ================================================== //
    //              *** PRESALE MINT LOGIC ***
    // ================================================== //

    function presaleMint(bytes32[] memory proof) external payable onlySender nonReentrant {

        uint256 _presaleMintMaxSupply = presaleMintMaxSupply;
        require(!presaleMintPaused, "Presale mint is paused");
        require(_presaleMintMaxSupply > 0, "Presale mint is sold out");

        require(isAddressEligible(proof, msg.sender), "You are not eligible for presale mint");

        uint256 amount = _getMintAmount(msg.value, presaleMintPrice);
        
        require(
            amount <= maxItemsPerTx,
            "Minting amount exceeds allowance per tx"
        );
        require(
            numberMinted(msg.sender) + amount <= maxItemsPerWallet,
            "Minting amount exceeds allowance per wallet"
        );

        require(_presaleMintMaxSupply >= amount, "Not enough supply remaining to support desired presale mint amount");

        presaleMintMaxSupply = _presaleMintMaxSupply - amount;

        _mintWithoutValidation(msg.sender, amount);
    }

    // ======================================================== //
    // *** AUTO BURN DUTCH AUCTION MINT LOGIC (ISS Algorithm) ***
    // ======================================================== //

    function auctionMint(uint256 quantity) external payable onlySender nonReentrant {
        
        uint256 _saleStartTime = uint256(auctionSaleStartTime);
        
        require(_saleStartTime != 0 && block.timestamp >= _saleStartTime,"Sale has not started yet");

        // Before minting, update the collection supply on runtime using the ISS algorithm (Iterative Smart Supply)
        _autoBurnAuctionSupply();

        if (block.timestamp > auctionSaleEndTime) {
            
            // The auction already ended. Issue refund instead of raising an error
            // so the supply update gets stored.
            // Needed in case of automatic remaining supply burn after the end of the auction.
            refundIfOver(0);

        } else {
        
            require((totalSupply() + quantity) <= (collectionSize - reservedSize), "Not enough supply remaining to support desired mint amount");
            
            require(numberMinted(msg.sender) + quantity <= maxItemsPerWallet,"Minting amount exceeds allowance per wallet");

            require( quantity <= maxItemsPerTx, "Minting amount exceeds allowance per tx");

            uint256 totalCost = getAuctionPrice(_saleStartTime) * quantity;
            _safeMint(msg.sender, quantity);
            refundIfOver(totalCost);

        }
    }

    // ================================================== //
    //              *** MULTIVERSE LOGIC ***
    // ================================================== //

    /// @notice Sets the address of the contract permitted to call mintMultiverseBoredCat
    /// @param _portalGunContract The address of the Portal Gun contract
    function setPortalGunContract(address _portalGunContract) public onlyOwner {
        portalGunContract = _portalGunContract; 
    }

    /// @notice Thrown when an invalid Multiverse Dimension is given by the Portal Gun contract.
    error UnknownMultiverseDimension();

    /// @notice Thrown when the caller is not the Portal Gun contract, and is trying to mint an alter Bored Cat.
    error UnauthorizedPortal();

    /// @notice Mints a Bored Cat from a parallel univers
    /// @param receiver Receiver of the alter Bored Cat
    /// @param parallelUniverseId The id of the origin parallel universe of the alter Bored Cat, initial Ids 2 to 5
    function mintMultiverseBoredCat(address receiver, uint parallelUniverseId) public payable {
        if(msg.sender != portalGunContract) revert UnauthorizedPortal();

        if (parallelUniverseId == 2) {
            require(!secondMultiverseMintPaused, "Multiverse Dimension 2 mint is paused");
            _mintMultivereDimension(receiver);
            unchecked {
                secondMultiverseDimensionSupply++;
            }
        } else if (parallelUniverseId == 3) {
            require(!thirdMultiverseMintPaused, "Multiverse Dimension 3 mint is paused");
            _mintMultivereDimension(receiver);
            unchecked {
                thirdMultiverseDimensionSupply++;
            }
        } else if (parallelUniverseId == 4) {
            require(!fourthMultiverseMintPaused, "Multiverse Dimension 4 mint is paused");
            _mintMultivereDimension(receiver);
            unchecked {
                fourthMultiverseDimensionSupply++;
            }
        } else if (parallelUniverseId == 5) {
            require(!fifthMultiverseMintPaused, "Multiverse Dimension 5 mint is paused");
            _mintMultivereDimension(receiver);
            unchecked {
                fifthMultiverseDimensionSupply++;
            }
        } else  {
            revert UnknownMultiverseDimension();
        }
    }

    // ================================================== //
    //              *** PUBLIC MINT LOGIC ***
    // ================================================== //

    function publicMint() external payable onlySender nonReentrant {

        require(!publicMintPaused, "Public mint is paused");

        uint256 amount = _getMintAmount(msg.value, publicMintPrice);

        require(
            amount <= maxItemsPerTx,
            "Minting amount exceeds allowance per tx"
        );
        require(
            numberMinted(msg.sender) + amount <= maxItemsPerWallet,
            "Minting amount exceeds allowance per wallet"
        );

        _mintWithoutValidation(msg.sender, amount);
    }

    // ================================================== //
    //                    *** HELPER ***
    // ================================================== //

    function getAuctionPrice(uint256 _saleStartTime)
        public
        view
        returns (uint256)
    {
        if (block.timestamp < _saleStartTime) {
            return auctionStartPrice;
        }
        if (block.timestamp - _saleStartTime >= auctionPriceCurveLength) {
            return auctionEndPrice;
        } else {
            uint256 steps = (block.timestamp - _saleStartTime) /
                auctionDropInterval;
            return auctionStartPrice - (steps * auctionDropPerStep);
        }
    }

    // @notice Updates the collection supply on runtime using the ISS algorithm (Iterative Smart Supply)
    function _autoBurnAuctionSupply() private {

        uint256 usedSupply = totalSupply() + reservedSize;
        uint256 _block_timestamp = block.timestamp;

        // If The Dutch Auction Already Ended, Automatically Burn All The Remaining Supply
        // Else, Iterativery Update The Supply By 
        // Automatically Burning 10% Of The Remaining Supply At Each Step
        if (_block_timestamp > auctionSaleEndTime) {
            
            collectionSize = usedSupply;
            lastAuctionSupplyBurnTime = _block_timestamp;

        } else if (lastAuctionSupplyBurnTime < auctionSaleStartTime + auctionPriceCurveLength) { 

            uint256 curveLengthSinceLastUpdate = min(_block_timestamp, auctionSaleStartTime + auctionPriceCurveLength) - lastAuctionSupplyBurnTime;
            
            if ( curveLengthSinceLastUpdate > auctionDropInterval) {

                uint256 remainingSupply = collectionSize - usedSupply;
                uint256 burnQuantity = 0;
                uint256 numBurnSteps = curveLengthSinceLastUpdate / auctionDropInterval;

                for (uint256 i = 0; i < numBurnSteps; i++) {
                    // Burn 10% of the remaining supply at each step
                    burnQuantity += (remainingSupply - burnQuantity)/10;
                }
                collectionSize = max(usedSupply, collectionSize -  burnQuantity);
                lastAuctionSupplyBurnTime = _block_timestamp;
            }
        }
    }

    function _getMintAmount(uint256 value, uint256 mintPrice) internal view returns (uint256) {
        uint256 remainder = value % mintPrice;
        require(remainder == 0, "Send a divisible amount of eth");

        uint256 amount = value / mintPrice;
        require(amount > 0, "Amount to mint is 0");
        require(
            (totalSupply() + amount) <= (collectionSize - reservedSize),
            "Sold out!"
        );
        return amount;
    }

    function _mintWithoutValidation(address to, uint256 amount) internal {
        require((totalSupply() + amount) <= (collectionSize - reservedSize), "Sold out!");
        _safeMint(to, amount);
    }

    function _mintMultivereDimension(address to) internal {
        _mintWithoutValidation(to, 1);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function isAddressEligible(bytes32[] memory proof, address _address)
        public
        view
        returns (bool)
    {
        return isAddressInMerkleRoot(eligibleMerkleRoot, proof, _address);
    }

    function isAddressInMerkleRoot(
        bytes32 merkleRoot,
        bytes32[] memory proof,
        address _address
    ) internal pure returns (bool) {
        return proof.verify(merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // ================================================== //
    //              *** SETTER *** (owner only)
    // ================================================== //

    function setPresaleMintPaused(bool _presaleMintPaused) external onlyOwner{
        presaleMintPaused = _presaleMintPaused;
    }

    function setEligibleMerkleRoot(bytes32 _eligibleMerkleRoot)
        external
        onlyOwner
    {
        eligibleMerkleRoot = _eligibleMerkleRoot;
    }

    function setMaxItemsPerTx(uint256 _maxItemsPerTx) external onlyOwner {
        maxItemsPerTx = _maxItemsPerTx;
    }

    function setMaxItemsPerWallet(uint256 _maxItemsPerWallet) external onlyOwner {
        maxItemsPerWallet = _maxItemsPerWallet;
    }

    function setPublicMintPaused(bool _publicMintPaused) external onlyOwner {
        publicMintPaused = _publicMintPaused;
    }

    function setPreSaleConfig(
        uint256 _presaleMintPrice,
        uint256 _collectionSize,
        uint256 _presaleMintMaxSupply,
        uint256 _reservedSize,
        uint256 _maxItemsPerWallet,
        uint256 _maxItemsPerTx,
        bool _presaleMintPaused,
        bytes32 _eligibleMerkleRoot
                    ) external onlyOwner {
        
        presaleMintPrice = _presaleMintPrice;
        collectionSize = _collectionSize;
        presaleMintMaxSupply = _presaleMintMaxSupply;
        reservedSize = _reservedSize;
        maxItemsPerWallet = _maxItemsPerWallet;
        maxItemsPerTx = _maxItemsPerTx;
        presaleMintPaused = _presaleMintPaused;
        eligibleMerkleRoot = _eligibleMerkleRoot;
    }

    function setAuctionSaleConfig(
        uint256 _collectionSize,
        uint256 _reservedSize,
        uint256 _maxItemsPerWallet,
        uint256 _maxItemsPerTx,
        uint256 _auctionStartPrice,
        uint256 _auctionEndPrice,
        uint256 _auctionPriceCurveLength,
        uint256 _auctionDropInterval,
        uint256 _auctionSaleStartTime,
        uint256 _auctionSaleEndTime,
        uint256 _lastAuctionSupplyBurnTime
                    ) external onlyOwner {
        
        collectionSize = _collectionSize;
        reservedSize = _reservedSize;
        maxItemsPerWallet = _maxItemsPerWallet;
        maxItemsPerTx = _maxItemsPerTx;
        auctionStartPrice = _auctionStartPrice;
        auctionEndPrice = _auctionEndPrice;
        auctionPriceCurveLength = _auctionPriceCurveLength;
        auctionDropInterval = _auctionDropInterval;
        auctionSaleStartTime = _auctionSaleStartTime;
        auctionSaleEndTime = _auctionSaleEndTime;
        lastAuctionSupplyBurnTime = _lastAuctionSupplyBurnTime;

        auctionDropPerStep = (_auctionStartPrice - _auctionEndPrice)
                    / (_auctionPriceCurveLength / _auctionDropInterval);

    }

    function setPublicSaleConfig(
        uint256 _collectionSize,
        uint256 _reservedSize,
        uint256 _maxItemsPerWallet,
        uint256 _maxItemsPerTx,
        uint64 _publicMintPrice,
        bool _publicMintPaused
                    ) external onlyOwner {

        collectionSize = _collectionSize;
        reservedSize = _reservedSize;
        maxItemsPerWallet = _maxItemsPerWallet;
        maxItemsPerTx = _maxItemsPerTx;
        publicMintPrice = _publicMintPrice;
        publicMintPaused = _publicMintPaused;
    }

    function setMultiverseConfig(
        address _portalGunContract,
        uint256 _secondMultiverseDimensionSupply,
        uint256 _thirdMultiverseDimensionSupply,
        uint256 _fourthMultiverseDimensionSupply,
        uint256 _fifthMultiverseDimensionSupply,
        bool _secondMultiverseMintPaused,
        bool _thirdMultiverseMintPaused,
        bool _fourthMultiverseMintPaused,
        bool _fifthMultiverseMintPaused
                    ) external onlyOwner {
        
        portalGunContract = _portalGunContract;
        secondMultiverseDimensionSupply = _secondMultiverseDimensionSupply;
        thirdMultiverseDimensionSupply = _thirdMultiverseDimensionSupply;
        fourthMultiverseDimensionSupply = _fourthMultiverseDimensionSupply;
        fifthMultiverseDimensionSupply = _fifthMultiverseDimensionSupply;
        secondMultiverseMintPaused = _secondMultiverseMintPaused;
        thirdMultiverseMintPaused = _thirdMultiverseMintPaused;
        fourthMultiverseMintPaused = _fourthMultiverseMintPaused;
        fifthMultiverseMintPaused = _fifthMultiverseMintPaused;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // ================================================== //
    //             *** WITHDRAW TO OWNER *** 
    // ================================================== //
    function withdrawAll() external onlyOwner onlySender nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send ether");
    }

    // ================================================== //
    //                     *** UTILS *** 
    // ================================================== //

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    // ================================================== //
    //                *** VIEW METADATA *** 
    // ================================================== //
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
        }
        return _tokens;
    }
}
