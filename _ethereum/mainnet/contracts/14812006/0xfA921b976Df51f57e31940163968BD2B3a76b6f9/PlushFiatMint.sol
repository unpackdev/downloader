//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./AccessControlEnumerable.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./IPlush.sol";

/**
 * @dev This contracts manages the fiat payment part of Plush. Tokens are first reserved and then claimed to be transferred to their owners.
 */
contract PlushFiatMint is AccessControlEnumerable, IERC721Receiver, Pausable {
    //The Plush NFT contract
    IPlush immutable Plush;

    //Admin role, manages other roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    //Reserver role. Is allowed to reserve tokens (mint them) for a future claim.
    bytes32 public constant RESERVER_ROLE = keccak256("RESERVER_ROLE");
    //Claimer role. Is allowed to claim tokens (transfer them) on behalf of the end user.
    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");

    error NotAllowed();
    error MaxSupplyReached();
    error DifferentLength();
    error SupplyNotInRange();
    error ReserveInsufficient();

    //Helps keep track of which token were minted and are available
    struct ReservedMint {
        uint128 nextTokenId; //Next tokenID available
        uint128 endTokenId; //Upper bound of token ID available
    }

    //Every reserved mint. Not using an array because it is too expensive.
    mapping(uint256 => ReservedMint) public reservedMints;

    //Next index for a ReservedMint structure in the mapping
    uint256 public nextReservedIndex;

    //Next ReservedIndex which is not empty (which has not been claimed totally);
    uint256 public emptyReservedIndex;

    //Max supply dedicated to the fiat payments. Can be adjusted
    uint256 public maxSupply = 30000;

    //Keeps track of the number of NFTs minted on this contract
    uint256 public minted;

    //Keeps track of the number of NFTs claimed on this contract
    uint256 public claimed;

    constructor(address _plush) {
        Plush = IPlush(_plush);
        _setRoleAdmin(RESERVER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(CLAIMER_ROLE, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    modifier onlyReserver() {
        if (!hasRole(RESERVER_ROLE, msg.sender)) revert NotAllowed();
        _;
    }

    modifier onlyClaimer() {
        if (!hasRole(CLAIMER_ROLE, msg.sender)) revert NotAllowed();
        _;
    }

    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert NotAllowed();
        _;
    }

    //Needed to perform safeTransfer
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return bytes4(this.onERC721Received.selector);
    }

    //Emergency pause only callable by an admin
    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    //Adjust max supply. Is adjusted according to total supply and FiatMint supply
    function setMaxSupply(uint256 _supply) external onlyReserver {
        if (_supply < minted) revert SupplyNotInRange();
        maxSupply = _supply;
    }

    /**
     * @dev Reserve some tokens and store the reserved Ids in a ReservedMint structure for future claims. Reserved mint are actually minted on the Plush Contract
     * @param quantity The quantity to reserve.
     */
    function reserveMint(uint256 quantity) external whenNotPaused onlyReserver {
        //Check that max supply has not been reached.
        if (quantity + minted > maxSupply) revert MaxSupplyReached();

        //Get the starting tokenId that will be minted -> current total supply because mint is sequential
        uint256 startIndex = Plush.totalSupply();

        //Set a new Reserved index structure with start and end index
        reservedMints[nextReservedIndex] = ReservedMint(
            uint128(startIndex),
            uint128(startIndex + quantity)
        );

        //Increment the next free index
        nextReservedIndex++;

        //Increment the quantity minted
        minted += quantity;

        //Mint the NFTs on the contract
        Plush.mintTo(address(this), quantity);
    }

    /**
     * @dev Performs a single claim for a single address
     * @param quantity see _claim quantity
     * @param to see _claim to
     */
    function claimMint(uint256 quantity, address to)
        public
        whenNotPaused
        onlyClaimer
    {
        if(quantity + claimed > minted) revert ReserveInsufficient();
        
        claimed += quantity;

        _claim(quantity, to);
    }

    /**
     * @dev Performs a batched claim for a multiple addresses
     * @param quantities array of quantities
     * @param to array of addresses
     * @dev Both arrays must have the same length
     */
    function claimMintBatch(
        uint256[] calldata quantities,
        address[] calldata to
    ) public whenNotPaused onlyClaimer {
        if (quantities.length != to.length) revert DifferentLength();

        uint256 totalReserved = 0;

        for (uint256 i = 0; i < quantities.length; i++) {
            totalReserved += quantities[i];
        }

        if (totalReserved + claimed > minted) revert ReserveInsufficient();

        claimed += totalReserved;

        for (uint256 i = 0; i < quantities.length; i++) {
            _claim(quantities[i], to[i]);
        }
    }

    /**
     * @dev Performs a claim on behalf of a user
     * @param quantity the quantity to transfer
     * @param to the address to transfer the tokens to
     */
    function _claim(uint256 quantity, address to) internal {
        //Number of tokens left to transfer
        uint256 leftToMint = quantity;

        while (leftToMint > 0) {
            //Current reserved mint that is not empty
            ReservedMint memory currentReserve = reservedMints[
                emptyReservedIndex
            ];

            //Number of tokens available in this ReservedMint
            uint128 available = currentReserve.endTokenId -
                currentReserve.nextTokenId;
            //Id of the first tokenId that will be transferred from this ReservedMint
            uint256 startTransferIndex = currentReserve.nextTokenId;
            //Amount that will be transferred from this ReservedMint
            uint256 amount;

            //If we can transfer all the tokens from this ReservedMint
            if (available >= leftToMint) {
                amount = leftToMint;

                //We set the current reserve nextTokenId available
                currentReserve.nextTokenId += uint128(leftToMint);

                //If the current reserve is empty (nextTokenId is the same as endTokenId) we discard it by incrementing the empty index
                if (currentReserve.nextTokenId == currentReserve.endTokenId) {
                    emptyReservedIndex++;
                } else {
                    //Commit the update of nextTokenId to storage
                    reservedMints[emptyReservedIndex]
                        .nextTokenId = currentReserve.nextTokenId;
                }
            } else {
                //If not enough is available in this ReservedMint we mint everything we can an then discard it
                amount = available;
                emptyReservedIndex++;
            }

            leftToMint -= amount;

            //Transfer all the selected ids of this ReservedMint. They are sequential inside a single struct
            for (uint256 i = 0; i < amount; i++) {
                Plush.safeTransferFrom(
                    address(this),
                    to,
                    startTransferIndex + i
                );
            }
        }
    }
}
