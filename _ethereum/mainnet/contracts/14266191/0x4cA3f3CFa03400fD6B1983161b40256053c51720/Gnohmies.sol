// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";

/// @author tempest-sol
contract Gnohmies is Ownable, Pausable, ERC721Enumerable {
    using SafeERC20 for IERC20;

    uint256 constant public MAX_GNOMES = 333;

    uint8 constant public MAXIMUM_RESERVE = 13;

    uint8 public reserveCount;

    uint256 public mintCost;

    string private baseURI;
    
    mapping(address => uint8) public reserveList;

    event GnohmieMinted(address minter);

    event GnohmieReservedFor(address receiver, uint8 amount);

    constructor() ERC721("Gnohmies", "GNOHM") {
        mintCost = 0.625 ether;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function updateMintCost(uint256 cost) external onlyOwner {
        mintCost = cost;
    }

    function reserveFor(address to, uint8 amount) external onlyOwner {
        require(to != address(0x0), "zero_address");
        require(amount > 0, "amount_zero");
        require(reserveCount < MAXIMUM_RESERVE && reserveCount + amount <= MAXIMUM_RESERVE, "not_enough_reserve");

        reserveList[to] += amount;
    }

    function claimReserved(uint8 amount) external _hasReserves whenNotPaused {
        require(reserveCount + amount <= MAXIMUM_RESERVE, "maximum_reserves_claimed");
        uint8 reserves = getReserveCount();
        require(reserves >= amount, "insufficient_reserves");
        reserveList[msg.sender] -= reserves;
        uint256 tokenId = totalSupply();
        for(uint8 i = 0; i<amount; i++) {
            _safeMint(msg.sender, tokenId + i);
        }
        reserveCount += reserves;
    }

    function mint() external payable _canMint() whenNotPaused {
        uint256 tokenId = totalSupply();
        _safeMint(msg.sender, tokenId);
    
        emit GnohmieMinted(msg.sender);
    }

    function getReserveCount() public view returns (uint8 _reserveCount) {
        _reserveCount = reserveList[msg.sender];
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function pause() external onlyOwner whenNotPaused {
        super._pause();
    }

    function unpause() external onlyOwner whenPaused {
        super._unpause();
    }

    modifier _canMint() {
        require(totalSupply() < MAX_GNOMES - MAXIMUM_RESERVE, "exceeds_maximum_supply");
        require(totalSupply() + 1 <= MAX_GNOMES - MAXIMUM_RESERVE, "exceeds_maximum_supply");
        require(msg.value >= mintCost, "not_enough_eth");
        _;
    }

    modifier _hasReserves() {
        require(reserveList[msg.sender] > 0, "no_reserves");
        _;
    }
}