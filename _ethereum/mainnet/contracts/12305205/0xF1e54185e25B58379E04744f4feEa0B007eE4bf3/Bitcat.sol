// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

/**
 * @title the Bitcat NFT smart contract
 */
contract Bitcat is ERC721, Ownable {
    using SafeMath for uint256;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // @dev symbol,name ,and base ui
    string private constant SYMBOL = "BTC";
    string private constant NAME = "Bitcat";
    string private constant BASE_URI = "https://ipfs.io/ipfs/";
    // @dev eth decimals
    uint256 private constant _ETH_DECIMALS = 1e18;
    // @dev users eth balances to reclaim
    mapping(address => uint256) private _balances;
    // @dev tokens placeholders
    mapping(uint256 => string) private _placeholderURIs;
    // @dev Cuddlers are all previous holders, cuddler only done using resell not transfer
    mapping(uint256 => EnumerableMap.UintToAddressMap) private _catCuddlers;

    // @notice We can't add more than 2K cats
    uint256 public constant MAX_CATS_SUPPLY = 2000;
    // @notice The next cat id for sale
    uint256 public nextCatId = 1;
    // @notice cat price by id
    mapping(uint256 => uint256) public catPrice;
    // @notice is cat for sale
    mapping(uint256 => bool) public isCatForSale;

    // @dev Emitted when `catId` is sold to `_msgSender()`.
    event Buy(uint256 indexed catId, address indexed to);
    // @dev Emitted when `catId` is open for resell.
    event Resell(uint256 indexed catId);
    // @dev Emitted when `catId` resell is canceled.
    event CancelResell(uint256 indexed catId);
    // @dev Emitted when `to` reclaim his balance.
    event Reclaim(address indexed to);

    // @dev We shouldn't be able to change anything of these on deployment
    constructor() ERC721(NAME, SYMBOL) {
        _setBaseURI(BASE_URI);
    }

    /**
     * @dev Set the token place holder uri
     */
    function _setPlaceholderURI(uint256 tokenId, string memory _placeholderURI) internal virtual {
        require(_exists(tokenId), "Bitcat: placeholder URI set of nonexistent token");
        _placeholderURIs[tokenId] = _placeholderURI;
    }

    /**
     * @notice Create a new cat
     */
    function mintCat(string memory tokenURI, string memory placeholderURI) public onlyOwner {
        address creator = _msgSender();
        uint256 newCatId = totalSupply().add(1);
        // check
        require(newCatId < MAX_CATS_SUPPLY, "Bitcat: exceeds Max Supply.");
        require(bytes(tokenURI).length > 0, "Bitcat: tokenURI is required.");
        require(bytes(placeholderURI).length > 0, "Bitcat: placeholderURI is required.");
        // mint
        _mint(creator, newCatId);
        // set uri
        _setTokenURI(newCatId, tokenURI);
        _setPlaceholderURI(newCatId, placeholderURI);
        // set the cat price
        catPrice[newCatId] = calculateMinCatPrice(newCatId);
        // set as available for sale
        isCatForSale[newCatId] = true;
    }

    /**
     * @dev Calculate the cat minimal price based on index and number of cuddlers
     */
    function calculateMinCatPrice(uint256 catId) public view returns (uint256) {
        // initial price from (0.1 ETH) to (200 ETH)
        uint256 initialCatPrice = catId.mul(_ETH_DECIMALS).div(10);
        // price increase %0.1 for every cuddler
        return initialCatPrice.mul((totalCatCuddlers(catId).div(10)).add(1));
    }

    /**
     * @notice get a cat caddler by catId and caddler index
     */
    function catCuddlers(uint256 catId, uint256 index) public view returns (address) {
        return _catCuddlers[catId].get(index);
    }

    /**
     * @notice get the cat total cuddlers by cat id
     */
    function totalCatCuddlers(uint256 catId) public view returns (uint256) {
        return _catCuddlers[catId].length();
    }

    /**
     * @notice Check if the reselling feature is open (reselling will be available when all cats are sold out)
     */
    function isResellingOpen() public view returns (bool) {
        return nextCatId.add(1) >= MAX_CATS_SUPPLY;
    }

    /**
     * @notice Cat owner can resell the cat and become a cuddler
     **/
    function resellCat(uint256 catId, uint256 newPrice) public {
        address seller = _msgSender();
        // check if owner
        require(seller == ownerOf(catId), "Bitcat: you need to be the cat owner to resell it.");
        // check minimal price
        require(
            newPrice >= calculateMinCatPrice(catId),
            "Bitcat: the new price should be larger than minimal price."
        );
        catPrice[catId] = newPrice;
        isCatForSale[catId] = true;
        emit Resell(catId);
    }

    /**
     * @notice Cat owner can cancel reselling the cat
     **/
    function cancelResellCat(uint256 catId) public {
        address seller = _msgSender();
        // check if owner
        require(
            seller == ownerOf(catId),
            "Bitcat: you need to be the cat owner to cancel the resell."
        );
        // check minimal price
        isCatForSale[catId] = false;
        // emit event
        emit CancelResell(catId);
    }

    /**
     * @notice Check if cat is unlocked
     **/
    function isCatUnlocked(uint256 catId) public view returns (bool) {
        return catId <= nextCatId;
    }

    /**
     * @notice Check if cat is minted
     **/
    function isCatMinted(uint256 catId) public view returns (bool) {
        return _exists(catId);
    }

    /**
     * @notice Cat token uri, cat need to be unlocked
     **/
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return isCatUnlocked(tokenId) ? super.tokenURI(tokenId) : "";
    }

    /**
     * @notice Cat token placeholder uri
     **/
    function placeholderURI(uint256 tokenId) public view returns (string memory) {
        string memory _placeholderURI = _placeholderURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _placeholderURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_placeholderURI).length > 0) {
            return string(abi.encodePacked(base, _placeholderURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
     * @notice buy cat, also make sure it's available for sale
     */
    function buyCat(uint256 catId) public payable {
        address buyer = _msgSender();
        address seller = ownerOf(catId);
        uint256 price = catPrice[catId];
        bool isForSale = isCatForSale[catId];
        bool isResellingEnabled = isResellingOpen();
        bool isUnlocked = isCatUnlocked(catId);

        // check
        require(buyer != address(0), "Bitcat: invalid address.");
        require(buyer != seller, "Bitcat: already an owner!");
        require(isForSale, "Bitcat: this cat is not for sale yet.");
        require(price == msg.value, "Bitcat: the cat Eth value sent is invalid.");
        require(isUnlocked, "Bitcat: this cat is locked and not open for sale yet.");

        EnumerableMap.UintToAddressMap storage cuddlers = _catCuddlers[catId];
        uint256 totalCuddlers = cuddlers.length();
        if (totalCuddlers > 0) {
            // cuddlers will receive 0.1 in total and owner will receive the rest 0.9
            uint256 cuddlersVal = price.div(10);
            uint256 sellerVal = price.sub(cuddlersVal);

            // add to the seller balance his money
            _balances[seller] = _balances[seller].add(sellerVal);

            // set to the cuddlers their money
            uint256 cuddlerVal = cuddlersVal.div(totalCuddlers);
            for (uint256 i = 0; i < totalCuddlers; i++) {
                address cuddler = cuddlers.get(i);
                _balances[cuddler] = _balances[cuddler].add(cuddlerVal);
            }
        } else {
            // add to the seller balance his money
            _balances[seller] = _balances[seller].add(price);
        }

        // seller become a cuddler :)
        _catCuddlers[catId].set(totalCuddlers, seller);

        // do transfer
        _transfer(seller, buyer, catId);

        // remove the cat from reselling
        isCatForSale[catId] = false;

        // if all cats still not sold out increase the nextCatId counter
        if (!isResellingEnabled) {
            nextCatId = nextCatId.add(1);
        }

        // emit event
        emit Buy(catId, buyer);
    }

    /**
     * @dev eth balance can be reclaimed
     */
    function balanceToReclaimOf(address user) public view returns (uint256) {
        require(user != address(0), "Bitcat: balance query for the zero address");
        return _balances[user];
    }

    /**
     * @dev reclaim and withdraw ether from this contract
     */
    function reclaim() public {
        address payable seller = _msgSender();
        require(seller != address(0), "Bitcat: invalid zero address.");

        uint256 balance = _balances[seller];
        require(balance > 0, "Bitcat: your balance is 0.");
        seller.transfer(balance);

        // clear balance
        _balances[seller] = 0;

        // emit event
        emit Reclaim(seller);
    }
}
