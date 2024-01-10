// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC2981ContractWideRoyalties.sol";

contract ForestSaviorsCollection is
    ERC721,
    Ownable,
    ERC2981ContractWideRoyalties
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter private _tokenIds;
    string private baseURI;

    uint256 public constant limit = 5000;
    uint256 public currentPrice = 50000000; // 50 USDC

    IERC20 public USDC;

    address public teamTreasury;
    address public plantingTreeTreasury;
    address public communityTreasury;

    event Mint(address indexed to, uint256 indexed tokenId);

    constructor(
        address _usdc,
        address _teamTreasury,
        address _plantingTreeTreasury,
        address _communityTreasury,
        string memory _newBaseURI
    ) ERC721("ForestSaviorsCollection", "FSC") {
        USDC = IERC20(_usdc);
        teamTreasury = _teamTreasury;
        communityTreasury = _communityTreasury;
        plantingTreeTreasury = _plantingTreeTreasury;
        baseURI = _newBaseURI;
    }

    function _mintItem(address _to) private returns (uint256) {
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        _safeMint(_to, id);

        emit Mint(_to, id);
        return id;
    }

    function mint(address _to, uint256 _amount) public returns (uint256) {
        require(_tokenIds.current() <= limit, "FSC: DONE MINTING");
        require(_amount >= currentPrice, "FSC: NOT ENOUGH");

        currentPrice = (currentPrice * 10005) / 10000;

        require(USDC.transferFrom(msg.sender, address(this), _amount));

        return _mintItem(_to);
    }

    function withdraw() public onlyOwner {
        uint256 currentBalance = USDC.balanceOf(address(this));

        uint256 twentyPercent = ((currentBalance * 20) / 100);
        uint256 sixtyPercent = ((currentBalance * 60) / 100);

        USDC.safeTransfer(teamTreasury, twentyPercent);
        USDC.safeTransfer(plantingTreeTreasury, twentyPercent);
        USDC.safeTransfer(communityTreasury, sixtyPercent);
    }

    function mintAsDAO(address _to) public onlyOwner returns (uint256) {
        return _mintItem(_to);
    }

    /// @notice Change the BaseURI
    /// @param newBaseURI string of the new base URI
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /// @notice Allows to set the royalties on the contract
    /// @param recipient the royalties recipient
    /// @param value royalties value (between 0 and 10000)
    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    /// @notice Get the current base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice Get the token URI for a given token Id
    /// @param tokenId value of the token id
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
