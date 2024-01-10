// SPDX-License-Identifier: MIT
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

pragma solidity ^0.8.7;
pragma abicoder v2;

contract TavernNFT is ERC721, Ownable, ERC721Enumerable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant tokenPublicPrice = 400000000000000000; // 0.4 ETH
    uint256 public constant tokenPreSalePrice = 250000000000000000; // 0.25 ETH
    uint256 public constant MAX_TOKENS = 1200;
    uint256 public maxMint = 2;
    uint256 public devReserve = 100;

    string public baseURI = ""; // IPFS URI WILL BE SET AFTER ALL TOKENS SOLD OUT

    bool public saleIsActive = false; // when launch sale then call to function
    bool public presaleIsActive = false;
    bool public isRevealed = false;

    uint256 private _countreserveTokens;

    mapping(address => bool) private _presaleList;
    mapping(address => uint256) private _presaleListClaimed;

    event Minted(uint256 tokenId, address owner);

    constructor() ERC721("Tavern", "TAVERN") {
        _safeMint(address(this), 1);
        _burn(1);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function reveal() public onlyOwner {
        isRevealed = !isRevealed;
    }

    // reverse token to dev with 100
    function reserveTokens(address _to, uint256 _reserveAmount)
        external
        onlyOwner
    {
        require(
            _reserveAmount > 0 &&
                _countreserveTokens.add(_reserveAmount) <= devReserve,
            "Not enough reserve left for team"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
            uint256 id = totalSupply().add(1);
            _safeMint(_to, id);
        }
        _countreserveTokens = _countreserveTokens.add(_reserveAmount);
    }

    function toggleSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function togglePresaleState() external onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function mint(uint256 numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint Token");
        require(
            numberOfTokens > 0 && numberOfTokens <= maxMint,
            "Can only mint one or more tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of tokens"
        );
        require(
            msg.value >= tokenPublicPrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );

        if (_presaleListClaimed[msg.sender] == 0) {
            require(
                balanceOf(msg.sender).add(numberOfTokens) <= maxMint,
                "You can mint max 2 NFTs"
            );

            for (uint256 i = 0; i < numberOfTokens; i++) {
                uint256 id = totalSupply().add(1);
                _safeMint(msg.sender, id);
                emit Minted(id, msg.sender);
            }
        }


        if(_presaleListClaimed[msg.sender] == 1){
             require(
                balanceOf(msg.sender).add(numberOfTokens) <= maxMint.add(1),
                "You can mint max 2 NFTs"
            );

            for (uint256 i = 0; i < numberOfTokens; i++) {
                uint256 id = totalSupply().add(1);
                _safeMint(msg.sender, id);
                emit Minted(id, msg.sender);
            }

        }

         if(_presaleListClaimed[msg.sender] == 2){
             require(
                balanceOf(msg.sender).add(numberOfTokens) <= maxMint.add(2),
                "You can mint max 2 NFTs"
            );

            for (uint256 i = 0; i < numberOfTokens; i++) {
                uint256 id = totalSupply().add(1);
                _safeMint(msg.sender, id);
                emit Minted(id, msg.sender);
            }

        }



    }

    function presaleTavern(uint256 numberOfTokens) external payable {
        require(presaleIsActive, "Presale is not active");
        require(_presaleList[msg.sender], "You are not on the Presale List");
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of presale event"
        );
        require(
            numberOfTokens > 0 && numberOfTokens <= maxMint,
            "Cannot purchase this many tokens"
        );
        require(
            _presaleListClaimed[msg.sender].add(numberOfTokens) <= maxMint,
            "Purchase exceeds max allowed"
        );
        require(
            msg.value >= tokenPreSalePrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );
        require(
            balanceOf(msg.sender).add(numberOfTokens) <= maxMint,
            "You can mint max 2 NFTs"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 id = totalSupply().add(1);
            _presaleListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, id);
            emit Minted(id, msg.sender);
        }
    }

    function addToPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _presaleList[addresses[i]] = true;
        }
    }

    function removeFromPresaleList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _presaleList[addresses[i]] = false;
        }
    }

    function onPreSaleList(address addr) external view returns (bool) {
        return _presaleList[addr];
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

        if (isRevealed == false) {
            return _baseURI();
        }

        return
            bytes(_baseURI()).length > 0
                ? string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), ".json")
                )
                : "";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
