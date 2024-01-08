// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*
████████╗██╗   ██╗██████╗ ████████╗██╗     ███████╗    ███████╗ ██████╗ ██╗   ██╗ █████╗ ██████╗     ███╗   ██╗███████╗████████╗
╚══██╔══╝██║   ██║██╔══██╗╚══██╔══╝██║     ██╔════╝    ██╔════╝██╔═══██╗██║   ██║██╔══██╗██╔══██╗    ████╗  ██║██╔════╝╚══██╔══╝
   ██║   ██║   ██║██████╔╝   ██║   ██║     █████╗      ███████╗██║   ██║██║   ██║███████║██║  ██║    ██╔██╗ ██║█████╗     ██║
   ██║   ██║   ██║██╔══██╗   ██║   ██║     ██╔══╝      ╚════██║██║▄▄ ██║██║   ██║██╔══██║██║  ██║    ██║╚██╗██║██╔══╝     ██║
   ██║   ╚██████╔╝██║  ██║   ██║   ███████╗███████╗    ███████║╚██████╔╝╚██████╔╝██║  ██║██████╔╝    ██║ ╚████║██║        ██║
   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚══════╝    ╚══════╝ ╚══▀▀═╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝     ╚═╝  ╚═══╝╚═╝        ╚═╝
*/

import "./Counters.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./PaymentSplitter.sol";
import "./SafeMath.sol";

contract TurtleSquad is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, PaymentSplitter {
    using SafeMath for uint;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint public constant TURTLE_PRICE = 0.06 ether;
    uint public constant MAX_TURTLES = 10000;
    uint private constant reservedTurtles = 250;
    uint private constant turtlesForSale = MAX_TURTLES - reservedTurtles;
    uint public constant maxPerTx = 30;
    string private _baseURIextended;
    string public PROVENANCE;
    mapping(address => uint) reservedShares;
    mapping(address => bool) hasSharesToClaim;

    address coreTeam = 0x2D6C66baE309e320726E0e672170A001ee1e2eDd;
    address dev = 0x46c5038e30B3FFca7F088c021575Efa787F171aC;
    address genArt = 0x8144f71774D583DBA83695661aC99E8853F3E0bb;

    address[] private _team = [coreTeam, dev, genArt];
    uint256[] private _team_shares = [78, 11, 11];

    constructor()
        ERC721("Turtle Squad NFT", "TURTLE")
        PaymentSplitter(_team, _team_shares)
    {
        reservedShares[coreTeam] = 175;
        reservedShares[genArt] = 38;
        reservedShares[dev] = 37;

        hasSharesToClaim[coreTeam] = true;
        hasSharesToClaim[dev] = true;
        hasSharesToClaim[genArt] = true;

        _baseURIextended = "ipfs://bafybeiapjjwebgxvnr4ber3xpkugsfvqb6cgkchz4hrs2ik7jd6u4c77t4/";
    }

    modifier verifyGift(uint _amount) {
        require(_totalSupply() < turtlesForSale, "Error 10,000: Sold Out!");
        require(_totalSupply().add(_amount) <= turtlesForSale, "Hold up! Purchase would exceed max supply. Try a lower amount.");
        _;
    }

    modifier verifyClaim(address _addr) {
        require(hasSharesToClaim[_addr] == true, "Sorry! You dont have any shares to claim.");
        _;
        hasSharesToClaim[_addr] = false;
    }

    modifier verifyBuy(uint _amount) {
        require(msg.value >= TURTLE_PRICE.mul(_amount), "Dang! You dont have enough ETH!");
        require(_totalSupply() < turtlesForSale, "Error 10,000: Sold Out!");
        require(_totalSupply().add(_amount) <= turtlesForSale, "Hold up! Purchase would exceed max supply. Try a lower amount.");
        require(_amount >= maxPerTx == false, "Hey you can not buy more than 30 at one time. Try a smaller amount.");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function pause() public onlyOwner {
            _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function increaseSupply() internal {
        _tokenIds.increment();
    }

    function _totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }

    function buyTurtle(uint _amount) external payable verifyBuy(_amount) {
        address _to = msg.sender;
        for (uint i = 0; i < _amount; i++) {
            uint id = _totalSupply() + 1;
            _safeMint(_to, id);
            increaseSupply();
        }
    }

    function giftManyTurtles(address[] memory _addr) external onlyOwner verifyGift(_addr.length) {
        for (uint i = 0; i < _addr.length; i++) {
            address _to = _addr[i];
            uint id = _totalSupply() + 1;
            _safeMint(_to, id);
            increaseSupply();
        }
    }

    function claimTurtles() external verifyClaim(msg.sender) {
        address _to = msg.sender;
        uint _amount = reservedShares[_to];
        for (uint i = 0; i < _amount; i++) {
            uint id = _totalSupply() + 1;
            _safeMint(_to, id);
            increaseSupply();
        }
    }

    // claim reserve function

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        PROVENANCE = _provenanceHash;
    }

    function withdrawAll() public onlyOwner {
        for (uint i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
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

/**

 Generative Art: @Jim Dee
 Smart Contract Consultant: @realkelvinperez

 https://generativenfts.io/

**/

