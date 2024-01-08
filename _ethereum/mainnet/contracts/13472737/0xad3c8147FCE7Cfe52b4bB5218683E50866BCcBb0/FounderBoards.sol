// SPDX-License-Identifier: MIT
//
//    _____ __   ____ _    __
//   / ___// /__( __ ) |  / /__  _____________
//   \__ \/ //_/ __  | | / / _ \/ ___/ ___/ _ \
//  ___/ / ,< / /_/ /| |/ /  __/ /  (__  )  __/
// /____/_/|_|\____/ |___/\___/_/  /____/\___/
//
//

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC2981Base.sol";

contract FounderBoards is
    ERC2981Base,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable
{
    using SafeMath for uint256;
    uint256 public constant price = 0.04 ether;
    uint256 constant reserved = 280; // Reserved for promotions via ownerMint()
    address withdrawTo;
    string public baseURI;
    bool public frozen;
    uint256 ownerWithdrawn;
    uint16[] boards;

    mapping(address => uint256) public claimedPerWallet;

    bool public presaleIsActive = true;
    uint256 whitelistContractCount;
    mapping(uint256 => address) whitelistContracts;

    constructor(string memory ipfs) ERC721("Sk8Founder", "FND") {
        withdrawTo = msg.sender;
        baseURI = ipfs;
        for (uint16 i = 1; i <= 8888; i++) {
            boards.push(i);
        }
    }

    function mintTo(address wallet, uint256 numberOfTokens) public payable {
        require(numberOfTokens > 0, "You want zero boards?");
        require(numberOfTokens < 9, "Max 8 tokens per wallet");
        require(msg.value >= price.mul(numberOfTokens), "Insufficient funds");
        require(
            numberOfTokens <= boards.length - reserved,
            "More than we have left"
        );
        require(
            (claimedPerWallet[wallet] + numberOfTokens) <= 8,
            "Max 8 tokens per wallet"
        );
        if (presaleIsActive) {
            require(isWhitelisted(wallet), "Not whitelisted");
        }

        for (uint16 i = 0; i < numberOfTokens; i++) {
            uint256 randBoard = getRandom(boards);
            _safeMint(wallet, randBoard);
        }
        claimedPerWallet[wallet] += numberOfTokens;
    }

    function mint(uint256 numberOfTokens) public payable {
        mintTo(msg.sender, numberOfTokens);
    }

    function ownerMint(uint256 quantity) public onlyOwner {
        uint256 left = reserved - ownerWithdrawn;
        require(left > 0, "Already withdrawn");
        require(quantity <= left, "More than allowed");
        for (uint16 i = 0; i < quantity; i++) {
            uint256 randBoard = getRandom(boards);
            _safeMint(withdrawTo, randBoard);
            ownerWithdrawn++;
        }
    }

    function tokensByOwner(address _owner)
        public
        view
        returns (uint16[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint16[](0);
        } else {
            uint16[] memory result = new uint16[](tokenCount);
            uint16 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = uint16(tokenOfOwnerByIndex(_owner, index));
            }
            return result;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        require(!frozen, "Contract is no longer editable");
        baseURI = uri;
    }

    function withdraw(uint256 amount) public onlyOwner {
        payable(withdrawTo).call{value: amount}("");
    }

    function setWithdrawalAddress(address to) public onlyOwner {
        withdrawTo = to;
    }

    function freeze() public onlyOwner {
        frozen = true;
    }

    function burn(uint256 tokenId) public override {
        _burn(tokenId);
    }

    //
    // Colors
    //
    //  0 Plain
    //  1 White
    //  2 Black
    //  3 Red
    //  4 Orange
    //  5 Yellow
    //  6 Green
    //  7 Blue
    //  8 Indigo
    //  9 Violet
    // 10 Bronze
    // 11 Silver
    // 12 Gold
    //
    function getColor(uint256 boardId) public pure returns (uint256) {
        // Gold
        if (boardId <= 8) return 12;
        // Silver
        else if (boardId <= 96) return 11;
        // Bronze
        else if (boardId <= 984) return 10;
        // Wood
        else return boardId % 10;
    }

    function ownsColor(address wallet, uint256 color)
        public
        view
        returns (bool)
    {
        uint16[] memory tokens = tokensByOwner(wallet);
        uint256 tokenCount = balanceOf(wallet);
        uint16 index;
        for (index = 0; index < tokenCount; index++) {
            uint256 tokenRarity = getColor(tokens[index]);
            if (tokenRarity == color) return true;
        }
        return false;
    }

    //
    // Thanks Manny
    //
    function getRandom(uint16[] storage _arr) private returns (uint256) {
        uint256 random = _getRandomNumber(_arr);
        uint256 tokenId = uint256(_arr[random]);

        _arr[random] = _arr[_arr.length - 1];
        _arr.pop();

        return tokenId;
    }

    function _getRandomNumber(uint16[] storage _arr)
        private
        view
        returns (uint256)
    {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    _arr.length,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender
                )
            )
        );

        return random % _arr.length;
    }

    //
    // Presale
    // False is public sale
    //
    function setPresale(bool isActive) public onlyOwner {
        presaleIsActive = isActive;
    }

    function isWhitelisted(address walletAddress) public view returns (bool) {
        uint16 i;
        for (i = 0; i < whitelistContractCount; i++) {
            if (IERC721(whitelistContracts[i]).balanceOf(walletAddress) >= 1) {
                return true;
            }
        }
        return false;
    }

    function addWhitelist(address contractAddress) public onlyOwner {
        whitelistContracts[whitelistContractCount] = contractAddress;
        whitelistContractCount += 1;
    }

    //
    // Royalties
    //
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (withdrawTo, (value * 400) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
