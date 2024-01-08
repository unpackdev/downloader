// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract BabyAlienInvasionClub is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;
    uint256 public maxTokenAmount = 10000;
    uint256 public nftCostGwei = 50000000000000000;

    bool public active = true;

    mapping(address => bool) private usedReferralAddresses;

    constructor() ERC721("Baby Alien Invasion Club", "BAIC") {
        setBaseURI("ipfs://QmdEb8YFFMNe2q6Pkv6CryaHvtDLQ8MNqTew2w4KVATDfR/");
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function contractURI() external pure returns (string memory) {
        return "https://www.babyalieninvasionclub.io/api/contract_metadata";
    }

    function setActive(bool state) external onlyOwner {
        active = state;
    }

    function buy_referral(uint256 amount, address referrer) external payable {
        // Give one to a referrer, get one free and mint the amount you bought
        require(canMintReferral(msg.sender), "Already Used Referral");
        require(referrer != msg.sender, "Can't Refer Yourself");
        _canMint(amount + 2);
        require(msg.value >= amount * nftCostGwei, "Not Enough Ether Sent ");
        for (uint256 i = 0; i < amount + 1; i++) {
            mint(msg.sender);
        }
        mint(referrer);
        payable(owner()).transfer(msg.value);
        usedReferralAddresses[msg.sender] = true;
    }

    function buy(uint256 amount) external payable {
        _canMint(amount);
        require(msg.value >= amount * nftCostGwei, "Not Enough Ether Sent ");
        for (uint256 i = 0; i < amount; i++) {
            mint(msg.sender);
        }
        payable(owner()).transfer(msg.value);
    }

    function giveaway(address[] calldata receivers, uint256 amount)
        external
        onlyOwner
    {
        uint256 arrayLength = receivers.length;
        _canMint(amount * arrayLength);
        for (uint256 i = 0; i < arrayLength; i++) {
            for (uint256 j = 0; j < amount; j++) {
                mint(receivers[i]);
            }
        }
    }

    function _canMint(uint256 amount) internal view {
        require(active, "Contract is inactive");
        require(amount <= amountLeft(), "Not enough left");
    }

    function amountLeft() public view returns (uint256) {
        return maxTokenAmount - _tokenIdTracker.current();
    }

    function canMintReferral(address account) public view returns (bool) {
        return usedReferralAddresses[account] == false;
    }

    function mint(address to) internal {
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
