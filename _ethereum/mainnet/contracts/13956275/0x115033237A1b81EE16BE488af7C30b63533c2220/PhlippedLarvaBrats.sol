// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract PhlippedLarvaBrats is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string public baseURI;
    string public baseExtension = ".json";
    uint16 public counter = 0;

    uint16 public giveaway = 500;
    uint16 public maxSupply = 5000;
    uint8 public constant maxPublicPurchase = 20;
    uint8 public constant maxWalletBalance = 20;

    uint256 public constant price = 20000000000000000;

    bool public publicSale = true;
    bool public giveAwayOn = true;

    mapping(address => uint256) addressBlockBought;

    constructor(string memory tokenBaseUri)
        ERC721("Phlipped Larva Brats", "BRATS")
    {
        counter = counter + 1;

        setBaseURI(tokenBaseUri);
    }

    function mint(uint8 numberOfTokens) public payable {
        uint256 supply = totalSupply();
        require(publicSale, "Public mint is not live right now.");
        require(
            addressBlockBought[msg.sender] < block.timestamp,
            "Not allowed to Mint on the same Block"
        );
        require(
            !Address.isContract(msg.sender),
            "Contracts are not allowed to mint"
        );
        require(
            numberOfTokens <= maxPublicPurchase,
            "You can mint a maximum of 20 Larva Brats"
        );
        require(
            supply + numberOfTokens <= maxSupply,
            "Exceeds maximum Brats supply"
        );
        require(
            balanceOf(msg.sender) + numberOfTokens <= maxWalletBalance,
            "Each wallet can only mint 20 Larva Brats"
        );
        require(
            price.mul(numberOfTokens) <= msg.value,
            "Ether value sent is incorrect"
        );

        addressBlockBought[msg.sender] = block.timestamp;

        for (uint8 i; i < numberOfTokens; i++) {
            _safeMint(msg.sender, counter);
            counter = counter + 1;
        }
    }

    function mintGiveAway(uint8 numberOfTokens) public {
        require(giveAwayOn, "Give away has not started");
        require(giveaway > 0, "All giveaways have been minted");
        require(
            giveaway - numberOfTokens >= 0,
            "Exceeds maximum Brats giveaway"
        );
        require(
            !Address.isContract(msg.sender),
            "Contracts are not allowed to mint"
        );
        require(
            addressBlockBought[msg.sender] < block.timestamp,
            "Not allowed to Mint on the same Block"
        );
        require(
            numberOfTokens <= maxPublicPurchase,
            "You can mint a maximum of 20 Larva Brats"
        );
        require(
            balanceOf(msg.sender) + numberOfTokens <= maxWalletBalance,
            "Each wallet can only mint 20 Larva Brats"
        );

        for (uint8 i; i < numberOfTokens; i++) {
            _safeMint(msg.sender, counter);
            counter = counter + 1;
            giveaway -= 1;
        }
    }

    function toggleSale() public onlyOwner {
        publicSale = !publicSale;
    }

    function toggleGiveAway() public onlyOwner {
        giveAwayOn = !giveAwayOn;
    }

    function turnOnSaleGiveAway() public onlyOwner {
        publicSale = true;
        giveAwayOn = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory tokenIdString = uint2str(tokenId);
        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenIdString,
                        baseExtension
                    )
                )
                : "";
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to withdraw payment");
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
