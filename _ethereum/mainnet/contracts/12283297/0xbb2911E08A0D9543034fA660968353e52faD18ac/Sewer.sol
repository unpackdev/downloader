// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";

interface IMillionDollarRat {
    function ratTokenURI() external view returns (string memory);
}

contract Sewer is ERC721, IERC721Receiver, Ownable, ReentrancyGuard {
    address private _ratRaceOperator;

    uint256 public lastPrice;
    uint256 public blockLastSold;

    //Depreciate Golden Rat price slightly more than 1 Ether every day
    uint256 private constant DEPRECIATION_PER_BLOCK = 1 ether / 5000;
    uint256 private constant LOWER_PRICE_BOUNDARY = 1 ether;

    constructor() ERC721("Golden Rat Sewer", "MDRS") {}

    fallback() external payable {}

    receive() external payable {}

    /*
     * @dev Call this after deploying MillionDollarRat.
     *  Sewer is deployed first. The address of the MillionDollarRat
     *  instance MUST be set to avoid the attack where a different
     *  ERC721 deposits the 0th token into Sewer.
     */
    function setMDROperator(address millionDollarRatAddress) public onlyOwner {
        require(_ratRaceOperator == address(0), "Operator already set");
        require(
            millionDollarRatAddress != address(0),
            "Operator not specified"
        );

        _ratRaceOperator = millionDollarRatAddress;
    }

    /*
     * @dev The Golden Rat owner must send it to this contract
     *  to be able to withdraw the prize fund through {withdrawAll}.
     *  This is done by calling {MillionDollarRat.depositGoldenRatToSewer},
     *  triggering ERC721.safeTransferFrom, which requires Sewer to 
     *  implement IERC721Receiver.
     *
     *  Sewer will only accept the deposit if:
     *  - The operator (the address of the MillionDollarRat instance) is set
          by calling {setMDROperator}
     *  - The sender is be the exact same MillionDollarRat instance
     *  - `tokenId` is 0 (the Golden Rat token id)
     *  - Golden Rat has not been deposited before.
     *
     *  The depositGoldenRatToSewer/onERC721Received burns Golden Rat
     *  on MillionDollarRat and mints it on Sewer. From this point
     *  forward, Sewer is reponsible for managing Golden Rat.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        require(_ratRaceOperator != address(0), "Operator not set");
        require(msg.sender == _ratRaceOperator, "Not a Rat token");
        require(tokenId == 0, "Not the Golden Rat");
        require(!_exists(0), "Duplicate deposit detected");

        _mint(from, 0);

        return IERC721Receiver.onERC721Received.selector;
    }

    /*
     * @dev Current Golden Rat owner (according to Sewer)
     *  can call this to redeem it for the current Sewer balance.
     *
     *  Sewer becomes the owner when this happens. It updates
     *  Block Last Sold and Last Price to be able to adjust the
     *  price in Dutch auction fashion for when someone comes
     *  to buy the Golden Rat later.
     */
    function withdrawAll() public nonReentrant {
        require(msg.sender == ERC721.ownerOf(0), "Not the Golden Rat owner");
        // this is pure conjecture... should not ever happen
        require(address(this).balance > 0, "Nothing to withdraw");

        blockLastSold = block.number;

        lastPrice = address(this).balance;

        _transfer(msg.sender, address(this), 0);

        //payable(msg.sender).transfer(address(this).balance);
        (bool sent, ) =
            payable(msg.sender).call{value: address(this).balance}("");

        require(sent && (address(this).balance == 0), "ETH Transfer Failed");
    }

    /*
     * @dev Anyone can buy the Golden Rat if it's in the Sewer.
     *  The price is adjusted by DEPRECIATION_PER_BLOCK every
     *  block. But it never goes lower than LOWER_PRICE_BOUNDARY.
     */
    function buyGoldenRat() public payable {
        require(ERC721.ownerOf(0) == address(this), "Golden Rat not on sale");

        uint256 depreciation =
            DEPRECIATION_PER_BLOCK * (block.number - blockLastSold);

        uint256 currentPrice =
            ((depreciation + LOWER_PRICE_BOUNDARY) >= lastPrice)
                ? LOWER_PRICE_BOUNDARY
                : (lastPrice - depreciation);

        require(msg.value >= currentPrice, "Price too low");

        blockLastSold = block.number;

        lastPrice = msg.value;

        _transfer(address(this), msg.sender, 0);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Unknown tokenId");

        return IMillionDollarRat(_ratRaceOperator).ratTokenURI();
    }
}