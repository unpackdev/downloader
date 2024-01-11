//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./AccessControlEnumerable.sol";
import "./Pausable.sol";
import "./IPlush.sol";

/**
 * @dev This contract is used to perform the sale of Plush NFT. You can enter the Plushlist and gain access to the presale
 */
contract PlushMint is AccessControlEnumerable, PaymentSplitter, Pausable {
    // The Plush NFT contract itself
    IPlush immutable Plush;

    // The maximum number of tokens mintable with the presale
    uint256 public constant maxMintablePresale = 3;
    //The maximum number of tokens mintable at once during the public sale
    uint256 public constant maxMintablePerTx = 10;
    //Both the sale and presale will start at the same time
    uint256 public immutable saleStart;
    uint256 public immutable presaleStart;
    //The initial price for the presale. Will be adjusted to match the price in euros
    uint256 public immutable initialPresalePrice;
    //The initial price for the sale. Will be adjusted to match the price in euros
    uint256 public immutable initialSalePrice;

    //Admin of other roles, is allowed to end sale
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    //Performs tasks on sale parameters (merkle root, price)
    bytes32 public constant SALE_ADMIN_ROLE = keccak256("SALE_ADMIN_ROLE");
    //Is allowed to pause and unpause sale
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    error NotAllowed();
    error AmountZero();
    error MintTooLarge();
    error NotWhitelisted();
    error PresaleNotStarted();
    error PresaleEnded();
    error MaxPresaleAmountReached();
    error MaxSupplyReached();
    error InsufficientFunds();
    error SaleNotStarted();
    error SaleEnded();
    error PriceNotInRange();
    error EndDateNotInRange();
    error StartNotInRange();
    error SupplyNotInRange();

    //Max supply dedicated to this mint out of 50,000. The other supply is dedicated to payment with fiat. See PlushFiatMint for more details.
    uint256 public maxSupply = 20000;
    //Actual sale price
    uint256 public price; //To be defined
    //Actual presale price
    uint256 public presalePrice; //To be defined

    //The merkle root used to confirm a user access to the presale
    bytes32 public presaleMerkleRoot;

    //Indicate if the sale has been ended. Can be switched of only once manually.
    bool public saleEnded;

    //Number of tokens minted with this contract.
    uint256 public minted;

    //Numbers of tokens minted by each address during the presale. Used to disallow more than 3 mints
    mapping(address => uint256) public tokensMinted;

    constructor(
        IPlush _plush,
        address[] memory _team,
        uint256[] memory _teamShares,
        uint256 _saleStart,
        uint256 _presaleStart,
        uint256 _initialPresalePrice,
        uint256 _initialSalePrice
    ) PaymentSplitter(_team, _teamShares) {
        if (_initialSalePrice == 0) revert PriceNotInRange();
        if (_initialPresalePrice == 0) revert PriceNotInRange();

        if (_saleStart == 0) revert StartNotInRange();
        if (_presaleStart == 0) revert StartNotInRange();

        Plush = _plush;
        saleStart = _saleStart;
        presaleStart = _presaleStart;
        initialPresalePrice = _initialPresalePrice;
        initialSalePrice = _initialSalePrice;

        price = _initialSalePrice;
        presalePrice = _initialPresalePrice;

        _setRoleAdmin(SALE_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert NotAllowed();
        _;
    }

    modifier onlySaleAdmin() {
        if (!hasRole(SALE_ADMIN_ROLE, msg.sender)) revert NotAllowed();
        _;
    }

    modifier onlyPauser() {
        if (!hasRole(PAUSER_ROLE, msg.sender)) revert NotAllowed();
        _;
    }

    //Set the presale merkle root. Can be updated if late participants send their address.
    function setPresaleMerkleRoot(bytes32 _presaleRoot) external onlySaleAdmin {
        presaleMerkleRoot = _presaleRoot;
    }

    //Set the max supply dedicated to this contract. Can not mint over 50,000 due to limitations in Plush. Can be adjusted in parallel with PlushFiatMint max supply.
    function setMaxSupply(uint256 _supply) external onlySaleAdmin {
        if (_supply < minted) revert SupplyNotInRange();
        maxSupply = _supply;
    }

    //Set the sale price. It can not vary for more than 50% of the initial price.
    function setPrice(uint256 _newPrice) public onlySaleAdmin {
        if (_newPrice > initialSalePrice + initialSalePrice / 2)
            revert PriceNotInRange();
        if (_newPrice < initialSalePrice / 2) revert PriceNotInRange();
        price = _newPrice;
    }

    //Set the presale price. It can not vary for more than 50% of the initial price.
    function setPresalePrice(uint256 _newPrice) public onlySaleAdmin {
        if (_newPrice > initialPresalePrice + initialPresalePrice / 2)
            revert PriceNotInRange();
        if (_newPrice < initialPresalePrice / 2) revert PriceNotInRange();
        presalePrice = _newPrice;
    }

    //Close the sale
    function endSale() public onlyAdmin {
        saleEnded = true;
    }

    //Pause the contract in case of an emergency
    function pause() external onlyPauser {
        _pause();
    }

    //Unpause the contract
    function unpause() external onlyPauser {
        _unpause();
    }

    /**
     * @dev Perform a presale mint using a MerkleTree construction to verify that an address belongs to the Plush list
     * @param amount The amount of tokens the user wants to mint. Total tokens minted must be <= 3 or else the function reverts
     * @param merkleProof The merkle proof for msg.sender address
     */
    function presaleMint(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
        whenNotPaused
    {
        //Check if sale is ended
        if (saleEnded) revert PresaleEnded();

        //Check if presale is started
        if (block.timestamp < presaleStart) revert PresaleNotStarted();

        // Check that max supply is not reached
        if (minted + amount > maxSupply) revert MaxSupplyReached();

        //Verify membership to plushlist
        if (
            !MerkleProof.verify(
                merkleProof,
                presaleMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert NotWhitelisted();

        //Check that the address does not mint more than allowed
        if (tokensMinted[msg.sender] + amount > maxMintablePresale)
            revert MaxPresaleAmountReached();

        if (amount == 0) revert AmountZero();

        // Check that the sufficient funds have been sent
        if (msg.value < presalePrice * amount) revert InsufficientFunds();

        //Increments tokens minted for this address
        tokensMinted[msg.sender] += amount;

        //Increments number of tokens minted
        minted += amount;

        //Mint to the address
        Plush.mintTo(msg.sender, amount);

        //Send back any excess amount
        if (msg.value > presalePrice * amount) {
            payable(msg.sender).transfer(msg.value - presalePrice * amount);
        }
    }

    /**
     * @dev Performs a public sale
     * @param amount The amount of tokens to purchase. Must be < 10 or the function reverts
     */
    function publicSaleMint(uint256 amount) external payable whenNotPaused {
        //Check that sale is not ended
        if (saleEnded) revert SaleEnded();
        //Check is sale is started
        if (block.timestamp < saleStart) revert SaleNotStarted();

        //Checks to the amount is correct
        if (amount > maxMintablePerTx) revert MintTooLarge();

        //Check if max supply has been reached
        if (minted + amount > maxSupply) revert MaxSupplyReached();

        if (amount == 0) revert AmountZero();

        //Check that a sufficient amount has been sent
        if (msg.value < price * amount) revert InsufficientFunds();

        //Increments counter of tokens minted
        minted += amount;

        //Mint the tokens
        Plush.mintTo(msg.sender, amount);

        //Send back any excess amount
        if (msg.value > price * amount) {
            payable(msg.sender).transfer(msg.value - price * amount);
        }
    }
}
