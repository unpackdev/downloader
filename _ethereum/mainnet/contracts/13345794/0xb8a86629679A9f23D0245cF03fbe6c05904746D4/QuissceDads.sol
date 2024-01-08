pragma solidity ^0.8.5;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./QuissceQoin.sol";

contract QuissceDads is
    ERC721,
    ERC721Burnable,
    ERC721Enumerable,
    ERC721URIStorage
{
    QuissceQoin public quissceQoin;
    uint256 public dadCounter;
    struct Dad {
        uint256 id;
        string firstName;
        string lastName;
        string favoriteFood;
        string hobbies;
        uint256 dadScore;
        bool isBurned;
        uint256 salePrice;
    }

    Dad[] public dadDataArray;
    mapping(address => uint256) public claimableDadDollars;

    constructor(QuissceQoin _quissceQoin) ERC721("Quissce Dads", "QDAD") {
        quissceQoin = _quissceQoin;
        dadCounter = 0;
    }

    function getDadData() public view returns (Dad[] memory) {
        return dadDataArray;
    }

    function getDadScore(uint256 dadId, string memory dadFirstName)
        private
        view
        returns (uint256)
    {
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    dadId,
                    dadFirstName
                )
            )
        );
        return randomHash % 1000;
    }

    function getDadsOwnedByAddress() public view returns (Dad[] memory) {
        uint256 dadsOwnedByAddress = balanceOf(msg.sender);
        Dad[] memory dads = new Dad[](dadsOwnedByAddress);
        for (uint256 i = 0; i < dads.length; i++) {
            dads[i] = dadDataArray[tokenOfOwnerByIndex(msg.sender, i)];
        }
        return dads;
    }

    function createDad(
        string memory firstName,
        string memory lastName,
        string memory favoriteFood,
        string memory hobbies,
        string memory tokenURI
    ) public returns (uint256) {
        quissceQoin.transferFrom(msg.sender, address(this), 100_000e18);

        uint256 newDadId = dadCounter;
        Dad memory newDad = Dad(
            newDadId,
            firstName,
            lastName,
            favoriteFood,
            hobbies,
            getDadScore(newDadId, firstName),
            false,
            0
        );
        dadDataArray.push(newDad);

        _safeMint(msg.sender, newDadId);
        _setTokenURI(newDadId, tokenURI);

        for (uint256 i = 0; i < dadDataArray.length; i++) {
            if (!dadDataArray[i].isBurned) {
                address tokenOwner = ownerOf(i);
                claimableDadDollars[tokenOwner] += dadDataArray[i].dadScore;
            }
        }

        dadCounter++;
        return newDadId;
    }

    function updateSalePrice(uint256 dadId, uint256 amount) public {
        require(
            msg.sender == ownerOf(dadId),
            "only the dad owner can update the sale price"
        );
        dadDataArray[dadId].salePrice = amount;
    }

    function buyDadWithQuissceQoin(uint256 dadId) public {
        require(msg.sender != ownerOf(dadId), "already the owner of this dad");
        require(dadDataArray[dadId].salePrice != 0, "this dad is not for sale");
        require(getApproved(dadId) == address(this), "not approved");
        quissceQoin.transferFrom(
            msg.sender,
            ownerOf(dadId),
            dadDataArray[dadId].salePrice
        );
        _transfer(ownerOf(dadId), msg.sender, dadId);
        dadDataArray[dadId].salePrice = 0;
    }

    function burnDad(uint256 dadId) public {
        burn(dadId);

        for (uint256 i = 0; i < dadDataArray.length; i++) {
            if (dadDataArray[i].id == dadId) {
                dadDataArray[i].isBurned = true;
            }
        }

        quissceQoin.transfer(msg.sender, 50_000e18);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        return super._burn(tokenId);
    }
}
