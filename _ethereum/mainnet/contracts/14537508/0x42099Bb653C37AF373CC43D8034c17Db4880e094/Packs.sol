// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

contract Packs is ERC721A, Ownable, Pausable {
    using SafeMath for uint256;

    SNAC public snac;
    string public baseTokenURI;

    struct Tier {
        uint256 rate;
        uint256 price;
        uint256 supply;
    }

    struct Stake {
        string tier;
        uint256 rate;
        uint256 timestamp;
    }

    mapping(string => Tier) public tiers;
    mapping(uint256 => Stake) public stakes;

    constructor(address _snac) ERC721A("SPACKS", "SPACKS") {
        _pause();

        snac = SNAC(_snac);

        tiers["cookie"] = Tier(30, 0.005 ether, 1000);
        tiers["chips"] = Tier(70, 0.01 ether, 1000);
        tiers["pizza"] = Tier(150, 0.02 ether, 1000);
    }

    modifier enoughSupply(string memory _tier, uint256 _quantity) {
        require(tiers[_tier].supply > 0, "Empty supply");
        require(tiers[_tier].supply >= _quantity, "Not enough supply");
        _;
    }

    modifier enoughFunds(string memory _tier, uint256 _quantity) {
        require(msg.value >= tiers[_tier].price.mul(_quantity), "Not enough ETH");
        _;
    }

    function mint(string memory _tier, uint256 _quantity)
        external
        payable
        whenNotPaused
        enoughSupply(_tier, _quantity)
        enoughFunds(_tier, _quantity)
    {
        uint256 supply = totalSupply();

        for (uint256 i; i < _quantity; i++) {
            stakes[supply + i] = Stake(_tier, tiers[_tier].rate, block.timestamp);
        }

        tiers[_tier].supply = tiers[_tier].supply.sub(_quantity);
        _safeMint(msg.sender, _quantity);
    }

    function getReward(uint256 _token) public view returns (uint256) {
        if (stakes[_token].timestamp == 0) return 0;
        return block.timestamp.sub(stakes[_token].timestamp).mul(stakes[_token].rate).div(86400);
    }

    function getRewards(uint256[] memory _tokens) external view returns (uint256[] memory) {
        uint256[] memory rewards = new uint256[](_tokens.length);
        for (uint256 i; i < _tokens.length; i++) rewards[i] = getReward(_tokens[i]);
        return rewards;
    }

    function claim(uint256[] memory _tokens) external whenNotPaused {
        uint256 rewards;
        for (uint256 i; i < _tokens.length; i++) {
            if (msg.sender == ownerOf(_tokens[i])) {
                rewards += getReward(_tokens[i]);
                stakes[_tokens[i]].timestamp = block.timestamp;
            }
        }

        if (rewards > 0) snac.mint(msg.sender, rewards);
    }

    function withdraw() external onlyOwner {
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setSNAC(address _address) external onlyOwner {
        snac = SNAC(_address);
    }

    function setTier(
        string memory _tier,
        uint256 _rate,
        uint256 _price,
        uint256 _supply
    ) external onlyOwner {
        tiers[_tier] = Tier(_rate, _price, _supply);
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, stakes[_tokenId].tier, "/", Strings.toString(_tokenId)));
    }
}

interface SNAC {
    function mint(address to, uint256 amount) external;
}
