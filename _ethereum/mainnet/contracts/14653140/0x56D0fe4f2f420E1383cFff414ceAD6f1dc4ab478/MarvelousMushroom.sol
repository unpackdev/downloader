// SPDX-License-Identifier: MIT

/*
..................................
...........MMMMMMMMMMM ...........
.......MMMM...........MMMM........
.....MM ..................MM......
...MM   .................. .MM....
...MM...................... MM....
...MM.......................MM....
..M ......................... MM..
..M ......................... MM..
..M ......................... MM..
..M ......................... MM..
..M ......................... MM..
..M ......................... MM..
..M ......................... MM..
...MMMMMMMMMMMMMMMMMMMMMMMMMMM....
.....MM ..................MM......
.....MM ... ..............MM......
...... MM...............MM .......
.......MM               MM........
.........MMMMMMMMMMMMMMM..........
..................................
*/

pragma solidity 0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./StartTokenIdHelper.sol";

contract MarvelousMushroom is StartTokenIdHelper, ERC721A, IERC2981, Ownable {
    uint256 public immutable MAX_BUY_PER_ADDRESS = 2;
    uint256 public maxSupply;

    bool public isPublicSaleStart;
    address public royaltyAddress;
    uint256 public royaltyPercent;
    string public baseURI;

    constructor(uint256 _maxSupply)
        StartTokenIdHelper(1)
        ERC721A("Marvelous Mushroom", "MMRs")
    {
        royaltyAddress = owner();
        royaltyPercent = 10;
        maxSupply = _maxSupply;
    }

    function mint(uint256 _amount) external {
        require(isPublicSaleStart, "Public sale not start");
        require(tx.origin == msg.sender, "EOA Only");
        require(
            numberMinted(msg.sender) + _amount <= MAX_BUY_PER_ADDRESS,
            "Exceed max buy per address"
        );
        require(
            totalSupply() + _amount <= maxSupply,
            "Exceed max token supply"
        );

        _safeMint(msg.sender, _amount);
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "Non-existent token");
        return (royaltyAddress, (_salePrice * royaltyPercent) / 100);
    }

    function _startTokenId() internal view override returns (uint256) {
        return startTokenId;
    }

    function setPublicSaleStatus(bool _isStart) external onlyOwner {
        require(isPublicSaleStart == !_isStart, "Status will not change");
        isPublicSaleStart = _isStart;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw(address _to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    function setRoyaltyReceiver(address _royaltyReceiver) public onlyOwner {
        royaltyAddress = _royaltyReceiver;
    }

    function setRoyaltyPercentage(uint256 _royaltyPercentage) public onlyOwner {
        royaltyPercent = _royaltyPercentage;
    }
}
