//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Strings.sol";
import "./Authorizable.sol";

contract YieldingNFTV1 is ERC721, Authorizable {
    using Strings for uint256;

    uint64 public mintPrice;
    uint public supply;
    uint32 public maxSupply;

    string public baseURI;
    bool public selling;

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        string memory _baseURI,
        uint64 _mintPrice,
        uint32 _maxSupply
    ) ERC721(_name, _symbol) {
        setOwner(_owner);
        baseURI = _baseURI;
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId-1 < supply, "Not minted yet");
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "?id=", tokenId.toString()))
                : "";
    }

    function updateBaseURI(string calldata _baseURI) public onlyOwner{
        baseURI = _baseURI;
    }

    function toggleSale() public onlyOwner{
        selling = !selling;
    }

    function mintReserve(address to, uint amount) public onlyOwner{
        for (; amount > 0; amount -= 1) {
            supply++;
            _mint(to, supply);
        }

        require(supply <= maxSupply, "Sold out");
    }

    function mint() public payable {
        require(msg.value != 0, "Not enough ETH");
        require(selling, "Sale not enabled");

        uint payment;

        assembly {
            payment := sub(callvalue(), mod(callvalue(), sload(mintPrice.slot)))
            pop(call(gas(), sload(owner.slot), callvalue(), 0, 0, 0, 0))
        }

        for (; payment > 0; payment -= mintPrice) {
            supply++;
            _mint(msg.sender, supply);
        }
        
        require(supply <= maxSupply, "Sold out");
    }
}
